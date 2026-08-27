import 'package:flutter/material.dart';

/// Cores semânticas do design Trackrios, resolvidas por tema.
///
/// As telas leem daqui em vez de constantes fixas, senão o modo escuro herdaria
/// os tons claros e ficaria ilegível. Use `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.label,
    required this.border,
    required this.borderCard,
    required this.loginBackdrop,
    required this.fieldFill,
    required this.muted,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color label;
  final Color border;
  final Color borderCard;
  final Color muted;

  /// Fundo da area superior do login; o cartao inferior usa [surface].
  final Color loginBackdrop;

  /// Preenchimento dos campos do login, sem borda visivel.
  final Color fieldFill;

  /// Convertida do OKLCH do design original.
  static const AppPalette light = AppPalette(
    primary: Color(0xFF005ABA),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDCEDFF),
    onPrimaryContainer: Color(0xFF004495),
    background: Color(0xFFF2F5F9),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF192029),
    textSecondary: Color(0xFF5E646C),
    label: Color(0xFF414853),
    border: Color(0xFFD3D8DE),
    borderCard: Color(0xFFDDE2E8),
    muted: Color(0xFF8B9095),
    loginBackdrop: Color(0xFFEAF3FE),
    fieldFill: Color(0xFFE1ECFC),
  );

  /// Mesmo matiz da marca, com luminosidade invertida. O azul clareia porque
  /// o #005ABA não tem contraste suficiente sobre fundo escuro.
  static const AppPalette dark = AppPalette(
    primary: Color(0xFF5CA0F6),
    onPrimary: Color(0xFF06213D),
    primaryContainer: Color(0xFF1B3E69),
    onPrimaryContainer: Color(0xFFB7D4F9),
    background: Color(0xFF12161B),
    surface: Color(0xFF1D2228),
    textPrimary: Color(0xFFE4E8ED),
    textSecondary: Color(0xFFA0A5AC),
    label: Color(0xFFBFC5CC),
    border: Color(0xFF383E45),
    borderCard: Color(0xFF383E45),
    muted: Color(0xFF81878D),
    loginBackdrop: Color(0xFF0C1015),
    fieldFill: Color(0xFF262C33),
  );

  @override
  AppPalette copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? label,
    Color? border,
    Color? borderCard,
    Color? loginBackdrop,
    Color? fieldFill,
    Color? muted,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      label: label ?? this.label,
      border: border ?? this.border,
      borderCard: borderCard ?? this.borderCard,
      muted: muted ?? this.muted,
      loginBackdrop: loginBackdrop ?? this.loginBackdrop,
      fieldFill: fieldFill ?? this.fieldFill,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer: Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      label: Color.lerp(label, other.label, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderCard: Color.lerp(borderCard, other.borderCard, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      loginBackdrop: Color.lerp(loginBackdrop, other.loginBackdrop, t)!,
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

class AppTheme {
  AppTheme._();

  static const double cardRadius = 16;
  static const double fieldRadius = 12;
  static const double buttonRadius = 10;

  /// Rótulo de seção dos cards: maiúsculas, espaçado, na cor da marca.
  static TextStyle sectionLabel(BuildContext context) => TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: context.palette.primary,
      );

  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
    ).copyWith(
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      primaryContainer: palette.primaryContainer,
      onPrimaryContainer: palette.onPrimaryContainer,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      outlineVariant: palette.borderCard,
    );

    return ThemeData(
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
        iconTheme: IconThemeData(color: palette.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      ),
      dialogTheme: DialogThemeData(backgroundColor: palette.surface),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        isDense: true,
        hintStyle: TextStyle(color: palette.muted, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(color: palette.primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldRadius)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: TextStyle(fontSize: 16, color: palette.textPrimary),
        subtitleTextStyle: TextStyle(fontSize: 14, color: palette.textSecondary),
      ),
    );
  }
}
