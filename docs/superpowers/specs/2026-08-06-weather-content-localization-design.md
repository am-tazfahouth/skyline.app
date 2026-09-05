# Weather Content Localization — Design Spec

**Date:** 2026-08-06
**Feature:** Localize the weather content page (and adjacent weather screens) through the existing ARB system
**Status:** Approved

---

## 1. Overview

The app already ships a full localization pipeline: `flutter gen-l10n`, four ARB files (`intl_en.arb` template + `intl_fr.arb`, `intl_es.arb`, `intl_ar.arb`) in `lib/core/l10n/arb`, a committed generated `AppLocalisation` class, and `locale: Locale(getStringFromLang(setting.lang))` wired in `main.dart`. The settings screen already follows the `AppLocalisation.of(context)!` pattern.

However, the **weather content page** — `WeatherContentView` and its widget tree — still displays hard-coded English strings, and the date/time formats are hard-coded to English (e.g. `'26 June 2026'`). This spec localizes:

1. All user-visible static strings on the weather content page (`WeatherHeader`, `WeatherMainCard`, `WeatherStatsCard`, hourly + daily forecast lists, sun times card).
2. The weather **condition labels** produced by `WeatherFormat.condition` (`Clear`, `Rain`, `Thunderstorm`, ...).
3. The **date/time formats** on that page (main card date, daily day labels, sun times) so they follow the active language.
4. The **adjacent weather screens**: `Refreshing...` overlay, `Retry` on the error view, `Search for a location` on the initial view.
5. The **user-facing error messages** of `AppError.getUserErrorMessage` (currently English-only).

Language changes are already applied app-wide by `MaterialApp` (the `Localizations` inherited widget rebuilds dependents), so no BLoC or manual refresh is needed for the weather page. Arabic is handled automatically (RTL direction) because `supportedLocales` already includes `ar`.

---

## 2. Approach

Three approaches were considered:

- **A. Direct `AppLocalisation.of(context)` + ICU formats in ARB (chosen)** — Follows the existing settings-screen pattern. Date/time display patterns are declared as ICU messages in the ARB files (e.g. `"{date, date, ::dMMMMy}"`), so `gen-l10n` generates typed, locale-aware methods (`String weatherDateLong(DateTime date)`). `WeatherFormat.condition(code)` becomes `WeatherFormat.condition(code, l10n)`. `AppError.getUserErrorMessage(code)` becomes `getUserErrorMessage(code, l10n)`. No global state, fully testable.
- **B. Semantic keys from `WeatherFormat`, switch in each widget** — More indirection; the code→label switch would be duplicated in every consumer.
- **C. Global `Intl.defaultLocale` set on language change** — Mutable global state, pollutes unrelated `DateFormat` usage, breaks test isolation. Rejected.

### Rationale for A

- Zero new dependencies, zero new infrastructure.
- `gen-l10n` already supports ICU date/time placeholders; the generated methods format using the delegate's `localeName`, so `'26 June 2026'` becomes `'26 juin 2026'` (fr), `'26 de junio de 2026'` (es), Arabic formats, etc.
- Both `WeatherFormat` and `AppError` live in `core/`; depending on `core/l10n/app_localisation.dart` is allowed and keeps the code→label mapping in exactly one place.

---

## 3. New ARB Keys

All keys are added to all four ARB files (`intl_en.arb` with `@` descriptions, `intl_fr.arb`, `intl_es.arb`, `intl_ar.arb`).

### App / adjacent screens

| Key | EN | FR | ES | AR |
|---|---|---|---|---|
| `appTitle` | `SkyLine` | `SkyLine` | `SkyLine` | `SkyLine` |
| `weatherRefreshing` | `Refreshing...` | `Actualisation...` | `Actualizando...` | `جارٍ التحديث...` |
| `weatherRetry` | `Retry` | `Réessayer` | `Reintentar` | `إعادة المحاولة` |
| `weatherSearchForLocation` | `Search for a location` | `Recherchez un lieu` | `Buscar un lugar` | `ابحث عن مكان` |

