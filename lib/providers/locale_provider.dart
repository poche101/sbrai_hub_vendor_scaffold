import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_strings.dart';

class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'sbrai_language';
  AppLanguage _language = AppLanguage.english;

  AppLanguage get language => _language;
  String t(String key) => AppStrings.t(key, _language);
  String category(String name) => AppStrings.translateCategory(name, _language);

  LocaleProvider() {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null) {
      _language = AppLanguage.values.firstWhere(
        (l) => l.code == code,
        orElse: () => AppLanguage.english,
      );
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.code);
  }
}
