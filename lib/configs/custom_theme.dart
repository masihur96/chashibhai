import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CustomTheme {
  CustomTheme._();

  static ThemeData get lightTheme => AppTheme.lightTheme;
  static ThemeData get darkTheme => AppTheme.darkTheme;
}