### Date / time formats (ICU)

| Key | EN | Generated signature |
|---|---|---|
| `weatherDateLong` | `{date, date, ::dMMMMy}` | `String weatherDateLong(DateTime date)` |
| `weatherDayLabel` | `{date, date, ::E dMMM}` | `String weatherDayLabel(DateTime date)` |
| `weatherSunTime` | `{time, time, short}` | `String weatherSunTime(DateTime time)` |

Same ARB values in fr/es/ar (the pattern is locale-independent; output follows the active locale).

### Weather conditions

| Key | EN | FR | ES | AR |
|---|---|---|---|---|
| `weatherConditionClear` | `Clear` | `Ciel dégagé` | `Despejado` | `صافٍ` |
| `weatherConditionPartlyCloudy` | `Partly cloudy` | `Partiellement nuageux` | `Parcialmente nublado` | `غائم جزئياً` |
| `weatherConditionFoggy` | `Foggy` | `Brouillard` | `Niebla` | `ضبابي` |
| `weatherConditionDrizzle` | `Drizzle` | `Bruine` | `Llovizna` | `رذاذ` |
| `weatherConditionRain` | `Rain` | `Pluie` | `Lluvia` | `مطر` |
| `weatherConditionSnow` | `Snow` | `Neige` | `Nieve` | `ثلج` |
| `weatherConditionRainShowers` | `Rain showers` | `Averses` | `Chubascos` | `زخات مطر` |
| `weatherConditionThunderstorm` | `Thunderstorm` | `Orage` | `Tormenta` | `عاصفة رعدية` |

### Stats card

| Key | EN | FR | ES | AR |
|---|---|---|---|---|
| `weatherStatsWind` | `Wind` | `Vent` | `Viento` | `الرياح` |
| `weatherStatsChanceOfRain` | `Chance of rain` | `Risque de pluie` | `Probabilidad de lluvia` | `احتمال هطول المطر` |
| `weatherStatsHumidity` | `Humidity` | `Humidité` | `Humedad` | `الرطوبة` |

### Forecast lists

| Key | EN | FR | ES | AR |
|---|---|---|---|---|
| `weatherHourlyTitle` | `Hourly Forecast` | `Prévisions horaires` | `Pronóstico por horas` | `توقعات كل ساعة` |
| `weatherDailyTitle` | `Next 7 Days` | `7 prochains jours` | `Próximos 7 días` | `الأيام السبعة القادمة` |
| `weatherDayToday` | `Today` | `Aujourd'hui` | `Hoy` | `اليوم` |
| `weatherDayTomorrow` | `Tomorrow` | `Demain` | `Mañana` | `غداً` |

### Sun times

| Key | EN | FR | ES | AR |
|---|---|---|---|---|
| `weatherSunSunrise` | `Sunrise` | `Lever du soleil` | `Amanecer` | `شروق الشمس` |
| `weatherSunSunset` | `Sunset` | `Coucher du soleil` | `Atardecer` | `غروب الشمس` |
| `weatherSunZenith` | `Zenith` | `Zénith` | `Cenit` | `الذروة` |
| `weatherSunMidnight` | `Midnight` | `Minuit` | `Medianoche` | `منتصف الليل` |
| `weatherSunTitle` | `Sun Time` | `Heures du soleil` | `Hora solar` | `وقت الشمس` |
| `weatherNightTitle` | `Night Time` | `Heures de nuit` | `Hora nocturna` | `وقت الليل` |

### AppError user messages

