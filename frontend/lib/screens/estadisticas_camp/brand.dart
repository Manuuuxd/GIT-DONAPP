import 'package:flutter/material.dart';

class DonAppBrand {
  // ⬇️ Reemplaza estos HEX por los oficiales de DonApp
  static const primary = Color(0xffde4f4f); // Rojo DonApp (ejemplo)
  static const secondary = Color(0xff507bdb); // Teal (ejemplo)
  static const tertiary = Color(0xff2884a8); // Azul petróleo (ejemplo)
  static const background = Color(0xFFFFFCF7); // Marfil claro (ejemplo)

  static ColorScheme scheme(Brightness b) =>
      ColorScheme.fromSeed(seedColor: primary, brightness: b);

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: scheme(Brightness.light),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(centerTitle: false),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    visualDensity: VisualDensity.standard,
  );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: scheme(Brightness.dark),
      );
}
