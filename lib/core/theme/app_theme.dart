import 'package:flutter/material.dart';

class AppTheme {

  static Color getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Colors.orange;
      case 'water':
        return Colors.blue;
      case 'grass':
        return Colors.green;
      case 'electric':
        return Colors.yellow;
      case 'psychic':
        return Colors.purple;
      case 'ice':
        return Colors.cyan;
      case 'dragon':
        return Colors.indigo;
      case 'dark':
        return Colors.brown;
      case 'fairy':
        return Colors.pink;
      case 'normal':
        return Colors.grey;
      case 'fighting':
        return Colors.red;
      case 'flying':
        return Colors.lightBlue;
      case 'poison':
        return Colors.deepPurple;
      case 'ground':
        return Colors.brown.shade300;
      case 'rock':
        return Colors.brown.shade700;
      case 'bug':
        return Colors.lightGreen;
      case 'ghost':
        return Colors.deepPurple.shade900;
      case 'steel':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: Color(0xFFFFD56F),
        primaryContainer: Color(0xFFFFF3B0),
        secondary: Color(0xFFFFB74D),
        secondaryContainer: Color(0xFFFFE0B2),
        surface: Colors.white,
        background: Color(0xFFFFFBF0),
        error: Colors.red.shade700,
        onPrimary: Colors.black87,
        onSecondary: Colors.black87,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
        onError: Colors.white,
        outline: Color(0xFFE0A040),
      ),
      scaffoldBackgroundColor: Color(0xFFFFFBF0),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFFFFD56F),
        foregroundColor: Colors.black87,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFFB74D),
          foregroundColor: Colors.black87,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFFE0A040),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFFFD56F), width: 2),
        ),
      ),
      iconTheme: IconThemeData(color: Color(0xFFE0A040)),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: Color(0xFFFFB74D),
        primaryContainer: Color(0xFF8B6914),
        secondary: Color(0xFFFFD56F),
        secondaryContainer: Color(0xFFA68945),
        surface: Color(0xFF1E1E1E),
        background: Color(0xFF121212),
        error: Colors.red.shade400,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.black,
        outline: Color(0xFFB8860B),
      ),
      scaffoldBackgroundColor: Color(0xFF121212),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Color(0xFF1E1E1E),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFFB74D),
          foregroundColor: Colors.black,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFFFFD56F),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF3C3C3C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFFFB74D), width: 2),
        ),
      ),
      iconTheme: IconThemeData(color: Color(0xFFFFD56F)),
    );
  }

  static LinearGradient cardGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? [Color(0xFF3D3520), Color(0xFF5C4E2A)]
          : [Color(0xFFFFF3B0), Color(0xFFFFD56F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient cardBackGradient(BuildContext context) {
    final theme = Theme.of(context);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        theme.colorScheme.surfaceVariant.withOpacity(0.3),
        theme.colorScheme.surface,
      ],
    );
  }

  static LinearGradient buttonGradient(BuildContext context) {
    final theme = Theme.of(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.colorScheme.primary,
        theme.colorScheme.primaryContainer,
      ],
    );
  }

  static Color cardBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Color(0xFFB8860B) : Color(0xFFE0A040);
  }

  static Color getRarityColor(String rarity, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (rarity.toLowerCase()) {
      case 'legendary':
        return isDark ? Color(0xFFB388FF) : Colors.purple;
      case 'rare':
        return isDark ? Color(0xFF82B1FF) : Colors.blue;
      case 'uncommon':
        return isDark ? Color(0xFF69F0AE) : Colors.green;
      case 'common':
      default:
        return isDark ? Color(0xFFBDBDBD) : Colors.grey;
    }
  }
}