| Key | EN | FR | ES | AR |
|---|---|---|---|---|
| `errorNetwork` | `No internet connection. Please check your network.` | `Pas de connexion internet. Vérifiez votre réseau.` | `Sin conexión a internet. Compruebe su red.` | `لا يوجد اتصال بالإنترنت. يرجى التحقق من شبكتك.` |
| `errorFetch` | `Could not load weather data. Please try again.` | `Impossible de charger les données météo. Veuillez réessayer.` | `No se pudieron cargar los datos meteorológicos. Inténtelo de nuevo.` | `تعذّر تحميل بيانات الطقس. يرجى المحاولة مرة أخرى.` |
| `errorCache` | `Could not save weather data locally.` | `Impossible d'enregistrer les données météo localement.` | `No se pudieron guardar los datos meteorológicos localmente.` | `تعذّر حفظ بيانات الطقس محلياً.` |
| `errorLoadCache` | `Could not load cached weather data.` | `Impossible de charger les données météo en cache.` | `No se pudieron cargar los datos meteorológicos guardados.` | `تعذّر تحميل بيانات الطقس المحفوظة.` |
| `errorUnexpected` | `Something went wrong. Please try again.` | `Une erreur est survenue. Veuillez réessayer.` | `Algo salió mal. Inténtelo de nuevo.` | `حدث خطأ ما. يرجى المحاولة مرة أخرى.` |
| `errorLoadSetting` | `Could not load your preferences.` | `Impossible de charger vos préférences.` | `No se pudieron cargar sus preferencias.` | `تعذّر تحميل تفضيلاتك.` |
| `errorUpdateSetting` | `Could not save your preferences.` | `Impossible d'enregistrer vos préférences.` | `No se pudieron guardar sus preferencias.` | `تعذّر حفظ تفضيلاتك.` |
| `errorLocation` | `Could not get your location. Please check permissions.` | `Impossible d'obtenir votre position. Vérifiez les autorisations.` | `No se pudo obtener su ubicación. Compruebe los permisos.` | `تعذّر الحصول على موقعك. يرجى التحقق من الأذونات.` |
| `errorSearch` | `Could not search cities. Please try again.` | `Impossible de rechercher des villes. Veuillez réessayer.` | `No se pudieron buscar ciudades. Inténtelo de nuevo.` | `تعذّر البحث عن المدن. يرجى المحاولة مرة أخرى.` |
| `errorGpsDisabled` | `Location services are turned off.` | `Les services de localisation sont désactivés.` | `Los servicios de ubicación están desactivados.` | `خدمات الموقع معطّلة.` |
| `errorGpsPermissionDenied` | `Location permission is required to get your current location.` | `L'autorisation de localisation est requise pour obtenir votre position actuelle.` | `Se requiere el permiso de ubicación para obtener su ubicación actual.` | `يجب منح إذن الموقع للحصول على موقعك الحالي.` |
| `errorGpsPermissionPermanentlyDenied` | `Location permission is permanently denied. Please enable it in Settings.` | `L'autorisation de localisation est refusée définitivement. Activez-la dans les Réglages.` | `El permiso de ubicación está denegado permanentemente. Actívelo en los Ajustes.` | `تم رفض إذن الموقع نهائياً. يرجى تفعيله في الإعدادات.` |

---

## 4. Architecture & Component Changes

### 4.1 `core/utils/weather_format.dart`

```dart
static String condition(int weatherCode, AppLocalisation l10n) {
  if (weatherCode == 0) return l10n.weatherConditionClear;
  if (weatherCode <= 3) return l10n.weatherConditionPartlyCloudy;
  if (weatherCode <= 48) return l10n.weatherConditionFoggy;
  if (weatherCode <= 55) return l10n.weatherConditionDrizzle;
  if (weatherCode <= 65) return l10n.weatherConditionRain;
  if (weatherCode <= 75) return l10n.weatherConditionSnow;
  if (weatherCode <= 82) return l10n.weatherConditionRainShowers;
  return l10n.weatherConditionThunderstorm;
}
```

