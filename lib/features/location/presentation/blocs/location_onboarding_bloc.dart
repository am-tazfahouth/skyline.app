import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/core/errors/location_error_codes.dart';
import 'package:sky_line/core/services/logger_services.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_state.dart';

class LocationOnboardingBloc
    extends Bloc<LocationOnboardingEvent, LocationOnboardingState> {
  final AppLogger logger;
  final LocationRepository repository;

  LocationOnboardingBloc({required this.logger, required this.repository})
      : super(const LocationOnboardingLoading()) {
    on<LoadOnboardingStatusEvent>(_onLoadOnboardingStatus);
    on<CompleteOnboardingEvent>(_onCompleteOnboarding);
  }

  Future<void> _onLoadOnboardingStatus(
    LoadOnboardingStatusEvent event,
    Emitter<LocationOnboardingState> emit,
  ) async {
    try {
      final value = await repository.hasSeenLocationOnboarding();
      emit(LocationOnboardingLoaded(hasSeenLocationOnboarding: value));
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.unexpected),
        error: e,
        stackTrace: stackTrace,
      );
      emit(const LocationOnboardingError());
    }
  }

  Future<void> _onCompleteOnboarding(
    CompleteOnboardingEvent event,
    Emitter<LocationOnboardingState> emit,
  ) async {
    try {
      await repository.markLocationOnboardingSeen();
    } catch (e, stackTrace) {
      logger.e(
        AppError.getDebugErrorMessage(LocationErrorCodes.unexpected),
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      emit(const LocationOnboardingLoaded(hasSeenLocationOnboarding: true));
    }
  }
}
