import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'theme.dart';

class ThemeController extends GetxController {
  Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  void toggleTheme() {
    themeMode.value = themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  ThemeData getThemeData() {
    return themeMode.value == ThemeMode.dark ? AppThemes.darkTheme : AppThemes.lightTheme;
  }
}
