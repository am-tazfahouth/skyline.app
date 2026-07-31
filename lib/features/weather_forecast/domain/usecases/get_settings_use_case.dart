import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';

class GetSettingsUseCase {
  final SettingRepository repository;

  GetSettingsUseCase(this.repository);

  Future<SettingEntity> call() => repository.loadSettings();
}
