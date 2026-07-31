import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_line/core/services/logger_sevices.dart';
import 'package:sky_line/features/settings/domain/entities/setting_entity.dart';
import 'package:sky_line/features/settings/domain/repositories/setting_repository.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:sky_line/features/settings/presentation/blocs/settings_event.dart';
import 'package:sky_line/features/settings/presentation/screens/settings_screen.dart';
import 'package:sky_line/core/l10n/app_localisation.dart';

class MockSettingRepository extends Mock implements SettingRepository {}

class MockAppLogger extends Mock implements AppLogger {}

Widget createTestScreen(SettingsBloc bloc) {
  return MaterialApp(
    localizationsDelegates: AppLocalisation.localizationsDelegates,
    supportedLocales: AppLocalisation.supportedLocales,
    home: BlocProvider<SettingsBloc>.value(
      value: bloc,
      child: const SettingsScreen(),
    ),
  );
}

void main() {
  late MockSettingRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingRepository();
    when(() => mockRepository.loadSettings()).thenAnswer(
      (_) async => SettingEntity.defaults,
    );
  });

  testWidgets('should display settings title', (tester) async {
    final bloc = SettingsBloc(logger: MockAppLogger(), repository: mockRepository);
    bloc.add(const LoadSettingsEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('should display all setting tiles', (tester) async {
    final bloc = SettingsBloc(logger: MockAppLogger(), repository: mockRepository);
    bloc.add(const LoadSettingsEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Wind'), findsOneWidget);
    expect(find.text('Temperature'), findsOneWidget);
  });

  testWidgets('should display setting descriptions', (tester) async {
    final bloc = SettingsBloc(logger: MockAppLogger(), repository: mockRepository);
    bloc.add(const LoadSettingsEvent());
    await tester.pumpWidget(createTestScreen(bloc));
    await tester.pumpAndSettle();

    expect(find.text('Choose the theme of the application'), findsOneWidget);
    expect(find.text('Choose the language of the application'), findsOneWidget);
    expect(find.text('Choose the unit of measurement for wind'), findsOneWidget);
    expect(find.text('Choose the unit of measurement of the temperature'), findsOneWidget);
  });
}
