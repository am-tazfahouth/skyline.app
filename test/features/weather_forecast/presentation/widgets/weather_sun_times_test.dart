import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/get_settings_use_case.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/weather_sun_times.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockAppLogger extends Mock implements AppLogger {}

class MockGetSettingsUseCase extends Mock implements GetSettingsUseCase {}

void main() {
  Widget buildScreen({Locale locale = const Locale('en')}) {
    final bloc = WeatherForecastBloc(
      logger: MockAppLogger(),
      weatherRepository: MockWeatherRepository(),
      getSettings: MockGetSettingsUseCase(),
      isConnected: () async => true,
    );

    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalisation.supportedLocales,
      localizationsDelegates: AppLocalisation.localizationsDelegates,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [WeatherSunTimes()],
          ),
        ),
      ),
    ).withBloc(bloc);
  }

  testWidgets(
      'placeholder fallback spreads the time points across the full card width',
      (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.text('--:--'), findsNWidgets(3));
    expect(find.text('Sun Time'), findsNothing);

    final firstCenter = tester.getCenter(find.text('--:--').at(0));
    final middleCenter = tester.getCenter(find.text('--:--').at(1));
    final lastCenter = tester.getCenter(find.text('--:--').at(2));

    final firstGap = middleCenter.dx - firstCenter.dx;
    final secondGap = lastCenter.dx - middleCenter.dx;

    expect(firstGap, greaterThan(120));
    expect(secondGap, greaterThan(120));

    final screenWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect((middleCenter.dx - screenWidth / 2).abs(), lessThan(50));
  });

  testWidgets('placeholder shows localized labels in French', (tester) async {
    await tester.pumpWidget(buildScreen(locale: const Locale('fr')));

    expect(find.text('Lever du soleil'), findsOneWidget);
    expect(find.text('Zénith'), findsOneWidget);
    expect(find.text('Coucher du soleil'), findsOneWidget);
  });
}

extension on Widget {
  Widget withBloc(WeatherForecastBloc bloc) {
    return BlocProvider<WeatherForecastBloc>.value(value: bloc, child: this);
  }
}
