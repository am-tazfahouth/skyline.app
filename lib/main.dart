import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/config/app_bootstrap.dart';
import 'package:sky_line/core/config/app_routes.dart';
import 'package:sky_line/core/config/app_theme.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/utils/platform_utils.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_state.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';
import 'package:sky_line/injection_container.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await InjectionContainer.init();
  await AppBootstrap.hydrate();
  FlutterNativeSplash.remove();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => InjectionContainer.weatherBloc..add(FetchWeatherEvent()),
        ),
        BlocProvider(
          create: (_) => InjectionContainer.settingsBloc,
        ),
        BlocProvider(
          create: (_) => InjectionContainer.locationBloc,
        ),
        BlocProvider(
          create: (_) => InjectionContainer.locationOnboardingBloc,
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        if (state is! SettingsLoadSuccess) return const SizedBox.shrink();
        final setting = state.setting;
        final appTheme = AppTheme(Theme.of(context).textTheme);

        return AnnotatedRegion(
          value: PlatformUtils.getSystemUiStyle(setting.theme, context),
          child: MaterialApp(
            title: 'SkyLine',
            initialRoute: AppRoutes.weather,
            onGenerateRoute: RouteGenerator.generateRoute,
            theme: appTheme.light(),
            darkTheme: appTheme.dark(),
            debugShowCheckedModeBanner: false,
            locale: Locale(getStringFromLang(setting.lang)),
            supportedLocales: AppLocalisation.supportedLocales,
            themeMode: SettingTheme.getThemeMode(setting.theme),
            localizationsDelegates: AppLocalisation.localizationsDelegates,
          ),
        );
      },
    );
  }
}
