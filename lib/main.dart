import 'dart:async';
import 'package:clay_dock/app/client_version_controller.dart';
import 'package:clay_dock/ui/widgets/client_version_gate.dart';
import 'package:clay_dock/ui/pages/notification/notification_controller_page.dart';
import 'package:clay_dock/app/chat_media_controller.dart';
import 'package:clay_dock/app/push_controller.dart';
import 'package:clay_dock/repositories/chat_repository.dart';
import 'package:clay_dock/ui/pages/notification/conversation_page.dart';
import 'package:clay_dock/ui/pages/notification/friend_requests_page.dart';
import 'package:flutter/material.dart';
import 'package:clay_dock/ui/theme/studio_theme.dart';
import 'package:clay_dock/app/entitlement_controller.dart';
import 'package:clay_dock/ui/widgets/feature_gate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clay_dock/cubits/authentication/authentication_cubit.dart';
import 'package:clay_dock/config/router/app_router.dart';
import 'package:clay_dock/ui/app_coordinator.dart';

import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/api/chat_event_service.dart';
import 'package:clay_dock/ui/widgets/v2/navigation_badge_controller.dart';
import 'package:clay_dock/app/app_settings_controller.dart';
import 'package:clay_dock/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appRouter = AppRouter();
  await AppSettingsController.instance.initializeLocale();
  await ApiClient.init();
  await ChatMediaDownload.clear();
  await PushController.instance.initialize();
  PushController.instance.onTap = (destination) async {
    unawaited(appRouter.replace(NotificationRoute()));
    await WidgetsBinding.instance.endOfFrame;
    final context = appRouter.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    if (destination['destination'] == 'FRIEND_REQUESTS') {
      final controller = NotificationControllerPage();
      try {
        await controller.load();
        if (context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FriendRequestsPage(controller: controller),
            ),
          );
        }
      } finally {
        controller.dispose();
      }
    } else if (destination['destination'] == 'CONVERSATION') {
      try {
        final conversation = await ChatRepository.getConversation(
          destination['conversationId'] as String,
        );
        if (context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ConversationPage(initialConversation: conversation),
            ),
          );
        }
      } catch (_) {
        /* Chats remains the safe fallback. */
      }
    }
  };
  final authenticationCubit = AuthenticationCubit();
  final versions = ClientVersionController(
    dio: ApiClient.dio,
    versionCode: InstalledClient.versionCode ?? 0,
  );
  ApiClient.onVersionRejected = (outdated) =>
      versions.requireVerification(outdated: outdated);
  versions.start();
  ApiClient.onUnauthorized = authenticationCubit.sessionExpired;
  ApiClient.onSubscriptionError = (error) {
    EntitlementController.instance.refresh();
    final context = appRouter.navigatorKey.currentContext;
    if (context != null && context.mounted) {
      showFeatureLock(
        context,
        error['featureKey'] as String? ?? '',
        limit: (error['limit'] as num?)?.toInt(),
        currentUsage: (error['currentUsage'] as num?)?.toInt(),
        offerMaker: error['requiredPlan'] == 'Maker',
      );
    }
  };
  ChatEventService.instance.onInvalidated =
      NavigationBadgeController.instance.refresh;

  runApp(
    BlocProvider(
      create: (_) => authenticationCubit,
      child: MyApp(appRouter: appRouter, versions: versions),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    authenticationCubit.checkAuthStatus();
  });
}

class MyApp extends StatelessWidget {
  final AppRouter appRouter;
  final ClientVersionController? versions;

  const MyApp({required this.appRouter, this.versions, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationCubit, AuthenticationState>(
      listener: (context, state) {
        state.whenOrNull(
          authenticated: () {
            EntitlementController.instance.start();
            ChatEventService.instance.start();
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => PushController.instance.start(),
            );
            NavigationBadgeController.instance.refresh();
            AppSettingsController.instance.load();
          },
          unauthenticated: () {
            EntitlementController.instance.reset();
            ChatEventService.instance.stop();
            PushController.instance.stop();
            ChatMediaDownload.clear();
            NavigationBadgeController.instance.setCount(0);
            AppSettingsController.instance.resetForLogout();
          },
          logout: () {
            EntitlementController.instance.reset();
            ChatEventService.instance.stop();
            PushController.instance.stop();
            ChatMediaDownload.clear();
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
            builder: (context, child) => versions == null
                ? child!
                : ClientVersionGate(controller: versions!, child: child!),
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            routerConfig: appRouter.config(),
            locale: AppSettingsController.instance.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            themeMode: AppSettingsController.instance.themeMode,
            theme: StudioTheme.light(),
            darkTheme: StudioTheme.dark(),
          ),
        ),
      ),
    );
  }
}
