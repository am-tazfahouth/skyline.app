import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/core/services/logger_services.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/get_settings_use_case.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/weather_hourly_tile_list.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockAppLogger extends Mock implements AppLogger {}

class MockGetSettingsUseCase extends Mock implements GetSettingsUseCase {}

FutureOr<({double latitude, double longitude})?> _defaultLastLocation() =>
    (latitude: 0.0, longitude: 0.0);

void main() {
  Widget buildScreen() {
    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: MockWeatherRepository(),
      getSettings: MockGetSettingsUseCase(),
      getLastLocation: _defaultLastLocation,
      isConnected: () async => true,
    );

    return MaterialApp(
      theme: AppTheme(ThemeData().textTheme).light(),
      locale: const Locale('en'),
      supportedLocales: AppLocalisation.supportedLocales,
      localizationsDelegates: AppLocalisation.localizationsDelegates,
      home: const Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [WeatherHourlyTileList()],
          ),
        ),
      ),
    ).withBloc(bloc);
  }

  testWidgets('placeholder renders six skeleton hourly tiles', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.text('--:--'), findsNWidgets(6));
    expect(find.text('--°'), findsNWidgets(6));
  });

  testWidgets(
    'placeholder keeps tiles clipped inside the card on narrow screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildScreen());

      expect(tester.takeException(), isNull);

      final scrollable = tester.widget<SingleChildScrollView>(
        find.descendant(
          of: find.byType(WeatherHourlyTileList),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      expect(scrollable.clipBehavior, isNot(Clip.none));
    },
  );
}

extension on Widget {
  Widget withBloc(WeatherForecastBloc bloc) {
    return BlocProvider<WeatherForecastBloc>.value(value: bloc, child: this);
  }
}
