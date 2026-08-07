import 'package:equatable/equatable.dart';

abstract class LocationOnboardingEvent extends Equatable {
  const LocationOnboardingEvent();

  @override
  List<Object?> get props => [];
}

class LoadOnboardingStatusEvent extends LocationOnboardingEvent {
  const LoadOnboardingStatusEvent();
}

class CompleteOnboardingEvent extends LocationOnboardingEvent {
  const CompleteOnboardingEvent();
}
