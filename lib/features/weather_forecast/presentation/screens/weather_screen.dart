import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/failure.dart';
import 'package:sky_line/features/weather_forecast/domain/entities/daily_weather_entity.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_bloc.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_event.dart';
import 'package:sky_line/features/weather_forecast/presentation/blocs/weather_forecast_state.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/current_weather_card.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/ephemeride_card.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/forecast_tabs.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/hourly_carousel.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/stats_card.dart';
import 'package:sky_line/features/weather_forecast/presentation/widgets/weather_header.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _isTodaySelected = true;

  @override
  void initState() {
    super.initState();
    context.read<WeatherForecastBloc>().add(const FetchWeatherEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<WeatherForecastBloc, WeatherForecastState>(
          builder: (context, state) {
            if (state is WeatherInitial || state is WeatherLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is WeatherError) {
              return _ErrorView(
                failure: state.failure,
                onRetry: () {
                  context
                      .read<WeatherForecastBloc>()
                      .add(const FetchWeatherEvent());
                },
              );
            }
            if (state is WeatherLoaded) {
              final weather = state.weather;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const WeatherHeader(),
                    CurrentWeatherCard(current: weather.current),
                    StatsCard(current: weather.current),
                    ForecastTabs(
                      isTodaySelected: _isTodaySelected,
                      onTodayTap: () => setState(() => _isTodaySelected = true),
                      onNext7Tap: () => setState(() => _isTodaySelected = false),
                    ),
                    if (_isTodaySelected)
                      HourlyCarousel(hourly: weather.hourly)
                    else
                      _DailyForecastList(daily: weather.daily),
                    if (weather.daily.isNotEmpty)
                      EphemerideCard(daily: weather.daily.first),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;

  const _ErrorView({required this.failure, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off,
                size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _userFriendlyMessage(failure),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _userFriendlyMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'No internet connection.\nPlease check your connection and try again.';
    }
    if (failure is ServerFailure) {
      return 'Server is not responding.\nPlease try again later.';
    }
    return 'Something went wrong.\nPlease try again.';
  }
}

class _DailyForecastList extends StatelessWidget {
  final List<DailyWeatherEntity> daily;

  const _DailyForecastList({required this.daily});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: daily.map((day) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    _dayAbbreviation(day.date),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Icon(Icons.cloud, color: theme.colorScheme.primary),
                Row(
                  children: [
                    Text(
                      '${day.tempMax.toStringAsFixed(0)}°',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${day.tempMin.toStringAsFixed(0)}°',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _dayAbbreviation(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day) return 'Today';
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }
}
