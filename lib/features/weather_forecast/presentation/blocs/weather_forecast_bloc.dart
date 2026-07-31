import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/core/errors/weather_error_codes.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/core/utils/platform_utils.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/get_settings_use_case.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';

class WeatherForecastBloc extends Bloc<WeatherForecastEvent, WeatherForecastState> {
  final AppLogger logger;
  final WeatherRepository weatherRepository;
  final GetSettingsUseCase getSettings;
  final FutureOr<bool> Function() isConnected;

  static const double _defaultLatitude = -11.7022;
  static const double _defaultLongitude = 43.2551;

  WeatherForecastBloc({
    required this.logger,
    required this.weatherRepository,
    required this.getSettings,
    this.isConnected = PlatformUtils.isConnected,
  }) : super(const WeatherInitial()) {
    on<FetchWeatherEvent>(_onFetchWeather);
    on<RefreshWeatherEvent>(_onRefreshWeather);
    on<ApplySettingsEvent>(_onApplySettings);
  }

  void _onApplySettings(ApplySettingsEvent event, Emitter<WeatherForecastState> emit) {
    switch (state) {
      case WeatherLoaded(:final result):
        emit(WeatherLoaded(result, settings: event.settings));
      case WeatherEmpty _:
        emit(WeatherEmpty(settings: event.settings));
      default:
        break;
    }
  }

  Future<SettingEntity> _loadSettings() async {
    try {
      return await getSettings();
    } catch (_) {
      return const SettingEntity();
    }
  }

  Future<void> _onFetchWeather(FetchWeatherEvent event, Emitter<WeatherForecastState> emit) async {
    final cached = await weatherRepository.loadCachedWeather();
    final settings = await _loadSettings();
    final online = await isConnected();

    if (cached != null) {
      emit(WeatherLoaded(cached, isFetching: true, settings: settings));
    } else {
      emit(WeatherEmpty(isFetching: true, settings: settings));
    }

    if (!online) {
      if (cached != null) {
        emit(WeatherLoaded(cached, settings: settings));
      } else {
        emit(WeatherEmpty(settings: settings));
      }
      return;
    }

    try {
      final lat = event.latitude ?? _defaultLatitude;
      final lon = event.longitude ?? _defaultLongitude;
      final fresh = await weatherRepository.fetchWeather(latitude: lat, longitude: lon);
      emit(WeatherLoaded(fresh, settings: settings));
    }
    on DioException catch (dioError, stackTrace) {
      final code = dioError.type == DioExceptionType.connectionTimeout 
        || dioError.type == DioExceptionType.receiveTimeout 
        || dioError.type == DioExceptionType.connectionError
          ? WeatherErrorCodes.network
          : WeatherErrorCodes.fetch;
      logger.e(AppError.getDebugErrorMessage(code), error: dioError, stackTrace: stackTrace);
      if (cached != null) {
        emit(WeatherLoaded(cached, settings: settings));
      } else {
        emit(WeatherError(errorCode: code));
      }
    }
    catch (e, stackTrace) {
      logger.e(AppError.getDebugErrorMessage(WeatherErrorCodes.unexpected), error: e, stackTrace: stackTrace);
      if (cached != null) {
        emit(WeatherLoaded(cached, settings: settings));
      } else {
        emit(WeatherError(errorCode: WeatherErrorCodes.unexpected));
      }
    }
  }

  Future<void> _onRefreshWeather(RefreshWeatherEvent event, Emitter<WeatherForecastState> emit) async {
    SettingEntity? currentSettings;
    switch (state) {
      case WeatherLoaded(:final result, :final settings):
        currentSettings = settings;
        emit(WeatherLoaded(result, isFetching: true, settings: settings));
      case WeatherEmpty(:final settings):
        currentSettings = settings;
        emit(WeatherEmpty(isFetching: true, settings: settings));
      default:
        return;
    }

    final settings = await _loadSettings();

    try {
      final fresh = await weatherRepository.fetchWeather(latitude: _defaultLatitude, longitude: _defaultLongitude);
      emit(WeatherLoaded(fresh, settings: settings));
    }
    on DioException catch (dioError, stackTrace) {
      final code = dioError.type == DioExceptionType.connectionTimeout 
        || dioError.type == DioExceptionType.receiveTimeout 
        || dioError.type == DioExceptionType.connectionError
          ? WeatherErrorCodes.network
          : WeatherErrorCodes.fetch;
      logger.e(AppError.getDebugErrorMessage(code), error: dioError, stackTrace: stackTrace);
      if (state case WeatherLoaded loaded) {
        emit(loaded.copyWith(isFetching: false));
      } else {
        emit(WeatherEmpty(settings: currentSettings));
      }
    }
    catch (e, stackTrace) {
      logger.e(AppError.getDebugErrorMessage(WeatherErrorCodes.unexpected), error: e, stackTrace: stackTrace);
      if (state case WeatherLoaded loaded) {
        emit(loaded.copyWith(isFetching: false));
      } else {
        emit(WeatherError(errorCode: WeatherErrorCodes.unexpected));
      }
    }
  }
}
