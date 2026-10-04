import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/ui/widgets/v2/text_field_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/studio_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ceramic_app/cubits/authentication/authentication_cubit.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/config/constants/app_constants.dart';
import 'package:ceramic_app/utils/web.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _openingWebsite = false;

  Future<void> _openAccountPage(String Function() url) async {
    if (_openingWebsite) return;
    setState(() => _openingWebsite = true);
    try {
      await openWebPage(url());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.accountWebsiteOpenFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _openingWebsite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthenticationCubit, AuthenticationState>(
          listener: (context, state) {
            state.whenOrNull(
              error: (message) {
                final authentication = context.read<AuthenticationCubit>();
                final retry = authentication.loginRetryAfterSeconds;
                final feedback =
                    message == AuthenticationCubit.loginThrottledMessage
                    ? retry == null
                          ? context.l10n.loginThrottled
                          : context.l10n.loginThrottledRetry(retry)
                    : message == AuthenticationCubit.requestTimedOutMessage
                    ? context.l10n.requestTimedOut
                    : message == 'Network error'
                    ? context.l10n.networkUnavailable
                    : authentication.deletionPending
                    ? context.l10n.operationFailed
                    : message;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(feedback)));
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: StudioBrandMark(size: 56)),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.appTitle,
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            context.l10n.welcomeBack,
                            style: theme.textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            context.l10n.signInToAccount,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 20),

                          TextFieldWidget(
                            placeholder: context.l10n.emailOrUsername,
                            keyboardType: TextInputType.text,
                            maxLines: 1,
                            onChanged: (value) async {
                              context
                                  .read<AuthenticationCubit>()
                                  .identifierChanged(value);
                              return true;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFieldWidget(
                            placeholder: context.l10n.password,
                            obscureText: true,
                            maxLines: 1,
                            onChanged: (value) async {
                              context
                                  .read<AuthenticationCubit>()
                                  .passwordChanged(value);
                              return true;
                            },
                          ),

                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _openingWebsite || isLoading
                                  ? null
                                  : () => _openAccountPage(
                                      () => AppConstants.api.forgotPasswordUrl,
                                    ),
                              child: Text(
                                context.l10n.forgotPassword,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          FilledButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    context.read<AuthenticationCubit>().login();
                                  },
                            child: isLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : Text(context.l10n.logIn),
                          ),

                          const SizedBox(height: 16),

                          if (authentication.deletionPending) ...[
                            Card(
                              color: theme.colorScheme.errorContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      context.l10n.accountDeletionPending,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      context
                                          .l10n
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
                                          : authentication
                                                .signOutPendingDeletion,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(context.l10n.or),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              Text(context.l10n.noAccountQuestion),
                              TextButton(
                                onPressed: _openingWebsite || isLoading
                                    ? null
                                    : () => _openAccountPage(
                                        () => AppConstants.api.signupUrl,
                                      ),
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
                        ],
                      ),
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
