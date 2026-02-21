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
  void goProfile() => setIndex(3);
} 
