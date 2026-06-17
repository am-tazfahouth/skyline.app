import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/fetch_weather_usecase.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';

class WeatherForecastBloc
    extends Bloc<WeatherForecastEvent, WeatherForecastState> {
  final FetchWeatherUseCase _fetchWeatherUseCase;

  WeatherForecastBloc(this._fetchWeatherUseCase) : super(const WeatherInitial()) {
    on<FetchWeatherEvent>(_onFetchWeather);
  }

  Future<void> _onFetchWeather(FetchWeatherEvent event, Emitter<WeatherForecastState> emit) async {
    emit(const WeatherLoading());
    try {
      final weather = await _fetchWeatherUseCase();
      emit(WeatherLoaded(weather));
    } on Failure catch (failure) {
      emit(WeatherError(failure));
    } catch (e, s) {
      emit(WeatherError(UnexpectedFailure(e.toString(), s)));
    }
  }
}
