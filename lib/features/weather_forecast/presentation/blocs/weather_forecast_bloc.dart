import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/core/errors/weather_exceptions.dart';
import 'package:sky_line/core/errors/weather_error_codes.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/core/utils/platform_utils.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/weather_result.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/get_settings_use_case.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';

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
    required this.getLastLocation,
    this.isConnected = PlatformUtils.isConnected,
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

    WeatherForecastState loadingAnchor;
    if (cached != null) {
      loadingAnchor = WeatherLoaded(cached, isFetching: true, settings: settings);
      emit(loadingAnchor);
    } else {
      loadingAnchor = WeatherEmpty(isFetching: true, settings: settings);
      emit(loadingAnchor);
    }

    if (!online) {
      if (cached != null && state == loadingAnchor) {
        emit(WeatherLoaded(
          cached,
          settings: settings,
          notice: WeatherNotice.cachedData,
        ));
      } else if (state == loadingAnchor) {
        emit(WeatherEmpty(settings: settings));
      }
      return;
    }

    try {
      final fresh = await weatherRepository.fetchWeather(latitude: lat, longitude: lon);
      if (state == loadingAnchor) {
        emit(WeatherLoaded(fresh, settings: settings));
      }
    }
    on DioException catch (dioError, stackTrace) {
      final code = dioError.type == DioExceptionType.connectionTimeout 
        || dioError.type == DioExceptionType.receiveTimeout 
        || dioError.type == DioExceptionType.connectionError
          ? WeatherErrorCodes.network
          : WeatherErrorCodes.fetch;
      logger.e(AppError.getDebugErrorMessage(code), error: dioError, stackTrace: stackTrace);
      if (cached != null && state == loadingAnchor) {
        emit(WeatherLoaded(
          cached,
          settings: settings,
          notice: WeatherNotice.cachedData,
        ));
      } else if (state == loadingAnchor) {
        emit(WeatherError(errorCode: code));
      }
    }
    on WeatherParseException catch (e, stackTrace) {
      final code = WeatherErrorCodes.parse;
      logger.e(AppError.getDebugErrorMessage(code), error: e, stackTrace: stackTrace);
      if (cached != null && state == loadingAnchor) {
        emit(WeatherLoaded(
          cached,
          settings: settings,
          notice: WeatherNotice.cachedData,
        ));
      } else if (state == loadingAnchor) {
        emit(WeatherError(errorCode: code));
      }
    }
    catch (e, stackTrace) {
      logger.e(AppError.getDebugErrorMessage(WeatherErrorCodes.unexpected), error: e, stackTrace: stackTrace);
      if (cached != null && state == loadingAnchor) {
        emit(WeatherLoaded(
          cached,
          settings: settings,
          notice: WeatherNotice.cachedData,
        ));
      } else if (state == loadingAnchor) {
        emit(WeatherError(errorCode: WeatherErrorCodes.unexpected));
      }
    }
  }

  Future<void> _onRefreshWeather(RefreshWeatherEvent event, Emitter<WeatherForecastState> emit) async {
    WeatherResult? capturedResult;
    SettingEntity? currentSettings;
    switch (state) {
      case WeatherLoaded(:final result, :final settings):
        capturedResult = result;
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

    WeatherForecastState? loadingAnchor;
    if (capturedResult != null) {
      loadingAnchor = WeatherLoaded(capturedResult, isFetching: true, settings: currentSettings);
    } else {
      loadingAnchor = WeatherEmpty(isFetching: true, settings: currentSettings);
    }

    try {
      final fresh = await weatherRepository.fetchWeather(latitude: lat, longitude: lon);
      if (state == loadingAnchor) {
        emit(WeatherLoaded(fresh, settings: settings));
      }
    }
    on DioException catch (dioError, stackTrace) {
      final code = dioError.type == DioExceptionType.connectionTimeout
        || dioError.type == DioExceptionType.receiveTimeout
        || dioError.type == DioExceptionType.connectionError
          ? WeatherErrorCodes.network
          : WeatherErrorCodes.fetch;
      logger.e(AppError.getDebugErrorMessage(code), error: dioError, stackTrace: stackTrace);
      if (state == loadingAnchor) {
        if (capturedResult != null) {
          emit(WeatherLoaded(capturedResult, isFetching: false,
              settings: currentSettings, notice: WeatherNotice.refreshError));
        } else {
          emit(WeatherEmpty(settings: currentSettings));
        }
      } else if (state case WeatherLoaded loaded) {
        emit(loaded.copyWith(isFetching: false));
      }
    }
    on WeatherParseException catch (e, stackTrace) {
      final code = WeatherErrorCodes.parse;
      logger.e(AppError.getDebugErrorMessage(code), error: e, stackTrace: stackTrace);
      if (state == loadingAnchor) {
        if (capturedResult != null) {
          emit(WeatherLoaded(capturedResult, isFetching: false,
              settings: currentSettings, notice: WeatherNotice.refreshError));
        } else {
          emit(WeatherEmpty(settings: currentSettings));
        }
      } else if (state case WeatherLoaded loaded) {
        emit(loaded.copyWith(isFetching: false));
      }
    }
    catch (e, stackTrace) {
      logger.e(AppError.getDebugErrorMessage(WeatherErrorCodes.unexpected), error: e, stackTrace: stackTrace);
      if (state == loadingAnchor) {
        if (capturedResult != null) {
          emit(WeatherLoaded(capturedResult, isFetching: false,
              settings: currentSettings, notice: WeatherNotice.refreshError));
        } else {
          emit(WeatherError(errorCode: WeatherErrorCodes.unexpected));
        }
      } else if (state case WeatherLoaded loaded) {
        emit(loaded.copyWith(isFetching: false));
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