- Import `package:sky_line/core/l10n/app_localisation.dart`.
- **Remove** `WeatherFormat.date` — its only caller (`WeatherMainCard`) switches to `l10n.weatherDateLong`.

### 4.2 `core/errors/app_error.dart`

`getUserErrorMessage` gains an `AppLocalisation` parameter and returns localized strings:

```dart
static String getUserErrorMessage(AppErrorCode code, AppLocalisation l10n) {
  if (code == LocationErrorCodes.gpsDisabled) return l10n.errorGpsDisabled;
  if (code == LocationErrorCodes.gpsPermissionDenied) return l10n.errorGpsPermissionDenied;
  if (code == LocationErrorCodes.gpsPermissionPermanentlyDenied) return l10n.errorGpsPermissionPermanentlyDenied;
  return switch (_userErrorTypeMap[code] ?? UserErrorType.unexpected) {
    UserErrorType.network => l10n.errorNetwork,
    UserErrorType.fetch => l10n.errorFetch,
    UserErrorType.cache => l10n.errorCache,
    UserErrorType.loadCache => l10n.errorLoadCache,
    UserErrorType.unexpected => l10n.errorUnexpected,
    UserErrorType.loadSetting => l10n.errorLoadSetting,
    UserErrorType.updateSetting => l10n.errorUpdateSetting,
    UserErrorType.location => l10n.errorLocation,
    UserErrorType.search => l10n.errorSearch,
  };
}
```

- The `_userMessages` map is removed (its three entries become the explicit code checks above).
- `getDebugErrorMessage` and `_debugErrorMessages` stay **English-only** (log-only, never user-visible).

### 4.3 Callers of `AppError.getUserErrorMessage`

All four call sites pass the `AppLocalisation` from context:

| File | Change |
|---|---|
| `features/weather_forecast/presentation/screens/weather_screen.dart` | `_contentFor` takes `BuildContext`; `WeatherErrorView(message: AppError.getUserErrorMessage(code, l10n))`; overlay `'Refreshing...'` → `l10n.weatherRefreshing` |
| `features/settings/presentation/screens/settings_screen.dart` | SnackBar content uses the l10n already fetched in `build` |
| `features/location/presentation/screens/location_screen.dart` | SnackBar content passes `AppLocalisation.of(context)!` (fetched in the listener) |
| `features/location/presentation/screens/location_search_screen.dart` | Inline error passes l10n from `build` |

The static UI strings of the settings/location screens are **out of scope** (this spec only localizes their error messages, forced by the shared `AppError` signature).

### 4.4 Weather widgets

Each widget reads `final l10n = AppLocalisation.of(context)!;` in `build` and replaces literals:

| Widget | Replacements |
|---|---|
| `weather_header.dart` | `'SkyLine'` fallback → `l10n.appTitle` |
| `weather_main_card.dart` | `WeatherFormat.date(...)` → `l10n.weatherDateLong(DateTime.now())`; `WeatherFormat.condition(code)` → `WeatherFormat.condition(code, l10n)`; placeholders `'--'` / `'--°C'` unchanged |
| `weather_stats_card.dart` | `'Wind'` → `l10n.weatherStatsWind`; `'Chance of rain'` → `l10n.weatherStatsChanceOfRain`; `'Humidity'` → `l10n.weatherStatsHumidity` |
| `weather_daily_tile_list.dart` | `'Next 7 Days'` → `l10n.weatherDailyTitle`; `_formatDayLabel` → `'Today'`/`'Tomorrow'` via l10n, other days via `l10n.weatherDayLabel(date)`; `WeatherFormat.condition(code)` → `(code, l10n)` |
| `weather_hourly_tile_list.dart` | `'Hourly Forecast'` → `l10n.weatherHourlyTitle`; time stays `DateFormat('HH:mm')` (numeric, locale-neutral) |
| `weather_sun_times.dart` | `PeriodConfig.compute(..., l10n: l10n)`; placeholder `TimePointData` labels → l10n (no longer `const`) |
| `views/weather_error_view.dart` | `'Retry'` → `l10n.weatherRetry` |
| `views/weather_initial_view.dart` | `'Search for a location'` → `l10n.weatherSearchForLocation` |

