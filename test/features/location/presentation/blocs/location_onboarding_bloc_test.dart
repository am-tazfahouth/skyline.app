import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/features/location/domain/repositories/location_repository.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_bloc.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_event.dart';
import 'package:sky_line/features/location/presentation/blocs/location_onboarding_state.dart';

class MockRepository extends Mock implements LocationRepository {}

class MockLogger extends Mock implements AppLogger {}

void main() {
  late MockRepository mockRepo;
  late MockLogger mockLogger;

  setUp(() {
    mockRepo = MockRepository();
    mockLogger = MockLogger();
  });

  group('LocationOnboardingBloc', () {
    blocTest<LocationOnboardingBloc, LocationOnboardingState>(
      'initial state is LocationOnboardingLoading',
      build: () => LocationOnboardingBloc(logger: mockLogger, repository: mockRepo),
      act: (_) {},
      expect: () => [],
    );

    blocTest<LocationOnboardingBloc, LocationOnboardingState>(
      'emits LocationOnboardingLoaded(false) when onboarding was not seen',
      build: () {
        when(() => mockRepo.hasSeenLocationOnboarding())
            .thenAnswer((_) async => false);
        return LocationOnboardingBloc(logger: mockLogger, repository: mockRepo);
      },
      act: (bloc) => bloc.add(const LoadOnboardingStatusEvent()),
      expect: () => [
        const LocationOnboardingLoaded(hasSeenLocationOnboarding: false),
      ],
    );

    blocTest<LocationOnboardingBloc, LocationOnboardingState>(
      'emits LocationOnboardingLoaded(true) when onboarding was already seen',
      build: () {
        when(() => mockRepo.hasSeenLocationOnboarding())
            .thenAnswer((_) async => true);
        return LocationOnboardingBloc(logger: mockLogger, repository: mockRepo);
      },
      act: (bloc) => bloc.add(const LoadOnboardingStatusEvent()),
      expect: () => [
        const LocationOnboardingLoaded(hasSeenLocationOnboarding: true),
      ],
    );

    blocTest<LocationOnboardingBloc, LocationOnboardingState>(
      'emits LocationOnboardingError and logs when load throws',
      build: () {
        when(() => mockRepo.hasSeenLocationOnboarding())
            .thenThrow(Exception('fail'));
        return LocationOnboardingBloc(logger: mockLogger, repository: mockRepo);
      },
      act: (bloc) => bloc.add(const LoadOnboardingStatusEvent()),
      expect: () => [isA<LocationOnboardingError>()],
      verify: (_) {
        verify(() => mockLogger.e(any(), error: any(named: 'error'), stackTrace: any(named: 'stackTrace'))).called(1);
      },
    );

    blocTest<LocationOnboardingBloc, LocationOnboardingState>(
      'marks onboarding seen and emits LocationOnboardingLoaded(true)',
      build: () {
        when(() => mockRepo.markLocationOnboardingSeen())
            .thenAnswer((_) async {});
        return LocationOnboardingBloc(logger: mockLogger, repository: mockRepo);
      },
      act: (bloc) => bloc.add(const CompleteOnboardingEvent()),
      expect: () => [
        const LocationOnboardingLoaded(hasSeenLocationOnboarding: true),
      ],
      verify: (_) {
        verify(() => mockRepo.markLocationOnboardingSeen()).called(1);
      },
    );

    blocTest<LocationOnboardingBloc, LocationOnboardingState>(
      'still emits LocationOnboardingLoaded(true) and logs when mark throws',
      build: () {
        when(() => mockRepo.markLocationOnboardingSeen())
            .thenThrow(Exception('fail'));
        return LocationOnboardingBloc(logger: mockLogger, repository: mockRepo);
      },
      act: (bloc) => bloc.add(const CompleteOnboardingEvent()),
      expect: () => [
        const LocationOnboardingLoaded(hasSeenLocationOnboarding: true),
      ],
      verify: (_) {
        verify(() => mockLogger.e(any(), error: any(named: 'error'), stackTrace: any(named: 'stackTrace'))).called(1);
      },
    );
  });
}
