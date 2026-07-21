import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ceramic_app/cubits/authentication/authentication_cubit.dart';
import 'package:ceramic_app/config/router/app_router.dart';
import 'package:ceramic_app/ui/app_coordinator.dart';

import 'package:ceramic_app/api/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appRouter = AppRouter();
  await ApiClient.init();
  final authenticationCubit = AuthenticationCubit();
  ApiClient.onUnauthorized = authenticationCubit.sessionExpired;

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
    return AppCoordinator(
      appRouter: appRouter,
      child: MaterialApp.router(
        title: "Keramik App",

        routerConfig: appRouter.config(),
      ),
    );
  }
}
