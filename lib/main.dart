import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ceramic_app/cubits/authentication/authentication_cubit.dart';
import 'package:ceramic_app/config/router/app_router.dart';
import 'package:ceramic_app/ui/app_coordinator.dart';

import 'package:ceramic_app/api/api_client.dart';
import 'package:ceramic_app/api/chat_event_service.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_badge_controller.dart';
import 'package:ceramic_app/app/app_settings_controller.dart';
import 'package:ceramic_app/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appRouter = AppRouter();
  await AppSettingsController.instance.initializeLocale();
  await ApiClient.init();
  final authenticationCubit = AuthenticationCubit();
  ApiClient.onUnauthorized = authenticationCubit.sessionExpired;
  ChatEventService.instance.onInvalidated =
      NavigationBadgeController.instance.refresh;

  runApp(
    BlocProvider(
      create: (_) => authenticationCubit,
      child: MyApp(appRouter: appRouter),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    authenticationCubit.checkAuthStatus();
  });
}

class MyApp extends StatelessWidget {
  final AppRouter appRouter;

  const MyApp({required this.appRouter, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationCubit, AuthenticationState>(
      listener: (context, state) {
        state.whenOrNull(
          authenticated: () {
            ChatEventService.instance.start();
            NavigationBadgeController.instance.refresh();
            AppSettingsController.instance.load();
          },
          unauthenticated: () {
            ChatEventService.instance.stop();
            NavigationBadgeController.instance.setCount(0);
            AppSettingsController.instance.resetForLogout();
          },
          logout: () {
            ChatEventService.instance.stop();
            NavigationBadgeController.instance.setCount(0);
            AppSettingsController.instance.resetForLogout();
          },
        );
      },
      child: AnimatedBuilder(
        animation: AppSettingsController.instance,
        builder: (context, _) => AppCoordinator(
          appRouter: appRouter,
          child: MaterialApp.router(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            routerConfig: appRouter.config(),
            locale: AppSettingsController.instance.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            themeMode: AppSettingsController.instance.themeMode,
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
          ),
        ),
      ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff7b5544),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: dark
          ? const Color(0xff121212)
          : const Color(0xfffafafa),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: dark
            ? const Color(0xff121212)
            : const Color(0xfffafafa),
        foregroundColor: scheme.onSurface,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: .55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
