import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ceramic_app/config/router/app_router.dart';
import 'package:ceramic_app/cubits/authentication/authentication_cubit.dart';

class AppCoordinator extends StatelessWidget {
  final AppRouter appRouter;
  final Widget child;

  const AppCoordinator({
    required this.appRouter,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationCubit, AuthenticationState>(
      listener: (context, state) {
        state.maybeWhen(
          authenticated: () {
            appRouter.replace(const HomeRoute());
          },
          unauthenticated: () {
            appRouter.replace(const LoginRoute());
          },
          orElse: () {},
        );
      },
      child: child,
    );
  }
}