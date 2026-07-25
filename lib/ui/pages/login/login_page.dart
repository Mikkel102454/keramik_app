import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/ui/widgets/v2/text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ceramic_app/cubits/authentication/authentication_cubit.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthenticationCubit, AuthenticationState>(
          listener: (context, state) {
            state.whenOrNull(
              error: (message) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              },
            );
          },
          builder: (context, state) {
            final isLoading = state.maybeWhen(
              loading: () => true,
              orElse: () => false,
            );
            final authentication = context.read<AuthenticationCubit>();

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),

                      Text(
                        context.l10n.welcomeBack,
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        context.l10n.signInToAccount,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      TextFieldWidget(
                        placeholder: context.l10n.emailOrUsername,
                        keyboardType: TextInputType.text,
                        maxLines: 1,
                        onChanged: (value) async {
                          context.read<AuthenticationCubit>().identifierChanged(
                            value,
                          );
                          return true;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFieldWidget(
                        placeholder: context.l10n.password,
                        obscureText: true,
                        maxLines: 1,
                        onChanged: (value) async {
                          context.read<AuthenticationCubit>().passwordChanged(
                            value,
                          );
                          return true;
                        },
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {},
                          child: Text(
                            context.l10n.forgotPassword,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  context.read<AuthenticationCubit>().login();
                                },
                          child: isLoading
                              ? const CircularProgressIndicator()
                              : Text(context.l10n.logIn),
                        ),
                      ),

                      const SizedBox(height: 24),

                      if (authentication.deletionPending) ...[
                        Card(
                          color: theme.colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  context.l10n.accountDeletionPending,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.l10n
                                      .accountDeletionPendingExplanation,
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: isLoading
                                      ? null
                                      : authentication.cancelDeletion,
                                  child: Text(context.l10n.cancelDeletion),
                                ),
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : authentication.signOutPendingDeletion,
                                  child: Text(context.l10n.signOut),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(context.l10n.or),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(context.l10n.noAccountQuestion),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              context.l10n.signUp,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
