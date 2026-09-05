import 'package:flutter/material.dart';
import 'package:sky_line/features/location/presentation/screens/location_screen.dart';
import 'package:sky_line/features/location/presentation/screens/location_search_screen.dart';
import 'package:sky_line/features/settings/presentation/screens/settings_screen.dart';
import 'package:sky_line/features/weather_forecast/presentation/screens/weather_screen.dart';

class AppRoutes {
  static const String weather = '/';
  static const String location = '/location';
  static const String locationSearch = '/location/search';
  static const String settings = '/settings';
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.weather:
        return _slideRoute(const WeatherScreen());
      case AppRoutes.location:
        return _slideRoute(const LocationScreen());
      case AppRoutes.locationSearch:
        return _slideRoute(const LocationSearchScreen());
      case AppRoutes.settings:
        return _slideRoute(const SettingsScreen());
      default:
        return _slideRoute(const WeatherScreen());
    }
  }

  static Route<dynamic> _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}
