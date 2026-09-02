import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends GetxService {
  late SharedPreferences _prefs;
  static const _key = 'isDarkMode';

  // Observable track of theme state
  final RxBool isDarkMode = false.obs;

  Future<ThemeService> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Default to false (Light Theme / White Theme)
    isDarkMode.value = _prefs.getBool(_key) ?? false;
    return this;
  }

  ThemeMode get themeMode => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _prefs.setBool(_key, isDarkMode.value);
    Get.changeThemeMode(themeMode);
  }
}
