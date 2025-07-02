import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier with ChangeNotifier {
  static const String _themePrefKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    loadThemeFromPrefs();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeToPrefs();
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefKey, _themeMode == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themePrefKey);
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  // --- Common Colors derived directly from the image ---
  // Light Mode Colors
  static const Color _lightBgColor = Color(0xFFF0F2F5); // Overall scaffold background
  static const Color _lightSurfaceColor = Colors.white; // Card backgrounds, App Bar
  static const Color _lightPrimaryTextColor = Color(0xFF212529); // Main dark text
  static const Color _lightSecondaryTextColor = Color(0xFF6C757D); // Labels, subtitles
  static const Color _lightAccentGreen = Color(0xFF4CAF50); // Positive indicator green
  static const Color _lightAccentRed = Color(0xFFEF5350); // Negative indicator red
  static const Color _lightBorderColor = Color(0xFFDEE2E6); // Divider/outline color
  static const Color _lightInputFillColor = Color(0xFFF8F9FA); // Input field background

  // Dark Mode Colors (complementary to the light theme, no blue)
  static const Color _darkBgColor = Color(0xFF1A1A1A); // Overall scaffold background
  static const Color _darkSurfaceColor = Color(0xFF2C2C2C); // Card backgrounds, App Bar
  static const Color _darkPrimaryTextColor = Color(0xFFE9ECEF); // Main light text
  static const Color _darkSecondaryTextColor = Color(0xFFADB5BD); // Labels, subtitles
  static const Color _darkAccentGreen = Color(0xFF81C784); // Lighter green for dark contrast
  static const Color _darkAccentRed = Color(0xFFEF9A9A); // Lighter red for dark contrast
  static const Color _darkBorderColor = Color(0xFF495057); // Divider/outline color
  static const Color _darkInputFillColor = Color(0xFF3A3A3A); // Input field background


  // Updated color scheme to match screenshot exactly
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBgColor,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.light(
      primary: _lightAccentGreen,       // Green for primary accent (from chart/positive)
      onPrimary: Colors.white,          // Text on primary green
      primaryContainer: _lightInputFillColor, // A neutral light grey for containers like switches background
      onPrimaryContainer: _lightPrimaryTextColor, // Dark text on primaryContainer
      secondary: _lightAccentRed,       // Red for secondary accent (negative)
      onSecondary: Colors.white,
      secondaryContainer: _lightBgColor, // Another general light grey container
      onSecondaryContainer: _lightPrimaryTextColor,
      surface: _lightSurfaceColor,      // White background for cards, AppBar
      onSurface: _lightPrimaryTextColor, // Dark text on white surfaces
      surfaceContainerHighest: _lightInputFillColor, // For input fields and similar components
      onSurfaceVariant: _lightSecondaryTextColor, // Secondary text on surfaces
      outline: _lightBorderColor,       // Borders, dividers
      shadow: const Color(0x0A000000),  // Very subtle shadow
      background: _lightBgColor,        // Scaffold background
      onBackground: _lightPrimaryTextColor, // Text on background
      error: _lightAccentRed, // Explicit error color
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme().apply(
      displayColor: _lightPrimaryTextColor, // Dark text for display styles
      bodyColor: _lightSecondaryTextColor, // Lighter dark text for body styles
    ),
    cardTheme: CardThemeData(
      color: _lightSurfaceColor,
      elevation: 0.8,
      shadowColor: const Color(0x0A000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _lightSurfaceColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: _lightPrimaryTextColor),
      titleTextStyle: GoogleFonts.inter(
        color: _lightPrimaryTextColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightInputFillColor,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.inter(color: _lightSecondaryTextColor),
      hintStyle: GoogleFonts.inter(color: _lightSecondaryTextColor.withOpacity(0.5)),
      floatingLabelBehavior: FloatingLabelBehavior.never,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return _lightAccentGreen;
        }
        return _lightSecondaryTextColor.withOpacity(0.5); // Match inactive grey
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return _lightAccentGreen.withOpacity(0.5);
        }
        return _lightSecondaryTextColor.withOpacity(0.2); // Lighter track for inactive
      }),
    ),
    dividerTheme: const DividerThemeData(
      color: _lightBorderColor,
      thickness: 0.5,
      space: 1,
    ),
    useMaterial3: true,
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _darkBgColor,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.dark(
      primary: _darkAccentGreen,       // Green for primary accent
      onPrimary: Colors.black,
      primaryContainer: _darkInputFillColor, // A neutral dark grey
      onPrimaryContainer: _darkPrimaryTextColor,
      secondary: _darkAccentRed,       // Red for secondary accent
      onSecondary: Colors.black,
      secondaryContainer: _darkBgColor, // Another general dark grey container
      onSecondaryContainer: _darkPrimaryTextColor,
      surface: _darkSurfaceColor,      // Dark background for cards, AppBar
      onSurface: _darkPrimaryTextColor, // Light text on dark surfaces
      surfaceContainerHighest: _darkInputFillColor, // For input fields
      onSurfaceVariant: _darkSecondaryTextColor, // Secondary text on surfaces
      outline: _darkBorderColor,       // Borders, dividers
      shadow: const Color(0x0A000000), // Subtle shadow
      background: _darkBgColor,        // Scaffold background
      onBackground: _darkPrimaryTextColor, // Text on background
      error: _darkAccentRed, // Explicit error color
      onError: Colors.black,
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme.apply(
        bodyColor: _darkPrimaryTextColor,
        displayColor: _darkPrimaryTextColor,
      ),
    ),
    cardTheme: CardThemeData(
      color: _darkSurfaceColor,
      elevation: 0.8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _darkSurfaceColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: _darkPrimaryTextColor),
      titleTextStyle: GoogleFonts.inter(
        color: _darkPrimaryTextColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkInputFillColor,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.inter(color: _darkSecondaryTextColor),
      hintStyle: GoogleFonts.inter(color: _darkSecondaryTextColor.withOpacity(0.5)),
      floatingLabelBehavior: FloatingLabelBehavior.never,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return _darkAccentGreen;
        }
        return _darkSecondaryTextColor.withOpacity(0.5);
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return _darkAccentGreen.withOpacity(0.5);
        }
        return _darkSecondaryTextColor.withOpacity(0.2);
      }),
    ),
    dividerTheme: const DividerThemeData(
      color: _darkBorderColor,
      thickness: 0.5,
      space: 1,
    ),
    useMaterial3: true,
  );
}