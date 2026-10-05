import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clay_dock/ui/widgets/v2/form_field_style.dart';

/// Monochrome surfaces and a restrained social accent, shared by every route.
abstract final class StudioTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors =
        ColorScheme.fromSeed(
          seedColor: const Color(0xff2457d6),
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xff8aaeff) : const Color(0xff2457d6),
          onPrimary: dark ? const Color(0xff071b43) : const Color(0xffffffff),
          primaryContainer: dark
              ? const Color(0xff142348)
              : const Color(0xffeaf0ff),
          onPrimaryContainer: dark
              ? const Color(0xffd7e3ff)
              : const Color(0xff143a88),
          secondary: dark ? const Color(0xffeeeeee) : const Color(0xff161823),
          onSecondary: dark ? const Color(0xff161823) : const Color(0xffffffff),
          secondaryContainer: dark
              ? const Color(0xff292a2e)
              : const Color(0xfff1f1f2),
          onSecondaryContainer: dark
              ? const Color(0xffeeeeee)
              : const Color(0xff161823),
          tertiary: dark ? const Color(0xfff2c36b) : const Color(0xff8b5a00),
          onTertiary: dark ? const Color(0xff352300) : const Color(0xffffffff),
          tertiaryContainer: dark
              ? const Color(0xff3b2c12)
              : const Color(0xfffff0ce),
          onTertiaryContainer: dark
              ? const Color(0xffffdfa6)
              : const Color(0xff624000),
          surface: dark ? const Color(0xff0c0c0e) : const Color(0xffffffff),
          onSurface: dark ? const Color(0xfffafafa) : const Color(0xff161823),
          onSurfaceVariant: dark
              ? const Color(0xffb4b4ba)
              : const Color(0xff60616a),
          surfaceContainerLowest: dark
              ? const Color(0xff101012)
              : const Color(0xffffffff),
          surfaceContainerLow: dark
              ? const Color(0xff18181b)
              : const Color(0xfff5f5f5),
          surfaceContainer: dark
              ? const Color(0xff202024)
              : const Color(0xfff1f1f2),
          surfaceContainerHigh: dark
              ? const Color(0xff29292e)
              : const Color(0xffe9e9ec),
          surfaceContainerHighest: dark
              ? const Color(0xff333339)
              : const Color(0xffdfdfe3),
          outline: dark ? const Color(0xff888891) : const Color(0xff8b8b94),
          outlineVariant: dark
              ? const Color(0xff303036)
              : const Color(0xffe7e7e9),
        );
    final base = ThemeData(useMaterial3: true, colorScheme: colors);
    final text = base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        letterSpacing: -0.4,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.3),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.3),
      labelSmall: base.textTheme.labelSmall?.copyWith(fontSize: 10),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
    );
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        titleTextStyle: text.titleLarge?.copyWith(color: colors.onSurface),
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerLowest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: FormFieldStyle.theme(colors),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: colors.onPrimary,
          backgroundColor: colors.primary,
          minimumSize: const Size(48, 48),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: buttonPadding,
          shape: buttonShape,
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 1,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: colors.surfaceContainerLowest,
        selectedColor: colors.secondaryContainer,
        labelStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        modalBackgroundColor: colors.surfaceContainerLowest,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: colors.onSurfaceVariant,
        titleTextStyle: text.titleMedium?.copyWith(color: colors.onSurface),
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        shape: const RoundedRectangleBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 16,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.primaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.secondaryContainer,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.onSurface,
        unselectedLabelColor: colors.onSurfaceVariant,
        labelStyle: text.titleMedium,
        unselectedLabelStyle: text.titleMedium,
        indicatorColor: colors.onSurface,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: colors.outlineVariant,
      ),
      tooltipTheme: const TooltipThemeData(preferBelow: false),
    );
  }
}
