import 'package:clay_dock/cubits/authentication/authentication_cubit.dart';
import 'package:clay_dock/repositories/mfa_repository.dart';
import 'package:clay_dock/ui/widgets/v2/text_field_widget.dart';
import 'package:clay_dock/utils/web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'mfa_labels.dart';

class MfaSettingsPage extends StatefulWidget {
  const MfaSettingsPage({
    super.key,
    this.pendingEnrollment = false,
    this.repository,
  });
  final bool pendingEnrollment;
  final MfaRepository? repository;
  @override
  State<MfaSettingsPage> createState() => _MfaSettingsPageState();
}

class _MfaSettingsPageState extends State<MfaSettingsPage> {
  late final _repository = widget.repository ?? MfaRepository();
  final _password = TextEditingController();
  final _code = TextEditingController();
  Map<String, dynamic>? _status;
  Map<String, dynamic>? _enrollment;
  List<String>? _recoveryCodes;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _run(() async {
      _status = await _repository.status();
    });
  }

  @override
  void dispose() {
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await operation();
    } on ApiException catch (error) {
      if (mounted) _error = error.message;
    } catch (_) {
      if (mounted) {
        _error = mfaText(
          context,
          'Could not complete the request. Retry.',
          'Handlingen kunne ikke udføres. Prøv igen.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _status?['enabled'] == true;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          mfaText(context, 'Authenticator security', 'Authenticator-sikkerhed'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                mfaText(
                  context,
                  'Use a compatible authenticator app. Administrators must use MFA.',
                  'Brug en kompatibel authenticator-app. Administratorer skal bruge MFA.',
                ),
              ),
              const SizedBox(height: 16),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_status == null && !_busy)
                TextButton(
                  onPressed: () => _run(() async {
                    _status = await _repository.status();
                  }),
                  child: Text(mfaText(context, 'Retry', 'Prøv igen')),
                ),
              if (_recoveryCodes != null) ...[
                Text(
                  mfaText(
                    context,
                    'Save your recovery codes now',
                    'Gem dine gendannelseskoder nu',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  mfaText(
                    context,
                    'Each code works once. Store them privately outside this device. They will not be shown again.',
                    'Hver kode virker én gang. Gem dem privat uden for denne enhed. De vises ikke igen.',
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(_recoveryCodes!.join('\n')),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (widget.pendingEnrollment) {
                            await context
                                .read<AuthenticationCubit>()
                                .completeMfaEnrollment();
                          }
                          if (context.mounted) Navigator.of(context).pop();
                        },
                  child: Text(
                    mfaText(
                      context,
                      'I saved my codes',
                      'Jeg har gemt mine koder',
                    ),
                  ),
                ),
              ] else if (_enrollment != null) ...[
                const SizedBox(height: 12),
                Text(
                  mfaText(
                    context,
                    'Open your authenticator on this phone, or enter this private setup key manually. Setup expires after five minutes.',
                    'Åbn din authenticator på denne telefon, eller indtast denne private opsætningsnøgle manuelt. Opsætningen udløber efter fem minutter.',
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(_enrollment!['secret'] as String),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          () =>
                              openWebPage(_enrollment!['otpauthUri'] as String),
                        ),
                  child: Text(
                    mfaText(
                      context,
                      'Open authenticator app',
                      'Åbn authenticator-app',
                    ),
                  ),
                ),
                TextFieldWidget(
                  controller: _code,
                  label: mfaText(
                    context,
                    'Six-digit authenticator code',
                    'Seks-cifret authenticator-kode',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          _recoveryCodes = await _repository.confirm(
                            _code.text,
                          );
                          _code.clear();
                          _password.clear();
                          _enrollment = null;
                        }),
                  child: Text(
                    mfaText(context, 'Confirm enrollment', 'Bekræft opsætning'),
                  ),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _enrollment = null;
                          _code.clear();
                        }),
                  child: Text(
                    mfaText(context, 'Restart setup', 'Start opsætning igen'),
                  ),
                ),
              ] else if (_status != null) ...[
                const SizedBox(height: 12),
                if (!widget.pendingEnrollment)
                  TextFieldWidget(
                    controller: _password,
                    label: mfaText(
                      context,
                      'Current password',
                      'Nuværende adgangskode',
                    ),
                    obscureText: true,
                    maxLines: 1,
                  ),
                if (!enabled && _status?['available'] == true)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            _enrollment = await _repository.enroll(
                              _password.text,
                            );
                            _password.clear();
                          }),
                    child: Text(
                      mfaText(
                        context,
                        'Set up authenticator',
                        'Opsæt authenticator',
                      ),
                    ),
                  ),
                if (!enabled && _status?['available'] != true)
                  Text(
                    mfaText(
                      context,
                      'Authenticator enrollment is not yet available.',
                      'Authenticator-opsætning er endnu ikke tilgængelig.',
                    ),
                  ),
                if (enabled) ...[
                  const SizedBox(height: 12),
                  TextFieldWidget(
                    controller: _code,
                    label: mfaText(
                      context,
                      'New authenticator code or one recovery code',
                      'Ny authenticator-kode eller én gendannelseskode',
                    ),
                    maxLength: 24,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            _enrollment = await _repository.replace(
                              _password.text,
                              _code.text,
                            );
                            _password.clear();
                            _code.clear();
                          }),
                    child: Text(
                      mfaText(
                        context,
                        'Replace authenticator',
                        'Udskift authenticator',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mfaText(
                      context,
                      'For replacement, the code is optional within five minutes of MFA sign-in. Your current authenticator remains active until the replacement is confirmed.',
                      'Ved udskiftning er koden valgfri inden for fem minutter efter MFA-login. Din nuværende authenticator forbliver aktiv, indtil udskiftningen er bekræftet.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            _recoveryCodes = await _repository.regenerate(
                              _password.text,
                              _code.text,
                            );
                            _password.clear();
                            _code.clear();
                          }),
                    child: Text(
                      mfaText(
                        context,
                        'Replace recovery codes',
                        'Udskift gendannelseskoder',
                      ),
                    ),
                  ),
                  if (_status?['required'] != true)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await _repository.disable(
                                _password.text,
                                _code.text,
                              );
                              _password.clear();
                              _code.clear();
                              _status = await _repository.status();
                            }),
                      child: Text(
                        mfaText(
                          context,
                          'Disable authenticator',
                          'Deaktiver authenticator',
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    mfaText(
                      context,
                      'Lost your authenticator? Sign in with one recovery code, then replace your factor. Password recovery does not remove MFA.',
                      'Mistet din authenticator? Log ind med én gendannelseskode, og udskift derefter din faktor. Adgangskodegendannelse fjerner ikke MFA.',
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
