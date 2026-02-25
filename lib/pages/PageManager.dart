import 'package:flutter/material.dart';

class PageManager {
  final BuildContext context;

  PageManager(this.context);

  /// Open a new page (with any required constructor arguments)
  void openPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  /// Open a page and replace the current one
  void replacePage(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  /// Close current page
  void closePage() {
    Navigator.pop(context);
  }

  /// Open a page and wait for a result
  Future<T?> openPageForResult<T>(Widget page) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }
}