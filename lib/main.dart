import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/utils/platform_utils.dart';
import 'package:sky_line/features/weather_forecast/data/repositories/weather_repository_impl.dart';
import 'package:sky_line/features/weather_forecast/data/sources/weather_remote_source.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/fetch_weather_usecase.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/screens/weather_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => WeatherForecastBloc(
            FetchWeatherUseCase(
              WeatherRepositoryImpl(WeatherRemoteSource(Dio())),
            ),
          )..add(FetchWeatherEvent()),
        ),
      ], child: MyApp())
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme(Theme.of(context).textTheme);

    return AnnotatedRegion(
      value: PlatformUtils.getSystemUiStyle(SettingTheme.system, context),
      child: MaterialApp(
        title: 'SkyLine',
        home: WeatherScreen(),
        theme: appTheme.light(),
        darkTheme: appTheme.dark(),
        debugShowCheckedModeBanner: false,
        themeMode: SettingTheme.getThemeMode(SettingTheme.system),
      ),
    );
  }
}
