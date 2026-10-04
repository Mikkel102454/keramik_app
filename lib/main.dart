import 'dart:async';
import 'package:ceramic_app/ui/pages/notification/notification_controller_page.dart';
import 'package:ceramic_app/app/chat_media_controller.dart';
import 'package:ceramic_app/app/push_controller.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/ui/pages/notification/conversation_page.dart';
import 'package:ceramic_app/ui/pages/notification/friend_requests_page.dart';
import 'package:flutter/material.dart';
import 'package:ceramic_app/ui/theme/studio_theme.dart';
import 'package:ceramic_app/app/entitlement_controller.dart';
import 'package:ceramic_app/ui/widgets/feature_gate.dart';
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
  await ChatMediaDownload.clear();
  await PushController.instance.initialize();
  PushController.instance.onTap = (destination) async {
    unawaited(appRouter.replace(const NotificationRoute()));
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
