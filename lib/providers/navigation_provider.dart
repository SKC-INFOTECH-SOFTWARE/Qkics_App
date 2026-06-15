// lib/navigation_provider.dart
import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void setIndex(int value) {
    _index = value;
    notifyListeners();
  }

  void goHome() => setIndex(0);
  void goSearch() => setIndex(1);
  void goPost() {
  _index = 2;
  notifyListeners();
}
  void goCompanies() => setIndex(3);
  void goNotifications() => setIndex(4);
  void goProfile() => setIndex(5);
}
