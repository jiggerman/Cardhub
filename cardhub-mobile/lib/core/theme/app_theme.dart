import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Manrope',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.violet,
        onPrimary: Colors.white,
        secondary: AppColors.coral,
        surface: AppColors.panel,
        onSurface: AppColors.ink,
        error: AppColors.danger,
        outline: AppColors.lineStrong,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.violetStrong,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.panelSoft,
          disabledForegroundColor: AppColors.mutedSoft,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.panel,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.line),
          textStyle: const TextStyle(fontFamily: 'Manrope', fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.violet,
          textStyle: const TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.panel,
        hintStyle: const TextStyle(color: AppColors.mutedSoft),
        labelStyle: const TextStyle(color: AppColors.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _fieldBorder(AppColors.line),
        enabledBorder: _fieldBorder(AppColors.line),
        focusedBorder: _fieldBorder(AppColors.violet),
        errorBorder: _fieldBorder(AppColors.danger),
        focusedErrorBorder: _fieldBorder(AppColors.danger),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgRaised,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.violetStrong.withValues(alpha: 0.18),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? AppColors.violet : AppColors.mutedSoft,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected) ? AppColors.ink : AppColors.mutedSoft,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.panelSoft,
        selectedColor: AppColors.violetStrong,
        side: const BorderSide(color: AppColors.line),
        labelStyle: const TextStyle(fontFamily: 'Manrope', fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.panelSoft,
        contentTextStyle: const TextStyle(fontFamily: 'Manrope', color: AppColors.ink),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgRaised,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.violet),
    );
  }

  static TextTheme _textTheme(TextTheme base) => base
      .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink, fontFamily: 'Manrope')
      .copyWith(
        headlineLarge: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.9),
        headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6),
        titleLarge: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.45),
        bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.45, color: AppColors.muted),
        labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        labelSmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
          color: AppColors.violet,
        ),
      );

  static OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide(color: color),
      );
}
