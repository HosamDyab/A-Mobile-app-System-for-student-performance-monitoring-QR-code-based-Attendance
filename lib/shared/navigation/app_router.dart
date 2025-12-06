import 'package:flutter/material.dart';

import '../../auth/screens/welcome_screen.dart';
import '../utils/page_transitions.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return SlidePageRoute(
      page: _getPageForRoute(settings.name ?? '/'),
      direction: SlideDirection.right,
    );
  }

  // TODO: Expand with real named routes when needed.
  static Widget _getPageForRoute(String route) {
    // Fallback: always go to welcome for now.
    switch (route) {
      default:
        return const WelcomeScreen();
    }
  }
}
