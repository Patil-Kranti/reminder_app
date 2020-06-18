import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Category {
  static final String tableName = 'category';

  static final String columnId = 'id';
  static final String columnName = 'name';

  static const String allLists = 'Select Category';
  static const String general = 'General';
  static const String personal = 'Personal';
  static const String shopping = 'Shopping';
  static const String work = 'Work';
  static const String finished = 'Finished';

  int id;
  String name;

  Category({this.id, @required this.name});

  Map toMap() {
    return <String, dynamic>{columnName: name};
  }

  Category.fromMap(Map map) {
    id = map[columnId];
    name = map[columnName];
  }

  IconData getIcon() {
    switch (name) {
      case allLists:
        return Icons.home;
      case general:
        return Icons.list;
      case personal:
        return Icons.person_outline;
      case shopping:
        return Icons.shopping_cart;
      case work:
        return Icons.work;
      case finished:
        return Icons.check;
    }
  }
}
