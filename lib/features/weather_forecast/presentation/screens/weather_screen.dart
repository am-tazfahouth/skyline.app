import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_content_view.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_error_view.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_initial_view.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/views/weather_loading_view.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
      builder: (context, state) => switch (state) {
        WeatherInitial() => const WeatherInitialView(),
        WeatherEmpty() => const WeatherLoadingView(),
        WeatherLoaded() => const WeatherContentView(),
        WeatherError(failure: final f) => WeatherErrorView(message: f.message),
        _ => const WeatherInitialView(),
      },
    );
  }
}