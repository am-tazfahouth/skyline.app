import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/enums/setting_heat_unit.dart';
import 'package:sky_line/core/enums/setting_lang.dart';
import 'package:sky_line/core/enums/setting_theme.dart';
import 'package:sky_line/core/enums/setting_wind_unit.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';
import 'package:sky_line/features/weather_forecast/domain/usecases/get_settings_use_case.dart';

class MockSettingRepository extends Mock implements SettingRepository {}

void main() {
  late MockSettingRepository mockRepository;
  late GetSettingsUseCase useCase;

  setUp(() {
    mockRepository = MockSettingRepository();
    useCase = GetSettingsUseCase(mockRepository);
  });

  test('returns settings from repository', () async {
    const expected = SettingEntity(
      theme: SettingTheme.dark,
      lang: SettingLang.fr,
      windUnit: SettingWindUnit.kmh,
      heatUnit: SettingHeatUnit.fahrenheit,
    );
    when(() => mockRepository.loadSettings())
        .thenAnswer((_) async => expected);

    final result = await useCase();

    expect(result, expected);
    verify(() => mockRepository.loadSettings()).called(1);
  });
}
