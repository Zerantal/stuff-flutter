import 'package:flutter/foundation.dart';

class AppBarTitleNotifier extends ChangeNotifier {
  String _appBarTitle = '';

  String get appBarTitle => _appBarTitle;

  void setTitle(String newTitle) {
    if (_appBarTitle != newTitle) {
      _appBarTitle = newTitle;
      notifyListeners();
    }
  }
}
