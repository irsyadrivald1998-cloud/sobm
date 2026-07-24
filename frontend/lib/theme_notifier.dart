import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  static const _key = 'is_light_mode';

  bool _isLight = true; // Default to light mode
  bool get isLight => _isLight;
  ThemeMode get themeMode => _isLight ? ThemeMode.light : ThemeMode.dark;

  ThemeNotifier() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isLight = prefs.getBool(_key) ?? true; // Default to light mode
    notifyListeners();
  }

  Future<void> toggle() async {
    _isLight = !_isLight;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isLight);
    notifyListeners();
  }

  Future<void> setLight(bool value) async {
    if (_isLight == value) return;
    _isLight = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isLight);
    notifyListeners();
  }
}
