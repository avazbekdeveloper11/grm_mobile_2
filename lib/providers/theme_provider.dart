import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { uzLatin, uzCyrillic }

// ─── Design Tokens ────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Primary (Blue)
  static const primary        = Color(0xFF1D6AF5);  // vivid blue
  static const primaryLight   = Color(0xFFEBF2FF);
  static const primaryDark    = Color(0xFF1554C4);

  // Accent (Sky blue)
  static const accent         = Color(0xFF38BDF8);  // sky-400
  static const accentLight    = Color(0xFFE0F7FF);

  // Surfaces — light (crisp white)
  static const surfaceLight   = Color(0xFFF6F9FF);
  static const cardLight      = Color(0xFFFFFFFF);
  static const bgLight        = Color(0xFFEEF4FF);
  static const borderLight    = Color(0xFFD6E4FF);

  // Surfaces — dark (deep navy)
  static const bgDark         = Color(0xFF0A1628);
  static const surfaceDark    = Color(0xFF0F2040);
  static const cardDark       = Color(0xFF132952);
  static const borderDark     = Color(0xFF1D3A6E);

  // Status colors
  static const statusYangi        = Color(0xFF3B82F6);
  static const statusQabul        = Color(0xFFF59E0B);
  static const statusYuvilyapti   = Color(0xFF8B5CF6);
  static const statusUpakovka     = Color(0xFFF97316);
  static const statusTayyor       = Color(0xFF10B981);
  static const statusYetkazildi   = Color(0xFF64748B);

  // Semantic
  static const success  = Color(0xFF10B981);
  static const warning  = Color(0xFFF59E0B);
  static const error    = Color(0xFFEF4444);
  static const info     = Color(0xFF3B82F6);
}

class AppSpacing {
  AppSpacing._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double x2l = 24;
  static const double x3l = 32;
  static const double x4l = 48;
}

class AppRadius {
  AppRadius._();
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double x2l = 24;
  static const BorderRadius smAll  = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll  = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll  = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll  = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius x2lAll = BorderRadius.all(Radius.circular(x2l));
}

class AppShadows {
  AppShadows._();
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x06000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 40, offset: Offset(0, 16)),
  ];
}

// ─── Theme Builders ───────────────────────────────────────────────────────────

ThemeData buildLightTheme() {
  final cs = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.cardLight,
    surfaceContainerLowest: AppColors.bgLight,
    surfaceContainerLow: AppColors.surfaceLight,
    outline: AppColors.borderLight,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: AppColors.bgLight,
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      shadowColor: Colors.transparent,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cardLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: const TextStyle(
        color: Color(0xFF0A1628),
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: AppColors.primary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.cardLight,
      indicatorColor: AppColors.primaryLight,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: const Color(0xFF94A3B8),
      indicatorColor: AppColors.primary,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: AppColors.borderLight,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: AppRadius.lgAll,
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgAll,
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgAll,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.x2lAll),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedColor: AppColors.primaryLight,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      side: const BorderSide(color: AppColors.borderLight),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderLight, space: 1),
  );
}

ThemeData buildDarkTheme() {
  final cs = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    primary: const Color(0xFF6BAEFF),   // light blue for dark mode
    secondary: AppColors.accent,
    surface: AppColors.cardDark,
    surfaceContainerLowest: AppColors.bgDark,
    surfaceContainerLow: AppColors.surfaceDark,
    outline: AppColors.borderDark,
    onSurface: const Color(0xFFE8F0FE),
    onSurfaceVariant: const Color(0xFF8BADD4),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: AppColors.bgDark,
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      shadowColor: Colors.transparent,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: const TextStyle(
        color: Color(0xFFE8F0FE),
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: Color(0xFFA78BFA)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      indicatorColor: AppColors.primaryDark,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: const Color(0xFF6BAEFF),
      unselectedLabelColor: const Color(0xFF64748B),
      indicatorColor: const Color(0xFF6BAEFF),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: AppColors.borderDark,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF6BAEFF),
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF6BAEFF),
        side: const BorderSide(color: Color(0xFFA78BFA)),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFA78BFA),
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.x2lAll),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderDark, space: 1),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class ThemeProvider extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _langKey = 'app_language';
  static const _fontKey = 'font_scale';

  ThemeMode _themeMode = ThemeMode.light;
  AppLanguage _language = AppLanguage.uzLatin;
  double _fontScale = 1.0; // 0.9 | 1.0 | 1.2 | 1.4

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  double get fontScale => _fontScale;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final tm = prefs.getString(_themeKey);
    if (tm == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (tm == 'light') {
      _themeMode = ThemeMode.light;
    }
    final lang = prefs.getString(_langKey);
    if (lang == 'cyrillic') {
      _language = AppLanguage.uzCyrillic;
    } else {
      _language = AppLanguage.uzLatin;
    }

    _fontScale = prefs.getDouble(_fontKey) ?? 1.0;

    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontKey, scale);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _langKey,
      lang == AppLanguage.uzCyrillic ? 'cyrillic' : 'latin',
    );
    notifyListeners();
  }
}
