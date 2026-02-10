import 'package:flutter/material.dart';

/// Convenient extensions on BuildContext to reduce boilerplate.
extension ContextExtensions on BuildContext {
  // Theme shortcuts
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // MediaQuery shortcuts
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => mediaQuery.padding;
  bool get isDarkMode => theme.brightness == Brightness.dark;

  // Navigation shortcuts
  NavigatorState get navigator => Navigator.of(this);
  void pop<T>([T? result]) => navigator.pop(result);
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) =>
      navigator.pushNamed<T>(routeName, arguments: arguments);
  Future<T?> pushReplacementNamed<T, TO>(String routeName, {Object? arguments}) =>
      navigator.pushReplacementNamed<T, TO>(routeName, arguments: arguments);

  // SnackBar shortcut
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
