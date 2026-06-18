import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/core/utils/platform_utils.dart';
import 'package:sky_line/features/weather_forecast/domain/repositories/weather_repository.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';

class WeatherForecastBloc
    extends Bloc<WeatherForecastEvent, WeatherForecastState> {
  final WeatherRepository _weatherRepository;
  final FutureOr<bool> Function() _isConnected;

  WeatherForecastBloc(
    this._weatherRepository, {
    FutureOr<bool> Function()? isConnected,
  })  : _isConnected = isConnected ?? PlatformUtils.isConnected,
        super(const WeatherInitial()) {
    on<FetchWeatherEvent>(_onFetchWeather);
    on<RefreshWeatherEvent>(_onRefreshWeather);
  }

  Future<void> _onFetchWeather(
      FetchWeatherEvent event, Emitter<WeatherForecastState> emit) async {
    final cached = await _weatherRepository.loadCachedWeather();
    if (cached != null) {
      emit(WeatherLoaded(cached, isFetching: true));
      if (!await _isConnected()) return;
      try {
        final fresh = await _weatherRepository.fetchWeather();
        emit(WeatherLoaded(fresh));
      } on Failure {
        emit(WeatherLoaded(cached));
      } catch (_) {
        emit(WeatherLoaded(cached));
      }
      return;
    }

    emit(const WeatherEmpty(isFetching: true));
    if (!await _isConnected()) {
      emit(const WeatherEmpty());
      return;
    }

    try {
      final fresh = await _weatherRepository.fetchWeather();
      emit(WeatherLoaded(fresh));
    } on Failure catch (failure) {
      emit(WeatherError(failure));
    } catch (e, s) {
      emit(WeatherError(UnexpectedFailure(e.toString(), s)));
    }
  }

  Future<void> _onRefreshWeather(
      RefreshWeatherEvent event, Emitter<WeatherForecastState> emit) async {
    final currentState = state;
    if (currentState is WeatherLoaded) {
      emit(WeatherLoaded(currentState.result, isFetching: true));
    } else if (currentState is WeatherEmpty) {
      emit(const WeatherEmpty(isFetching: true));
    }

    try {
      final fresh = await _weatherRepository.fetchWeather();
      emit(WeatherLoaded(fresh));
    } on Failure {
      if (state is WeatherLoaded) {
        emit((state as WeatherLoaded).copyWith(isFetching: false));
      } else {
        emit(const WeatherEmpty());
      }
    } catch (e, s) {
      if (state is WeatherLoaded) {
        emit((state as WeatherLoaded).copyWith(isFetching: false));
      } else {
        emit(WeatherError(UnexpectedFailure(e.toString(), s)));
      }
    }
  }
}
