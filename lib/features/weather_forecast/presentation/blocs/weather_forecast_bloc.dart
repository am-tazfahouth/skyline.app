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

const double _defaultLatitude = -11.7022;
const double _defaultLongitude = 43.2551;

FutureOr<({double latitude, double longitude})?> _defaultLastLocation() =>
    (latitude: _defaultLatitude, longitude: _defaultLongitude);

class WeatherForecastBloc extends Bloc<WeatherForecastEvent, WeatherForecastState> {
  final AppLogger logger;
  final WeatherRepository weatherRepository;
  final GetSettingsUseCase getSettings;
  final FutureOr<bool> Function() isConnected;
  final FutureOr<({double latitude, double longitude})?> Function() getLastLocation;

  WeatherForecastBloc({
    required this.logger,
    required this.weatherRepository,
    required this.getSettings,
    this.isConnected = PlatformUtils.isConnected,
    this.getLastLocation = _defaultLastLocation,
  }) : super(const WeatherInitial()) {
    on<FetchWeatherEvent>(_onFetchWeather);
    on<RefreshWeatherEvent>(_onRefreshWeather);
    on<ApplySettingsEvent>(_onApplySettings);
    on<ResetWeatherEvent>(_onResetWeather);
  }

  void _onApplySettings(ApplySettingsEvent event, Emitter<WeatherForecastState> emit) {
    switch (state) {
      case WeatherLoaded(:final result, :final isFetching):
        emit(WeatherLoaded(result, isFetching: isFetching, settings: event.settings));
      case WeatherEmpty(:final isFetching):
        emit(WeatherEmpty(isFetching: isFetching, settings: event.settings));
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
    final settings = await _loadSettings();
    double? lat = event.latitude;
    double? lon = event.longitude;
    if (lat == null || lon == null) {
      final last = await getLastLocation();
      if (last == null) {
        await weatherRepository.clearCachedWeather();
        emit(WeatherEmpty(settings: settings));
        return;
      }
      lat = last.latitude;
      lon = last.longitude;
    }

    final cached = await weatherRepository.loadCachedWeather(latitude: lat, longitude: lon);
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
    double? lat;
    double? lon;
    final last = await getLastLocation();
    if (last != null) {
      lat = last.latitude;
      lon = last.longitude;
    }
    if (lat == null || lon == null) {
      emit(WeatherEmpty(settings: settings));
      return;
    }

    try {
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

  Future<void> _onResetWeather(
    ResetWeatherEvent event,
    Emitter<WeatherForecastState> emit,
  ) async {
    final settings = await _loadSettings();
    await weatherRepository.clearCachedWeather();
    emit(WeatherEmpty(settings: settings));
  }
}
