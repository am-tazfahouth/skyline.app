import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_line/core/errors/app_error.dart';
import 'package:sky_line/core/errors/setting_error_codes.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_event.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final AppLogger logger;
  final SettingRepository repository;
  final Future<String> Function() getAppVersion;

  SettingsBloc({
    required this.logger,
    required this.repository,
    this.getAppVersion = _defaultAppVersion,
  }) : super(const SettingsLoadSuccess()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateSettingsEvent>(_onUpdateSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final setting = await repository.loadSettings();
      String appVersion = '';
      try {
        appVersion = await getAppVersion();
      } catch (_) {
        appVersion = '';
      }
      emit(SettingsLoadSuccess(
        setting: setting,
        isLoaded: true,
        appVersion: appVersion,
      ));
    } catch (e, stackTrace) {
      logger.e(AppError.getDebugErrorMessage(SettingErrorCodes.load), error: e, stackTrace: stackTrace);
      emit(SettingsError(errorCode: SettingErrorCodes.load));
    }
  }

  Future<void> _onUpdateSettings(
    UpdateSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.saveSettings(event.setting);
      final previousVersion = state is SettingsLoadSuccess
          ? (state as SettingsLoadSuccess).appVersion
          : '';
      emit(SettingsLoadSuccess(
        setting: event.setting,
        isLoaded: true,
        appVersion: previousVersion,
      ));
    } catch (e, stackTrace) {
      logger.e(AppError.getDebugErrorMessage(SettingErrorCodes.update), error: e, stackTrace: stackTrace);
      emit(SettingsError(errorCode: SettingErrorCodes.update));
    }
  }
}

Future<String> _defaultAppVersion() async => '';
