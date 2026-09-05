import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/config/db_helper/db_helper.dart';
import 'package:sky_line/core/config/db_helper/setting_cache_entity.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/features/settings/data/models/setting_model.dart';
import 'package:sky_line/features/settings/data/repositories/setting_repository_impl.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';

class MockDbHelper extends Mock implements DbHelper {}

void main() {
  late MockDbHelper mockDbHelper;
  late SettingRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      SettingCacheEntity(
        id: 1,
        themeValue: 'system',
        langValue: 'en',
        windUnitValue: 'ms',
        heatUnitValue: 'celsius',
      ),
    );
    registerFallbackValue(const SettingModel());
  });

  setUp(() {
    mockDbHelper = MockDbHelper();
    repository = SettingRepositoryImpl(mockDbHelper);
  });

  group('loadSettings', () {
    group('loadSettings first launch (null cache)', () {
      setUp(() {
        when(() => mockDbHelper.loadSettings()).thenReturn(null);
        when(() => mockDbHelper.saveSettings(any())).thenReturn(null);
      });

      test(
        'should use provider language and persist on first launch',
        () async {
          repository = SettingRepositoryImpl.withSystemLang(
            mockDbHelper,
            () => SettingLang.fr,
          );

          final result = await repository.loadSettings();

          expect(result.lang, SettingLang.fr);
          expect(result.theme, SettingTheme.system);
          verify(() => mockDbHelper.saveSettings(any())).called(1);
        },
      );

      test(
        'should fall back to en for unsupported provider language',
        () async {
          repository = SettingRepositoryImpl.withSystemLang(
            mockDbHelper,
            () => SettingLang.en,
          );

          final result = await repository.loadSettings();

          expect(result.lang, SettingLang.en);
          verify(() => mockDbHelper.saveSettings(any())).called(1);
        },
      );
    });

    test('should return cached entity converted to domain', () async {
      final entity = SettingCacheEntity(
        id: 1,
        themeValue: 'dark',
        langValue: 'fr',
        windUnitValue: 'kmh',
        heatUnitValue: 'fahrenheit',
      );
      when(() => mockDbHelper.loadSettings()).thenReturn(entity);

      final result = await repository.loadSettings();

      expect(result.theme, SettingTheme.dark);
      expect(result.lang, SettingLang.fr);
      expect(result.windUnit, SettingWindUnit.kmh);
      expect(result.heatUnit, SettingHeatUnit.fahrenheit);
    });

    test(
      'should keep persisted language and not save when cache exists',
      () async {
        final entity = SettingCacheEntity(
          id: 1,
          themeValue: 'system',
          langValue: 'es',
          windUnitValue: 'ms',
          heatUnitValue: 'celsius',
        );
        when(() => mockDbHelper.loadSettings()).thenReturn(entity);
        repository = SettingRepositoryImpl.withSystemLang(
          mockDbHelper,
          () => SettingLang.fr,
        );

        final result = await repository.loadSettings();

        expect(result.lang, SettingLang.es);
        verifyNever(() => mockDbHelper.saveSettings(any()));
      },
    );
  });

  group('saveSettings', () {
    test('should save through dbHelper', () async {
      final setting = const SettingEntity(
        theme: SettingTheme.light,
        lang: SettingLang.ar,
        windUnit: SettingWindUnit.ms,
        heatUnit: SettingHeatUnit.celsius,
      );
      when(() => mockDbHelper.saveSettings(any())).thenReturn(null);

      await repository.saveSettings(setting);

      verify(() => mockDbHelper.saveSettings(any())).called(1);
    });
  });
}
