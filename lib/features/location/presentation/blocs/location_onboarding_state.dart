import 'package:equatable/equatable.dart';

abstract class LocationOnboardingState extends Equatable {
  const LocationOnboardingState();

  @override
  List<Object?> get props => [];
}

class LocationOnboardingLoading extends LocationOnboardingState {
  const LocationOnboardingLoading();
}

class LocationOnboardingLoaded extends LocationOnboardingState {
  final bool hasSeenLocationOnboarding;

  const LocationOnboardingLoaded({required this.hasSeenLocationOnboarding});

  LocationOnboardingLoaded copyWith({bool? hasSeenLocationOnboarding}) {
    return LocationOnboardingLoaded(
      hasSeenLocationOnboarding:
          hasSeenLocationOnboarding ?? this.hasSeenLocationOnboarding,
    );
  }

  @override
  List<Object?> get props => [hasSeenLocationOnboarding];
}

class LocationOnboardingError extends LocationOnboardingState {
  const LocationOnboardingError();
}
