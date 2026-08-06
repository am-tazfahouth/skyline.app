import 'package:flutter/material.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';

class WeatherInitialView extends StatelessWidget {
  const WeatherInitialView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalisation.of(context)!;
    return Scaffold(
      body: Center(
        child: Text(l10n.weatherSearchForLocation),
      ),
    );
  }
}