### 4.5 `sun_time/sun_times_ui_model.dart`

`PeriodConfig.compute` gains a required `AppLocalisation l10n` parameter:

- `'Sunrise'` / `'Sunset'` → `l10n.weatherSunSunrise` / `l10n.weatherSunSunset`.
- `'Sun Time'` / `'Night Time'` → `l10n.weatherSunTitle` / `l10n.weatherNightTitle`.
- `DateFormat('hh:mm a')` → `l10n.weatherSunTime(dateTime)` (locale-aware `short` time).
- **Precompute the middle point**: the current `middle` getter builds `'Zenith'` / `'Midnight'` + `DateFormat('hh:mm a')` lazily. Store `middleLabel` and `middleTime` (computed in the factory using `l10n.weatherSunZenith` / `l10n.weatherSunMidnight` and `l10n.weatherSunTime`) as constructor fields; keep the public `middle` getter so `WeatherSunTimes` is unchanged. This keeps `PeriodConfig` pure/`Equatable` (no `AppLocalisation` reference stored in the object).

---

## 5. Data Flow

```
Language change in Settings (selectLangDialog)
  → SettingsBloc emits updated SettingEntity
  → main.dart MaterialApp.locale = Locale(newLang)
  → Localizations inherited widget rebuilds dependents
  → weather widgets' build() re-runs with new AppLocalisation
  → l10n.weatherXxx + DateFormat(localeName) produce localized output
```

No BLoC event, no repository change, no rebuild orchestration is required on the weather side.

---

## 6. Error Handling

- All user-facing `AppError` messages come from `AppLocalisation`; debug strings remain English and are never rendered.
- The non-null assertion `AppLocalisation.of(context)!` is safe in production (delegates always present) and in widget tests once the delegates are added to the test harnesses.
- Placeholder states (`'--'`, `'--°C'`, `'-- m/s'`, `'--%'`, `'--:--'`, `'--°'`) are locale-neutral and unchanged.

---

## 7. Testing Strategy

TDD; `flutter analyze` (zero warnings) and `flutter test` must pass.

- **Unit — `weather_format_test.dart`**: `condition` tests pass `AppLocalisationEn()` and keep asserting English labels; add a French assertion via `AppLocalisationFr()`; remove the `WeatherFormat.date` test.
- **Unit — `app_error_location_test.dart`**: `getUserErrorMessage` tests pass `AppLocalisationEn()`.
- **Widget — `weather_screen_test.dart`**: add `localizationsDelegates: AppLocalisation.localizationsDelegates` and `supportedLocales: AppLocalisation.supportedLocales` to `createTestScreen`. Existing assertions (`'Retry'`, `'SkyLine'`, `'28°C'`, `'12 m/s'`, `'65%'`) remain valid under the default `en` locale.
- **Widget — `weather_sun_times_test.dart`**: add the delegates/supported locales to `buildScreen`.
- **Widget — `location_screen_test.dart` / `location_search_screen_test.dart`**: add the delegates/supported locales (the screens now call `AppLocalisation.of` on error paths).

---

## 8. Commands

| Step | Command |
|---|---|
| Regenerate l10n after ARB edits | `flutter gen-l10n` |
| Static analysis | `flutter analyze` |
| Full test suite | `flutter test` |

---

## 9. Non-Goals / Out of Scope

- No localization of the settings screen cards or location screen UI strings (only their shared `AppError` messages).
- No localization of `getDebugErrorMessage`.
- No change to the hourly tile time format (`HH:mm` stays).
- No change to the ARB file layout, generation config (`l10n.yaml`), or locale switching logic in `main.dart`.
- No new localization infrastructure.
