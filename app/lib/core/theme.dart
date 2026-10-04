import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Polices embarquées (SIL Open Font License) : Oswald pour les titres,
/// Barlow pour le texte et les chiffres.
const kDisplayFont = 'Oswald';
const kBodyFont = 'Barlow';

/// Palette originale (aucune couleur ni logo de marque officielle).
/// Neutres d'une seule famille, légèrement chauds, et un seul accent : l'or.
/// Le rouge est réservé aux signaux (nouvelle carte, erreur).
class AppColors {
  static const background = Color(0xFF0E0D0B);
  static const surface = Color(0xFF181614);
  static const surfaceHigh = Color(0xFF221F1B);
  static const outline = Color(0xFF35312B);
  static const gold = Color(0xFFE2B04F);
  static const goldDeep = Color(0xFF9C7224);
  static const crimson = Color(0xFFD03A48);
  static const steel = Color(0xFFA29D93);
  static const text = Color(0xFFF3F0EA);
  static const textMuted = Color(0xFFA7A196);
  static const success = Color(0xFF4DB77F);
  static const warning = Color(0xFFE0A243);

  /// Couleur associée à chaque niveau de rareté (lueurs, badges).
  static const rarity = {
    'commune': Color(0xFFB9B5AD),
    'peu_commune': Color(0xFF7FB3D5),
    'rare': Color(0xFF4F8DFF),
    'epique': Color(0xFFB45CFF),
    'legendaire': Color(0xFFE2B04F),
    'mythique': Color(0xFFFF4D6D),
  };
}

/// Durées et courbes communes des animations d'interface.
class Motion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 520);
  static const curve = Curves.easeOutCubic;
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.gold, brightness: Brightness.dark).copyWith(
    primary: AppColors.gold,
    onPrimary: const Color(0xFF1A1206),
    secondary: AppColors.crimson,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textMuted,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surfaceHigh,
    surfaceContainerHighest: const Color(0xFF2A2621),
    error: AppColors.crimson,
    outline: AppColors.outline,
    outlineVariant: const Color(0xFF2A2621),
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    brightness: Brightness.dark,
    fontFamily: kBodyFont,
    splashFactory: InkSparkle.splashFactory,
  );

  final text = base.textTheme
      .copyWith(
        displayLarge: const TextStyle(fontFamily: kDisplayFont, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displayMedium: const TextStyle(fontFamily: kDisplayFont, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displaySmall: const TextStyle(fontFamily: kDisplayFont, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        headlineLarge: const TextStyle(fontFamily: kDisplayFont, fontWeight: FontWeight.w700, letterSpacing: -0.2),
        headlineMedium: const TextStyle(fontFamily: kDisplayFont, fontWeight: FontWeight.w600),
        headlineSmall: const TextStyle(fontFamily: kDisplayFont, fontWeight: FontWeight.w600),
        titleLarge: const TextStyle(fontFamily: kDisplayFont, fontWeight: FontWeight.w600, letterSpacing: 0.4),
        titleMedium: const TextStyle(fontWeight: FontWeight.w600),
        titleSmall: const TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(height: 1.4),
        bodyMedium: const TextStyle(height: 1.4),
        labelLarge: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
      )
      .apply(bodyColor: AppColors.text, displayColor: AppColors.text, fontFamily: kBodyFont)
      .copyWith(
        // Titres en Oswald (apply() a remis Barlow partout)
        displayLarge: const TextStyle(fontFamily: kDisplayFont, fontWeight: FontWeight.w700, color: AppColors.text),
        displayMedium: const TextStyle(fontFamily: kDisplayFont, fontWeight: FontWeight.w700, color: AppColors.text),
        displaySmall: const TextStyle(fontFamily: kDisplayFont, fontWeight: FontWeight.w700, color: AppColors.text),
        headlineLarge: const TextStyle(fontFamily: kDisplayFont, fontWeight: FontWeight.w700, color: AppColors.text),
        headlineMedium: const TextStyle(fontFamily: kDisplayFont, fontWeight: FontWeight.w600, color: AppColors.text),
        headlineSmall: const TextStyle(fontFamily: kDisplayFont, fontWeight: FontWeight.w600, color: AppColors.text),
        titleLarge: const TextStyle(
          fontFamily: kDisplayFont,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: AppColors.text,
          fontSize: 22,
        ),
      );

  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  const buttonText = TextStyle(fontFamily: kBodyFont, fontWeight: FontWeight.w700, fontSize: 15.5, letterSpacing: 0.4);

  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      // Transparent sur les fonds animés ; opaque quand le contenu défile dessous
      backgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.scrolledUnder)
            ? AppColors.background.withValues(alpha: 0.94)
            : Colors.transparent,
      ),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: const TextStyle(
        fontFamily: kDisplayFont,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.text,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface.withValues(alpha: 0.86),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: const Color(0xFF1A1206),
        disabledBackgroundColor: AppColors.surfaceHigh,
        textStyle: buttonText,
        shape: buttonShape,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ).copyWith(overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.12))),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        textStyle: buttonText,
        shape: buttonShape,
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.45)),
        backgroundColor: AppColors.background.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.gold,
        textStyle: const TextStyle(fontFamily: kBodyFont, fontWeight: FontWeight.w600, fontSize: 14.5),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: AppColors.text)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh.withValues(alpha: 0.85),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
      ),
      labelStyle: const TextStyle(color: AppColors.textMuted),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.background.withValues(alpha: 0.9),
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.gold.withValues(alpha: 0.16),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Icônes seules (le nom reste lu par l'accessibilité et en info-bulle)
      height: 62,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.gold : AppColors.textMuted, size: 24),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: kBodyFont,
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? AppColors.text : AppColors.textMuted,
          letterSpacing: 0.2,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surfaceHigh.withValues(alpha: 0.8),
      selectedColor: AppColors.gold.withValues(alpha: 0.2),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(fontFamily: kBodyFont, fontWeight: FontWeight.w600, color: AppColors.text),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: AppColors.outline,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: const TextStyle(
        fontFamily: kDisplayFont,
        fontSize: 21,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: const TextStyle(fontFamily: kBodyFont, color: AppColors.text, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    listTileTheme: const ListTileThemeData(iconColor: AppColors.gold),
    dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.06), space: 1),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.gold : AppColors.steel,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.gold.withValues(alpha: 0.35) : AppColors.surfaceHigh,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.gold),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
