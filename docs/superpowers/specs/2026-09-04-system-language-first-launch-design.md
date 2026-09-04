# Detection automatique de la langue au premier demarrage

**Date** : 2026-09-04
**Feature** : settings / language
**Statut** : design valide

## Probleme

Au premier demarrage de l'application, la langue par defaut est `en` (`SettingEntity.defaults`), quel que soit le langage du systeme/materiel. L'utilisateur doit donc changer manuellement la langue dans les parametres, meme si celle de son appareil est deja supportee par l'application.

Langues supportees par l'application : `en`, `fr`, `es`, `ar`.

## Objectif

Au **premier demarrage uniquement** (absence de reglage persiste en base), l'application doit regler automatiquement sa langue sur celle du systeme si elle est supportee. Si la langue du systeme ne correspond a aucune langue supportee, l'application utilise `en` comme fallback.

La langue ainsi choisie devient un reglage manuel par defaut, modifiable ensuite dans les parametres (elle ne doit pas re-appliquer le reglage systeme a chaque lancement).

## Approche retenue

Approche **A (couche Data) + injection testable**. Aucun changement dans la presentation, le BLoC, `main.dart` ni l'injection container.

Le flux existant reste inchange :
- `main.dart` lit `setting.lang` via `SettingsBloc` / `SettingsLoadSuccess`.
- `SettingRepositoryImpl.loadSettings()` est le point d'entree du premier demarrage : il retourne `SettingEntity.defaults` quand rien n'existe en base.

## Conception

### 1. `lib/core/utils/platform_utils.dart` — detection de la langue systeme

Ajouter une methode statique qui resout la langue supportee du systeme avec fallback `en` :

```dart
// Resolve supported system language, fallback to en
static SettingLang getSystemLang() {
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  return getLangFromString(locale.languageCode);
}
```

- Reutilise `getLangFromString(String)` de `lib/core/enums/setting_lang.dart`, qui fait deja le mapping `en/fr/es/ar` avec fallback `en`.
- Importer `setting_lang.dart` : pas de cycle (ce fichier n'importe pas `platform_utils`).
- Coherent avec le pattern existant `is24HourFormat()` qui lit `platformDispatcher`.

### 2. `lib/features/settings/data/repositories/setting_repository_impl.dart` — injection + premier demarrage

Ajouter un provider injectable `systemLangProvider`, avec un constructeur nomme dedie aux tests pour ne pas impacter l'injection container existante :

```dart
class SettingRepositoryImpl implements SettingRepository {
  final DbHelper _dbHelper;
  final SettingLang Function() systemLangProvider;

  SettingRepositoryImpl(this._dbHelper)
      : systemLangProvider = PlatformUtils.getSystemLang;

  @visibleForTesting
  SettingRepositoryImpl.withSystemLang(
    this._dbHelper,
    this.systemLangProvider,
  );

  @override
  Future<SettingEntity> loadSettings() async {
    final cached = _dbHelper.loadSettings();
    if (cached == null) {
      final lang = systemLangProvider();
      final setting = SettingEntity.defaults.copyWith(lang: lang);
      saveSettings(setting);
      return setting;
    }
    return SettingMapper.toEntity(SettingMapper.fromCacheEntity(cached));
  }

  // saveSettings inchange
}
```

Comportement :
- Si `cached == null` (premier demarrage) : langue systeme resolue, reglage persiste (`saveSettings`), valeur retournee.
- Si un reglage existe : langue conservee telle quelle (pas d'ecrasement par le systeme).

## Donnees

- La langue auto-detected est persistee immédiatement via `saveSettings(setting)`. Elle devient ainsi le reglage manuel par defaut.
- Aucune nouvelle entite, ni nouveau champ ObjectBox, ni migration necessaire.

## Gestion des erreurs

- `loadSettings()` ne leve pas d'exception pour la detection : le fallback `en` garantit toujours une langue valide.
- `saveSettings` suit son comportement synchrone existant (`DbHelper`).
- Le BLoC et l'UI restent inchanges : aucun nouvel etat d'erreur.

## Tests

### `test/core/utils/platform_utils_test.dart` (a creer)

Verifier la detection et le mapping via `tester.platformDispatcher.locale` :
- locale `fr` → `SettingLang.fr`
- locale `ar` → `SettingLang.ar`
- locale non supportee (`de`, `zh`) → `SettingLang.en` (fallback)

### `test/features/settings/data/repositories/setting_repository_impl_test.dart` (ajouts)

Utiliser `SettingRepositoryImpl.withSystemLang` avec un `DbHelper` mocktail :
- `loadSettings()` retourne `null`, provider `fr` → `SettingEntity.lang == SettingLang.fr` et `saveSettings` appele.
- `loadSettings()` retourne `null`, provider `ar` → `SettingLang.ar`.
- `loadSettings()` retourne `null`, provider non supporte (`de`) → `SettingLang.en` (fallback).
- `loadSettings()` retourne un reglage existant (lang `es`) → langue conservee `es`, `saveSettings` non appele.

## Verification usine

- `flutter analyze` : 0 warning, 0 info.
- `flutter test` : suite globale verte.
- `flutter test test/core/utils/platform_utils_test.dart test/features/settings/data/repositories/setting_repository_impl_test.dart`

## Hors perimetre (YAGNI)

- Ne pas re-appliquer la langue systeme a chaque lancement.
- Pas d'ecran de premier lancement dedie au choix de langue.
- Pas de changement de l'injection container (le constructeur par defaut reste `SettingRepositoryImpl(this._dbHelper)`).
