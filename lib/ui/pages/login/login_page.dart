import 'package:auto_route/auto_route.dart';
import 'package:clay_dock/ui/widgets/v2/text_field_widget.dart';
import 'package:clay_dock/ui/widgets/v2/studio_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clay_dock/cubits/authentication/authentication_cubit.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';
import 'package:clay_dock/config/constants/app_constants.dart';
import 'package:clay_dock/utils/web.dart';
import 'package:clay_dock/ui/pages/settings/mfa_settings_page.dart';
import 'package:clay_dock/ui/pages/settings/mfa_labels.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _openingWebsite = false;
  final _mfaCode = TextEditingController();

  @override
  void dispose() {
    _mfaCode.dispose();
    super.dispose();
  }

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

            if (authentication.mfaRequired) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          mfaText(
                            context,
                            'Complete authenticator verification',
                            'Fuldf?r authenticator-bekr?ftelse',
                          ),
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        if (authentication.mfaEnrollmentRequired)
                          FilledButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => BlocProvider.value(
                                        value: authentication,
                                        child: const MfaSettingsPage(
                                          pendingEnrollment: true,
                                        ),
                                      ),
                                    ),
                                  ),
                            child: Text(
                              mfaText(
                                context,
                                'Set up required MFA',
                                'Ops?t p?kr?vet MFA',
                              ),
                            ),
                          )
                        else ...[
                          TextFieldWidget(
                            controller: _mfaCode,
                            label: mfaText(
                              context,
                              'Six-digit authenticator code or one recovery code',
                              'Seks-cifret authenticator-kode eller ?n gendannelseskode',
                            ),
                            maxLength: 24,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final code = _mfaCode.text;
                                    _mfaCode.clear();
                                    await authentication.verifyMfa(code);
                                  },
                            child: Text(
                              mfaText(
                                context,
                                'Verify and sign in',
                                'Bekr?ft og log ind',
                              ),
                            ),
                          ),
                        ],
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  _mfaCode.clear();
                                  authentication.cancelMfa();
                                },
                          child: Text(
                            mfaText(
                              context,
                              'Use another account',
                              'Brug en anden konto',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

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
