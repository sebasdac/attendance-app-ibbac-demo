import 'package:flutter/material.dart';

class AppRouter {
  static const String initialRoute = '/';

  static Map<String, WidgetBuilder> get routes => {
    initialRoute: (context) =>
        const Scaffold(body: Center(child: CircularProgressIndicator())),
  };
}
