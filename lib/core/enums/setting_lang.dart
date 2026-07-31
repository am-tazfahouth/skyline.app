enum SettingLang {
  en,
  fr,
  es,
  ar
}

// Convert a String lo lang
SettingLang getLangFromString(String lang) {
  switch (lang) {
    case 'en':
      return SettingLang.en;
    case 'fr':
      return SettingLang.fr;
    case 'es':
      return SettingLang.es;
    case 'ar':
      return SettingLang.ar;    
    default:
      return SettingLang.en;
  }
}

// Get lang name
String getNameFromLang(SettingLang lang) {
  switch (lang) {
    case SettingLang.en:
      return 'English';
    case SettingLang.fr:
      return 'Français';
    case SettingLang.es:
      return 'Spanish';
    case SettingLang.ar:
      return 'Arabic';
  }
}

// Convert a lang to String
String getStringFromLang(SettingLang lang) {
  switch (lang) {
    case SettingLang.en:
      return 'en';
    case SettingLang.fr:
      return 'fr';
    case SettingLang.es:
      return 'es';  
    case SettingLang.ar:
      return 'ar';  
  }
}