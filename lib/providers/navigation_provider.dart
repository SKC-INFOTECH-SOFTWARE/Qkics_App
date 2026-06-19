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
  void goKnowledgeHub() => setIndex(1);
  void goCompanies() => setIndex(2);
  void goNotifications() => setIndex(3);
  void goProfile() => setIndex(4);
}
