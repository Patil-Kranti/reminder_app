import '../model/item.dart';
import '../model/view_type.dart';

class Header implements Item {
  final String date;
  Header({this.date});

  @override
  ViewType getViewType() {
    return ViewType.HEADER;
  }
}
