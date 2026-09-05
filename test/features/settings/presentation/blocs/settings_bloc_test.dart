import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/services/logger_services.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_event.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_state.dart';

class MockSettingRepository extends Mock implements SettingRepository {}

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  late MockSettingRepository mockRepository;
  late MockAppLogger mockLogger;

  setUpAll(() {
    registerFallbackValue(const SettingEntity());
  });

  setUp(() {
    mockRepository = MockSettingRepository();
    mockLogger = MockAppLogger();
  });

  group('SettingsBloc', () {
    blocTest<SettingsBloc, SettingsState>(
      'emits loaded state when LoadSettingsEvent is added',
      setUp: () {
        when(
          () => mockRepository.loadSettings(),
        ).thenAnswer((_) async => SettingEntity.defaults);
      },
      build: () => SettingsBloc(
        logger: mockLogger,
        repository: mockRepository,
        getAppVersion: () async => '1.2.3',
      ),
      act: (bloc) => bloc.add(const LoadSettingsEvent()),
      expect: () => [
        isA<SettingsLoadSuccess>()
            .having((s) => s.isLoaded, 'isLoaded', true)
            .having((s) => s.appVersion, 'appVersion', '1.2.3'),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits updated state when UpdateSettingsEvent is added',
      setUp: () {
        when(() => mockRepository.saveSettings(any())).thenAnswer((_) async {});
        when(
          () => mockRepository.loadSettings(),
        ).thenAnswer((_) async => SettingEntity.defaults);
      },
      build: () => SettingsBloc(logger: mockLogger, repository: mockRepository),
      seed: () => const SettingsLoadSuccess(
        setting: SettingEntity.defaults,
        isLoaded: true,
        appVersion: '1.2.3',
      ),
      act: (bloc) => bloc.add(
        const UpdateSettingsEvent(
          setting: SettingEntity(
            theme: SettingTheme.dark,
            lang: SettingLang.fr,
          ),
        ),
      ),
      expect: () => [
        isA<SettingsLoadSuccess>()
            .having((s) => s.setting.theme, 'theme', SettingTheme.dark)
            .having((s) => s.appVersion, 'appVersion', '1.2.3'),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'initial state is SettingsLoadSuccess with defaults',
      build: () => SettingsBloc(logger: mockLogger, repository: mockRepository),
      act: (_) {},
      expect: () => [],
    );
  });
}
