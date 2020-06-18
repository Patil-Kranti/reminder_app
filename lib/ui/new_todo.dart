import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import '../db/category_provider.dart';
import '../db/todo_provider.dart';
import '../model/category.dart';
import '../model/todo.dart';
import '../util/constants.dart';
import 'todo_list.dart';

class NewTodo extends StatefulWidget {
  static final String routeName = '/new';
  final Todo todo;
  final DateFormat formatter = new DateFormat("dd-MM-yyyy hh:mm a");

  NewTodo({Key key, this.todo}) : super(key: key) {
    if (todo.date == null) {
      this.todo.date = formatter.format(new DateTime.now());
    }
  }

  @override
  _NewTodoState createState() => new _NewTodoState();
}

class _NewTodoState extends State<NewTodo> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  List<Category> _categoryList = [];
  Category _category;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AndroidInitializationSettings _androidInitializationSettings;
  IOSInitializationSettings _iosInitializationSettings;
  InitializationSettings initializationSettings;

  AppBar _createAppBar() {
    return new AppBar(
      backgroundColor: Colors.indigo.shade700,
      title: new Text(_getTitle()),
      actions: <Widget>[_createSaveUpdateAction()],
    );
  }

  IconButton _createSaveUpdateAction() {
    return new IconButton(
      onPressed: () {
        _saveTodo();
      },
      icon: const Icon(Icons.send),
    );
  }

  _saveTodo() async {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      TodoProvider provider = new TodoProvider();
      widget.todo.categoryId = _category.id;
      print(widget.todo.id);
      print(widget.todo.note);
      print(widget.todo.date);
      if (!_isExistRecord()) {
        await provider.insert(widget.todo);
        showScheduledNotifications(
            widget.todo.id, widget.todo.note, widget.todo.date);
      } else {
        await provider.update(widget.todo);
        showScheduledNotifications(
            widget.todo.id, widget.todo.note, widget.todo.date);
      }
      Navigator.of(context).pop();
    }
  }

  bool _isExistRecord() {
    return widget.todo.id == null ? false : true;
  }

  @override
  void initState() {
    super.initState();
    new CategoryProvider().getAllCategory().then((categories) {
      setState(() {
        if (_isExistRecord())
          _category = categories
              .firstWhere((category) => category.id == widget.todo.categoryId);
        _categoryList = categories;
      });
    });
    initializing();
  }

  Future<void> initializing() async {
    _androidInitializationSettings = AndroidInitializationSettings('app_icon');
    _iosInitializationSettings = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    initializationSettings = InitializationSettings(
        _androidInitializationSettings, _iosInitializationSettings);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  void showScheduledNotifications(int id, String note, String date) async {
    await scheduleNotfication(id, note, date);
  }

  Future<void> scheduleNotfication(int id, String note, String date) async {
    DateTime schedule = widget.formatter.parse(date);
    if (DateTime.now().difference(schedule) <= Duration(minutes: 15)) {
      schedule = schedule;
    } else {
      schedule = schedule.subtract(Duration(minutes: 15));
    }

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
            'Channel ID', 'Channel Title', 'channel body',
            priority: Priority.High,
            importance: Importance.Max,
            ongoing: true,
            ticker: 'Test');
    IOSNotificationDetails iosNotificationDetails = IOSNotificationDetails();
    NotificationDetails notificationDetails =
        NotificationDetails(androidNotificationDetails, iosNotificationDetails);
    await flutterLocalNotificationsPlugin.schedule(
        id, note, date, schedule, notificationDetails);
  }

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      print(payload);
    }
  }

  Future onDidReceiveLocalNotification(
    int id,
    String title,
    String body,
    String payload,
  ) async {
    return CupertinoAlertDialog(
      title: Text(title),
      content: Text(body),
      actions: <Widget>[
        CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              print("");
            },
            child: Text("Okay"))
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _getTitle() {
    return _isExistRecord() ? Constants.titleEdit : Constants.titleNew;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: _createAppBar(),
      body: new Padding(
          padding: new EdgeInsets.fromLTRB(12.0, 18.0, 12.0, 18.0),
          child: new Form(
            onWillPop: _warnUserWithoutSaving,
            key: _formKey,
            child: new Column(
              children: <Widget>[
                _createDatePicker(),
                SizedBox(height: 20.0),
                _createNote(),
                SizedBox(height: 20.0),
                _categoryList.isNotEmpty
                    ? _createCategoryDropDownList(_categoryList)
                    : new Container()
              ],
            ),
          )),
    );
  }

  Row _createDatePicker() {
    return new Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        new Icon(
          Icons.date_range,
          color: Colors.indigo.shade700,
        ),
        new InkWell(
          child: new Padding(
            padding: new EdgeInsets.only(
                left: 18.0, top: 8.0, bottom: 8.0, right: 18.0),
            child: new Text(
              widget.todo.date,
              style:
                  new TextStyle(color: Colors.indigo.shade700, fontSize: 18.0),
            ),
          ),
          onTap: _pickDateFromDatePicker,
        )
      ],
    );
  }

  Row _createCategoryDropDownList(List<Category> categories) {
    return new Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Icon(
            Icons.list,
            color: Colors.indigo.shade700,
            size: 28.0,
          ),
          new Padding(
              padding:
                  new EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
              child: new DropdownButtonHideUnderline(
                child: new DropdownButton(
                    value: _category ??
                        (categories.length > 0
                            ? _category = categories[0]
                            : null),
                    items: _createCategoryDropDownMenuItems(categories),
                    isDense: true,
                    onChanged: (value) {
                      setState(() => _category = value);
                    }),
              ))
        ]);
  }

  List<DropdownMenuItem<Category>> _createCategoryDropDownMenuItems(
      List<Category> categories) {
    return categories.map((category) {
      return new DropdownMenuItem(
          value: category,
          child: new Text(category.name,
              style: new TextStyle(
                  color: Colors.indigo.shade700, fontSize: 18.0)));
    }).toList();
  }

  _pickDateFromDatePicker() async {
    DateTime dateTime = widget.formatter.parse(widget.todo.date);
    TimeOfDay timeOfDay = new TimeOfDay.now();
    DateTime datePicked = await showDatePicker(
      context: context,
      initialDate: dateTime,
      firstDate: isBeforeToday(dateTime) ? dateTime : new DateTime.now(),
      lastDate: dateTime.add(
        const Duration(days: 10950),
      ),
    );
    TimeOfDay timeSelected = await showTimePicker(
      context: context,
      initialTime: timeOfDay,
    );
    DateTime dateTimePicked = DateTime(datePicked.year, datePicked.month,
        datePicked.day, timeSelected.hour, timeSelected.minute);

    print(dateTimePicked);
    if (dateTimePicked != null) {
      setState(() {
        widget.todo.date = widget.formatter.format(dateTimePicked);
      });
    }
  }

  bool isBeforeToday(DateTime date) {
    return date.isBefore(new DateTime.now());
  }

  Future<bool> _warnUserWithoutSaving() async {
    if (_isExistRecord()) {
      return true;
    } else {
      return await showDialog<bool>(
            context: context,
            child: new AlertDialog(
              title: const Text(
                'Discard',
                style: TextStyle(fontSize: 20.0),
              ),
              content: const Text(
                'Do you want close without saving to do note?',
                style: TextStyle(fontSize: 18.0),
              ),
              actions: <Widget>[
                new FlatButton(
                  child: const Text(
                    'YES',
                    style: TextStyle(color: Colors.indigo, fontSize: 18.0),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
                new FlatButton(
                  child: const Text(
                    'NO',
                    style: TextStyle(color: Colors.indigo, fontSize: 18.0),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
              ],
            ),
          ) ??
          false;
    }
  }

  TextFormField _createNote() {
    return new TextFormField(
      textAlign: TextAlign.justify,
      maxLines: 1,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        enabledBorder:
            OutlineInputBorder(borderSide: BorderSide(color: Colors.indigo)),
        contentPadding:
            const EdgeInsets.only(left: 15.0, top: 20.0, bottom: 20.0),
        icon: const Icon(
          Icons.note_add,
          color: Colors.indigo,
        ),
        hintText: 'Add your new task',
        labelText: 'New Task',
        hintStyle: TextStyle(color: Colors.indigo, fontSize: 18.0),
        labelStyle: TextStyle(color: Colors.indigo, fontSize: 18.0),
      ),
      initialValue: widget.todo.note ?? '',
      keyboardType: TextInputType.text,
      validator: _validateNote,
      onSaved: _noteOnSave,
    );
  }

  String _validateNote(String value) {
    return value.isEmpty ? 'Note is required' : null;
  }

  void _noteOnSave(String value) {
    widget.todo.note = value;
  }
}
