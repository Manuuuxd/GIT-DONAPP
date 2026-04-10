import 'package:flutter/material.dart';

/// Paleta DonApp: rojo como primario, neutros limpios y acentos sobrios.
/// Mantiene nombres existentes para compatibilidad, pero alineados a la marca.
abstract class AppColors {
  // ===== Neutros base =====
  static const Color black = Color(0xFF000000);
  static const Color lightBlack = Colors.black54;
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);

  /// Fondo principal (app)
  static const Color background = Color(0xFFF7F7F8);
  /// Superficies (cards, sheets)
  static const Color surface = Color(0xFFFFFFFF);
  /// Neutros para bordes
  static const Color borderOutline = Color(0xFFE5E7EB);
  static const Color outlineLight = Color(0x33000000); // legacy, mantener
  static const Color outlineOnDark = Color(0x29FFFFFF);

  /// Texto
  static const Color onBackground = Color(0xFF1F1F1F);
  static const Color darkText1 = Color(0xFFFCFCFC); // sobre fondos oscuros
  static const Color rangoonGreen = Color(0xFF1B1B1B); // legacy
  static const Color paleSky = Color(0xFF6B7280); // texto atenuado
  static const Color textMuted = paleSky;

  // ===== Primario DonApp (ROJO) =====
  /// Swatch rojo alineado a DonApp
  static const MaterialColor customRed = MaterialColor(0xFFD32F2F, <int, Color>{
    50: Color(0xFFFFEBEE),
    100: Color(0xFFFFCDD2),
    200: Color(0xFFEF9A9A),
    300: Color(0xFFE57373),
    400: Color(0xFFEF5350),
    500: Color(0xFFF44336),
    600: Color(0xFFE53935),
    700: Color(0xFFD32F2F), // base
    800: Color(0xFFC62828),
    900: Color(0xFFB71C1C),
  });

  /// Alias más explícitos (por si quieres usarlos en nuevo código)
  static const Color primary = customRed;
  static const Color primaryDark = Color(0xFFB71C1C);
  /// Tinte suave para headers/llamados sin saturar
  static const Color primaryLight = Color(0xFFFFEBEE);

  // ===== Acento sobrio (AZUL frío para estados/links) =====
  /// Acento azul (contenido, iconos secundarios). Mantiene nombre existente.
  static const MaterialColor customBlue = MaterialColor(0xFF1565C0, <int, Color>{
    50: Color(0xFFE3F2FD),
    100: Color(0xFFBBDEFB),
    200: Color(0xFF90CAF9),
    300: Color(0xFF64B5F6),
    400: Color(0xFF42A5F5),
    500: Color(0xFF2196F3),
    600: Color(0xFF1E88E5),
    700: Color(0xFF1976D2),
    800: Color(0xFF1565C0), // base
    900: Color(0xFF0D47A1),
  });

  // ===== Compatibilidad (mantener nombres legacy pero con nuevos valores) =====
  static const MaterialColor grey = Colors.grey;
  static const MaterialColor green = Colors.green; // lo usamos en success abajo
  static const MaterialColor teal = Colors.teal;
  static const Color darkAqua = Color(0xFF00677F);

  // Acentos azules legacy (ajustados o mantenidos)
  static const Color blue = Color(0xFF1976D2);
  static const Color skyBlue = Color(0xFF1565C0);
  static const Color oceanBlue = Color(0xFF0D47A1);
  static const MaterialColor lightBlue = Colors.lightBlue;
  static const Color blueDress = Color(0xFF1877F2);
  static const Color crystalBlue = Color(0xFF55ACEE);

  // Grises de UI (inputs y superficies)
  static const Color surface2 = Color(0xFFF1F5F9);
  static const Color inputHover = Color(0xFFEFF1F3);
  static const Color inputFocused = Color(0xFFE3E6EA);
  static const Color inputEnabled = Color(0xFFF4F6F8);
  static const Color pastelGrey = Color(0xFFCCCCCC);
  static const Color brightGrey = Color(0xFFEAEAEA);
  static const Color gainsboro = Color(0xFFDADCE0);

  // Amarillo/rojo de sistema (mantener referencias)
  static const MaterialColor yellow = Colors.yellow;
  static const MaterialColor red = customRed;

  // Fondos oscuros y overlays (mantener)
  static const Color darkBackground = Color(0xFF0F1214);
  static const Color modalBackground = Color(0xFFF3F4F6);
  static const Color eerieBlack = Color(0xFF191C1D);

  // Enfasis/overlays legacy
  static const Color mediumEmphasisPrimary = Color(0xBDFFFFFF);
  static const Color mediumEmphasisSurface = Color(0x99000000);
  static const Color highEmphasisPrimary = Color(0xFCFFFFFF);
  static const Color highEmphasisSurface = Color(0xE6000000);
  static const Color mediumHighEmphasisPrimary = Color(0xE6FFFFFF);
  static const Color mediumHighEmphasisSurface = Color(0xB3000000);

  // Disabled
  static const Color disabledForeground = Color(0x611B1B1B);
  static const Color disabledButton = Color(0x1F000000);
  static const Color disabledSurface = Color(0xFFE0E0E0);

  // ===== Secundario (magenta frambuesa para highlights suaves) =====
  /// Mantengo tu `secondary` pero con una rampa más usable en UI
  static const MaterialColor secondary = MaterialColor(0xFF9C2B4F, <int, Color>{
    50: Color(0xFFFDE9EF),
    100: Color(0xFFF9D0DC),
    200: Color(0xFFF2A3BC),
    300: Color(0xFFE9729A),
    400: Color(0xFFDF4A7E),
    500: Color(0xFFD22C67),
    600: Color(0xFFBE255B),
    700: Color(0xFFA71D4D), // cercano a tu 600 anterior
    800: Color(0xFF90163F),
    900: Color(0xFF6A0E2C),
  });

  // ===== Estados semánticos (UX consistente) =====
  static const Color success = Color(0xFF16A34A); // green 600
  static const Color warning = Color(0xFFF59E0B); // amber 500
  static const Color error = Color(0xFFDC2626);   // red 600

  // ===== Gamificación (badges, niveles, streaks) =====
  /// Oro/Plata/Bronce para medallas
  static const Color badgeGold = Color(0xFFFFC107);
  static const Color badgeSilver = Color(0xFFB0BEC5);
  static const Color badgeBronze = Color(0xFFCD7F32);

  /// Puntos/XP, rachas y cofres
  static const Color xp = Color(0xFF7C3AED);         // púrpura vivo
  static const Color streak = Color(0xFFEF4444);     // rojo vivo (streak heat)
  static const Color quest = Color(0xFF0EA5E9);      // cyan para misiones
  static const Color reward = Color(0xFF22C55E);     // verde recompensa

  /// Tintes suaves para fondos de gamificación
  static const Color xpSoft = Color(0xFFF3E8FF);
  static const Color streakSoft = Color(0xFFFFE4E6);
  static const Color questSoft = Color(0xFFE0F2FE);
  static const Color rewardSoft = Color(0xFFECFDF5);

  // ===== Aliases/Legacy para no romper código existente =====
  /// Mantengo liver y otros por compatibilidad (no se usan en la nueva guía)
  static const Color liver = Color(0xFF4D4D4D);

  /// ⚠️ Antes NARANJO. Ahora lo redirigimos a un tinte rojo suave coherente con DonApp.
  static const Color orange = primaryLight;

  /// Swatch café legacy (lo suavizo para cards especiales si los usabas)
  static const MaterialColor customBrown = MaterialColor(0xFF8D6E63, <int, Color>{
    50: Color(0xFFEFEBE9),
    100: Color(0xFFD7CCC8),
    200: Color(0xFFBCAAA4),
    300: Color(0xFFA1887F),
    400: Color(0xFF8D6E63), // base
    500: Color(0xFF7B5E54),
    600: Color(0xFF6A5047),
    700: Color(0xFF5A433B),
    800: Color(0xFF4A362F),
    900: Color(0xFF3B2A24),
  });

  // ===== Otros (por si alguna pantalla los referenciaba) =====
  static const Color redWine = Color(0xFF9A031E);
  static const MaterialColor lightBlue1 = Colors.lightBlue;
  static const MaterialColor yellow1 = Colors.yellow;
}