import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/current_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/daily_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/hourly_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/fetch_weather_usecase.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/screens/weather_screen.dart';

class MockFetchWeatherUseCase extends Mock implements FetchWeatherUseCase {}

Widget createTestScreen(WeatherForecastBloc bloc) {
  return MaterialApp(
    home: BlocProvider<WeatherForecastBloc>.value(
      value: bloc,
      child: const WeatherScreen(),
    ),
  );
}

void main() {
  late MockFetchWeatherUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockFetchWeatherUseCase();
  });

  testWidgets('shows loading indicator while loading', (tester) async {
    final completer = Completer<WeatherEntity>();
    when(() => mockUseCase()).thenAnswer((_) => completer.future);

    final bloc = WeatherForecastBloc(mockUseCase);
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(WeatherEntity(
      current: const CurrentWeatherEntity(
        temperature: 0, humidity: 0, isDay: true,
        windSpeed: 0, precipitation: 0, weatherCode: 0,
      ),
      hourly: [],
      daily: [],
    ));
    await tester.pumpAndSettle();
  });

  testWidgets('shows weather data on loaded state', (tester) async {
    final weather = WeatherEntity(
      current: const CurrentWeatherEntity(
        temperature: 28.0,
        humidity: 65,
        isDay: true,
        windSpeed: 12.0,
        precipitation: 0.0,
        weatherCode: 51,
      ),
      hourly: [
        HourlyWeatherEntity(
          time: DateTime(2026, 5, 16, 12, 0),
          temperature: 28.0,
          precipitationProbability: 10,
          weatherCode: 0,
        ),
      ],
      daily: [
        DailyWeatherEntity(
          date: DateTime(2026, 5, 16),
          tempMax: 29.0,
          tempMin: 23.0,
          weatherCode: 51,
          sunrise: DateTime(2026, 5, 16, 3, 16),
          sunset: DateTime(2026, 5, 16, 14, 50),
        ),
      ],
    );

    when(() => mockUseCase()).thenAnswer((_) async => weather);

    final bloc = WeatherForecastBloc(mockUseCase);
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();

    expect(find.text('28°C'), findsOneWidget);
    expect(find.text('3 m/s'), findsOneWidget);
    expect(find.text('65%'), findsOneWidget);
    expect(find.text('Moroni, Comoros'), findsOneWidget);
  });

  testWidgets('shows error view on error state', (tester) async {
    when(() => mockUseCase()).thenThrow(const NetworkFailure('No internet'));

    final bloc = WeatherForecastBloc(mockUseCase);
    bloc.add(const FetchWeatherEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
  });
}
