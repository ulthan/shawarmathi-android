import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  final bool enablePersistence;
  ThemeModeOption _themeModeOption = ThemeModeOption.night;
  DualPaletteType _dualPalette = DualPaletteType.saffronFire;
  int _dailyGoal = 50;

  ThemeProvider({this.enablePersistence = true}) {
    if (enablePersistence) {
      _loadPreferences();
    }
  }

  ThemeModeOption get themeModeOption => _themeModeOption;
  DualPaletteType get dualPalette => _dualPalette;
  int get dailyGoal => _dailyGoal;

  ThemeMode get materialThemeMode {
    switch (_themeModeOption) {
      case ThemeModeOption.day:
        return ThemeMode.light;
      case ThemeModeOption.night:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }

  bool get isDay => _themeModeOption == ThemeModeOption.day;
  bool get isNight => _themeModeOption == ThemeModeOption.night;

  ThemeData get darkTheme => AppTheme.buildDarkTheme(_dualPalette);
  ThemeData get lightTheme => AppTheme.buildLightTheme(_dualPalette);

  void toggleDayNight() {
    if (_themeModeOption == ThemeModeOption.night) {
      setThemeMode(ThemeModeOption.day);
    } else {
      setThemeMode(ThemeModeOption.night);
    }
  }

  void setThemeMode(ThemeModeOption mode) {
    if (_themeModeOption == mode) return;
    _themeModeOption = mode;
    notifyListeners();
    if (enablePersistence) {
      _savePreferences();
    }
  }

  void setDualPalette(DualPaletteType palette) {
    if (_dualPalette == palette) return;
    _dualPalette = palette;
    notifyListeners();
    if (enablePersistence) {
      _savePreferences();
    }
  }

  void setDailyGoal(int goal) {
    if (goal < 10 || goal > 1000) return;
    _dailyGoal = goal;
    notifyListeners();
    if (enablePersistence) {
      _savePreferences();
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final db = DatabaseHelper.instance;
      final modeStr = await db.getSetting('theme_mode');
      final paletteStr = await db.getSetting('dual_palette');
      final goalStr = await db.getSetting('daily_goal');

      if (modeStr != null) {
        for (final m in ThemeModeOption.values) {
          if (m.name == modeStr) {
            _themeModeOption = m;
            break;
          }
        }
      }

      if (paletteStr != null) {
        for (final p in DualPaletteType.values) {
          if (p.name == paletteStr) {
            _dualPalette = p;
            break;
          }
        }
      }

      if (goalStr != null) {
        final g = int.tryParse(goalStr);
        if (g != null && g >= 10 && g <= 1000) {
          _dailyGoal = g;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final db = DatabaseHelper.instance;
      await db.setSetting('theme_mode', _themeModeOption.name);
      await db.setSetting('dual_palette', _dualPalette.name);
      await db.setSetting('daily_goal', _dailyGoal.toString());
    } catch (e) {
      debugPrint('Error saving theme preferences: $e');
    }
  }
}
