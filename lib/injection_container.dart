import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/core/config/logger_impl.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/features/settings/data/repositories/setting_repository_impl.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/weather_forecast/data/repositories/weather_repository_impl.dart';
import 'package:sky_line/features/weather_forecast/data/sources/weather_remote_source.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/get_settings_use_case.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/location/data/sources/location_remote_source.dart';
import 'package:sky_line/features/location/data/sources/location_local_source.dart';
import 'package:sky_line/features/location/data/sources/location_permission_source.dart';
import 'package:sky_line/features/location/data/repositories/location_repository_impl.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_bloc.dart';

class InjectionContainer {
  static late final Dio dio;
  static late final DbHelper dbHelper;
  static late final WeatherRemoteSource weatherRemoteSource;
  static late final WeatherRepository weatherRepository;
  static late final SettingRepository settingRepository;
  static late final AppLogger logger;
  static late final SettingsBloc settingsBloc;
  static late final WeatherForecastBloc weatherBloc;
  static late final LocationRemoteSource locationRemoteSource;
  static late final LocationLocalSource locationLocalSource;
  static late final LocationPermissionSource locationPermissionSource;
  static late final LocationRepository locationRepository;
  static late final LocationBloc locationBloc;

  static Future<void> init() async {
    dio = Dio();
    dbHelper = await DbHelper.init();
    logger = LoggerServiceImpl(Logger(
      printer: PrettyPrinter(),
      level: kReleaseMode ? Level.warning : Level.debug,
    ));
    weatherRemoteSource = WeatherRemoteSource(dio);
    settingRepository = SettingRepositoryImpl(dbHelper);
    settingsBloc = SettingsBloc(logger: logger, repository: settingRepository);
    weatherRepository = WeatherRepositoryImpl(weatherRemoteSource, dbHelper);
    final getSettings = GetSettingsUseCase(settingRepository);
    weatherBloc = WeatherForecastBloc(
      logger: logger,
      weatherRepository: weatherRepository,
      getSettings: getSettings,
    );
    locationRemoteSource = LocationRemoteSource(dio);
    locationLocalSource = LocationLocalSource(dbHelper);
    locationPermissionSource = LocationPermissionSource();
    locationRepository = LocationRepositoryImpl(
      locationRemoteSource,
      locationLocalSource,
      locationPermissionSource,
    );
    locationBloc =
        LocationBloc(logger: logger, repository: locationRepository);
  }

  static void dispose() {
    dbHelper.dispose();
  }
}
