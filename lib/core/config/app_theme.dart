import "package:flutter/material.dart";
import "package:sky_line/core/constants/app_text_styles.dart";

class AppTheme {
  final TextTheme textTheme;

  const AppTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff535a92),
      surfaceTint: Color(0xff535a92),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffdfe0ff),
      onPrimaryContainer: Color(0xff3b4279),
      secondary: Color(0xff5b5d72),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffe0e0f9),
      onSecondaryContainer: Color(0xff444559),
      tertiary: Color(0xff77536c),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffffd7f0),
      onTertiaryContainer: Color(0xff5e3c54),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffbf8ff),
      onSurface: Color(0xff1b1b21),
      onSurfaceVariant: Color(0xff46464f),
      outline: Color(0xff777680),
      outlineVariant: Color(0xffc7c5d0),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff303036),
      inversePrimary: Color(0xffbcc2ff),
      primaryFixed: Color(0xffdfe0ff),
      onPrimaryFixed: Color(0xff0d154b),
      primaryFixedDim: Color(0xffbcc2ff),
      onPrimaryFixedVariant: Color(0xff3b4279),
      secondaryFixed: Color(0xffe0e0f9),
      onSecondaryFixed: Color(0xff181a2c),
      secondaryFixedDim: Color(0xffc4c5dd),
      onSecondaryFixedVariant: Color(0xff444559),
      tertiaryFixed: Color(0xffffd7f0),
      onTertiaryFixed: Color(0xff2d1127),
      tertiaryFixedDim: Color(0xffe6bad6),
      onTertiaryFixedVariant: Color(0xff5e3c54),
      surfaceDim: Color(0xffdbd9e0),
      surfaceBright: Color(0xfffbf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff5f2fa),
      surfaceContainer: Color(0xffefedf4),
      surfaceContainerHigh: Color(0xffe9e7ef),
      surfaceContainerHighest: Color(0xffe4e1e9),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff2a3167),
      surfaceTint: Color(0xff535a92),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff6269a2),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff333548),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff6a6b81),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff4b2c43),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff87627b),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffbf8ff),
      onSurface: Color(0xff101116),
      onSurfaceVariant: Color(0xff35353e),
      outline: Color(0xff52525b),
      outlineVariant: Color(0xff6d6c76),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff303036),
      inversePrimary: Color(0xffbcc2ff),
      primaryFixed: Color(0xff6269a2),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff495088),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff6a6b81),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff525368),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff87627b),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff6d4a62),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc7c5cd),
      surfaceBright: Color(0xfffbf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff5f2fa),
      surfaceContainer: Color(0xffe9e7ef),
      surfaceContainerHigh: Color(0xffdedce3),
      surfaceContainerHighest: Color(0xffd3d0d8),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff20275c),
      surfaceTint: Color(0xff535a92),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff3e457b),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff292b3d),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff46485c),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff402238),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff603e56),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffbf8ff),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff2b2b34),
      outlineVariant: Color(0xff484851),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff303036),
      inversePrimary: Color(0xffbcc2ff),
      primaryFixed: Color(0xff3e457b),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff272e63),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff46485c),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff2f3144),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff603e56),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff47283f),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffbab8bf),
      surfaceBright: Color(0xfffbf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff2eff7),
      surfaceContainer: Color(0xffe4e1e9),
      surfaceContainerHigh: Color(0xffd6d3db),
      surfaceContainerHighest: Color(0xffc7c5cd),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffbcc2ff),
      surfaceTint: Color(0xffbcc2ff),
      onPrimary: Color(0xff242b61),
      primaryContainer: Color(0xff3b4279),
      onPrimaryContainer: Color(0xffdfe0ff),
      secondary: Color(0xffc4c5dd),
      onSecondary: Color(0xff2d2f42),
      secondaryContainer: Color(0xff444559),
      onSecondaryContainer: Color(0xffe0e0f9),
      tertiary: Color(0xffe6bad6),
      onTertiary: Color(0xff45263d),
      tertiaryContainer: Color(0xff5e3c54),
      onTertiaryContainer: Color(0xffffd7f0),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff131318),
      onSurface: Color(0xffe4e1e9),
      onSurfaceVariant: Color(0xffc7c5d0),
      outline: Color(0xff90909a),
      outlineVariant: Color(0xff46464f),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe4e1e9),
      inversePrimary: Color(0xff535a92),
      primaryFixed: Color(0xffdfe0ff),
      onPrimaryFixed: Color(0xff0d154b),
      primaryFixedDim: Color(0xffbcc2ff),
      onPrimaryFixedVariant: Color(0xff3b4279),
      secondaryFixed: Color(0xffe0e0f9),
      onSecondaryFixed: Color(0xff181a2c),
      secondaryFixedDim: Color(0xffc4c5dd),
      onSecondaryFixedVariant: Color(0xff444559),
      tertiaryFixed: Color(0xffffd7f0),
      onTertiaryFixed: Color(0xff2d1127),
      tertiaryFixedDim: Color(0xffe6bad6),
      onTertiaryFixedVariant: Color(0xff5e3c54),
      surfaceDim: Color(0xff131318),
      surfaceBright: Color(0xff39393f),
      surfaceContainerLowest: Color(0xff0d0e13),
      surfaceContainerLow: Color(0xff1b1b21),
      surfaceContainer: Color(0xff1f1f25),
      surfaceContainerHigh: Color(0xff29292f),
      surfaceContainerHighest: Color(0xff34343a),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffd7daff),
      surfaceTint: Color(0xffbcc2ff),
      onPrimary: Color(0xff192055),
      primaryContainer: Color(0xff868dc8),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffdadaf3),
      onSecondary: Color(0xff222437),
      secondaryContainer: Color(0xff8e8fa6),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xfffecfec),
      onTertiary: Color(0xff391c31),
      tertiaryContainer: Color(0xffad859f),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff131318),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffdddbe6),
      outline: Color(0xffb2b1bb),
      outlineVariant: Color(0xff908f99),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe4e1e9),
      inversePrimary: Color(0xff3c437a),
      primaryFixed: Color(0xffdfe0ff),
      onPrimaryFixed: Color(0xff020841),
      primaryFixedDim: Color(0xffbcc2ff),
      onPrimaryFixedVariant: Color(0xff2a3167),
      secondaryFixed: Color(0xffe0e0f9),
      onSecondaryFixed: Color(0xff0e1021),
      secondaryFixedDim: Color(0xffc4c5dd),
      onSecondaryFixedVariant: Color(0xff333548),
      tertiaryFixed: Color(0xffffd7f0),
      onTertiaryFixed: Color(0xff21071c),
      tertiaryFixedDim: Color(0xffe6bad6),
      onTertiaryFixedVariant: Color(0xff4b2c43),
      surfaceDim: Color(0xff131318),
      surfaceBright: Color(0xff44444a),
      surfaceContainerLowest: Color(0xff07070c),
      surfaceContainerLow: Color(0xff1d1d23),
      surfaceContainer: Color(0xff27272d),
      surfaceContainerHigh: Color(0xff323238),
      surfaceContainerHighest: Color(0xff3d3d43),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfff0eeff),
      surfaceTint: Color(0xffbcc2ff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffb8befd),
      onPrimaryContainer: Color(0xff000336),
      secondary: Color(0xfff0eeff),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffc0c1d9),
      onSecondaryContainer: Color(0xff080a1b),
      tertiary: Color(0xffffebf5),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffe2b6d2),
      onTertiaryContainer: Color(0xff1a0316),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff131318),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xfff1effa),
      outlineVariant: Color(0xffc3c1cc),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe4e1e9),
      inversePrimary: Color(0xff3c437a),
      primaryFixed: Color(0xffdfe0ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffbcc2ff),
      onPrimaryFixedVariant: Color(0xff020841),
      secondaryFixed: Color(0xffe0e0f9),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffc4c5dd),
      onSecondaryFixedVariant: Color(0xff0e1021),
      tertiaryFixed: Color(0xffffd7f0),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffe6bad6),
      onTertiaryFixedVariant: Color(0xff21071c),
      surfaceDim: Color(0xff131318),
      surfaceBright: Color(0xff504f56),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1f1f25),
      surfaceContainer: Color(0xff303036),
      surfaceContainerHigh: Color(0xff3b3b41),
      surfaceContainerHighest: Color(0xff46464c),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) {
    final baseTextTheme = colorScheme.brightness == Brightness.light
      ? Typography.material2021().black
      :  Typography.material2021().white;

    final customTextTheme = createTextTheme(
      baseTextTheme: baseTextTheme, 
      bodyFontFamily: "SFPro", 
      displayFontFamily: "SFPro"
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        elevation: 0.5,
        scrolledUnderElevation: 1,
        shadowColor: Colors.grey,
        surfaceTintColor: colorScheme.surface,
        backgroundColor: colorScheme.surface,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.brightness == Brightness.light ?colorScheme.surface: colorScheme.surfaceContainerLow,
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerLow)
      ),
      dialogTheme: DialogThemeData(
        shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: colorScheme.brightness == Brightness.light ?colorScheme.surface: colorScheme.surfaceContainerLow,
      ),
      snackBarTheme: SnackBarThemeData(
        elevation: 1,
        showCloseIcon: true,
        contentTextStyle: TextStyle(
          color: colorScheme.surface,
          fontWeight: FontWeight.w500
        ),
        behavior: SnackBarBehavior.floating,
        closeIconColor: colorScheme.surface,
        dismissDirection: DismissDirection.horizontal,
        backgroundColor: colorScheme.inverseSurface,
        shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: customTextTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      bottomAppBarTheme: BottomAppBarThemeData(
        elevation: 1,
        shadowColor: Colors.grey,
        color: colorScheme.surfaceContainerLowest,
        surfaceTintColor: colorScheme.onInverseSurface
      ),
      extensions: [
        TextStyleCatalog.fromColorScheme(colorScheme),
      ]
    );
  }

  TextTheme createTextTheme({ required TextTheme baseTextTheme, required String bodyFontFamily, required String displayFontFamily }) {  
    // For eache style "display" (titres, headlines…), we change la the font
    final display = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(fontFamily: displayFontFamily),
      displayMedium: baseTextTheme.displayMedium?.copyWith(fontFamily: displayFontFamily),
      displaySmall: baseTextTheme.displaySmall?.copyWith(fontFamily: displayFontFamily),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontFamily: displayFontFamily),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontFamily: displayFontFamily),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontFamily: displayFontFamily),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontFamily: displayFontFamily),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontFamily: displayFontFamily),
      titleSmall: baseTextTheme.titleSmall?.copyWith(fontFamily: displayFontFamily),
    );

    return display.copyWith(
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontFamily: bodyFontFamily),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontFamily: bodyFontFamily),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontFamily: bodyFontFamily),
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontFamily: bodyFontFamily),
      labelMedium: baseTextTheme.labelMedium?.copyWith(fontFamily: bodyFontFamily),
      labelSmall: baseTextTheme.labelSmall?.copyWith(fontFamily: bodyFontFamily),
    );
  }

  static const ExtendedColor uiSurface = ExtendedColor(
    seed: Color(0xFF6750A4),
    value: Color(0xFF6750A4),
    light: ColorFamily(
      color: Color(0xfffbf8ff),
      onColor: Color(0xff1b1b21),
      colorContainer: Color(0xffe4e1e9),
      onColorContainer: Color(0xff46464f),
    ),
    lightMediumContrast: ColorFamily(
      color: Color(0xfffbf8ff),
      onColor: Color(0xff101116),
      colorContainer: Color(0xffd3d0d8),
      onColorContainer: Color(0xff35353e),
    ),
    lightHighContrast: ColorFamily(
      color: Color(0xfffbf8ff),
      onColor: Color(0xff000000),
      colorContainer: Color(0xffc7c5cd),
      onColorContainer: Color(0xff000000),
    ),
    dark: ColorFamily(
      color: Color(0xFF121212),
      onColor: Color(0xFFFFFFFF),
      colorContainer: Color(0xFF1E1E1E),
      onColorContainer: Color(0xFF888888),
    ),
    darkMediumContrast: ColorFamily(
      color: Color(0xFF121212),
      onColor: Color(0xFFFFFFFF),
      colorContainer: Color(0xFF1E1E1E),
      onColorContainer: Color(0xFF888888),
    ),
    darkHighContrast: ColorFamily(
      color: Color(0xFF121212),
      onColor: Color(0xFFFFFFFF),
      colorContainer: Color(0xFF1E1E1E),
      onColorContainer: Color(0xFF888888),
    ),
  );

  static ColorFamily surfaceFor(Brightness brightness) {
    return switch (brightness) {
      Brightness.light => uiSurface.light,
      Brightness.dark => uiSurface.dark,
    };
  }

  List<ExtendedColor> get extendedColors => [AppTheme.uiSurface];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
