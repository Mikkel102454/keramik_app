import 'package:clay_dock/app/client_version_controller.dart';
import 'package:clay_dock/utils/web.dart';
import 'package:flutter/material.dart';

/// Overlay preserves the mounted router and unsent drafts during verification.
class ClientVersionGate extends StatelessWidget {
  const ClientVersionGate({
    required this.controller,
    required this.child,
    super.key,
  });
  final ClientVersionController controller;
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final da = Localizations.localeOf(context).languageCode == 'da';
      final deadline = controller.policy?.deadline;
      final deadlineText = deadline == null
          ? ''
          : '${da ? ' Kræves fra' : ' Required from'} ${deadline.toUtc().toIso8601String()}';
      Future<void> update() async {
        final url = controller.policy?.storeUrl;
        if (url == null) return;
        try {
          await openWebPage(url.toString());
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  da
                      ? 'Google Play kunne ikke åbnes. Prøv igen.'
                      : 'Could not open Google Play. Please retry.',
                ),
              ),
            );
          }
        }
      }

      return Stack(
        children: [
          ExcludeSemantics(
            excluding: !controller.mayEnter,
            child: AbsorbPointer(absorbing: !controller.mayEnter, child: child),
          ),
          if (controller.updateAvailable)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                child: Material(
                  elevation: 4,
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            da
                                ? 'En ClayDock-opdatering er tilgængelig.$deadlineText'
                                : 'A ClayDock update is available.$deadlineText',
                          ),
                        ),
                        TextButton(
                          onPressed: update,
                          child: Text(da ? 'Opdater' : 'Update'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!controller.mayEnter)
            Positioned.fill(
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.state == VersionVerification.checking)
                            const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            controller.state ==
                                    VersionVerification.updateRequired
                                ? (da
                                      ? 'Opdater ClayDock for at fortsætte.'
                                      : 'Update ClayDock to continue.')
                                : controller.state ==
                                      VersionVerification.checking
                                ? (da
                                      ? 'Kontrollerer appversion…'
                                      : 'Verifying app version…')
                                : (da
                                      ? 'Appversionen kunne ikke bekræftes. Kontroller forbindelsen og prøv igen.'
                                      : 'Could not verify the app version. Check your connection and retry.'),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (controller.state ==
                                  VersionVerification.updateRequired &&
                              controller.policy != null)
                            FilledButton(
                              onPressed: update,
                              child: Text(
                                da ? 'Åbn Google Play' : 'Open Google Play',
                              ),
                            ),
                          if (controller.state != VersionVerification.checking)
                            TextButton(
                              onPressed: controller.verify,
                              child: Text(da ? 'Prøv igen' : 'Retry'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
