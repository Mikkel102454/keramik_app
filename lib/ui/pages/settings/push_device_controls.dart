import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:clay_dock/app/push_controller.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';

class PushDeviceControls extends StatefulWidget {
  const PushDeviceControls({super.key});
  @override
  State<PushDeviceControls> createState() => _PushDeviceControlsState();
}

class _PushDeviceControlsState extends State<PushDeviceControls> {
  @override
  void initState() {
    super.initState();
    PushController.instance.refresh();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: PushController.instance,
    builder: (context, _) {
      final push = PushController.instance;
      final status = switch (push.permission) {
        AuthorizationStatus.authorized => context.l10n.permissionAllowed,
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently => context.l10n.permissionDenied,
        AuthorizationStatus.notDetermined => context.l10n.permissionUnknown,
        AuthorizationStatus.provisional => context.l10n.permissionLimited,
      };
      return Column(
        children: [
          ListTile(
            title: Text(context.l10n.pushNotifications),
            subtitle: Text(
              !push.available
                  ? context.l10n.pushUnavailable
                  : '${context.l10n.pushPermission}: $status',
            ),
            trailing: push.busy ? const CircularProgressIndicator() : null,
          ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: !push.available || push.busy
                    ? null
                    : () async {
                        try {
                          if (push.optedIn) {
                            await push.disable();
                          } else {
                            await push.enable();
                          }
                        } catch (_) {
                          /* Inline retry below. */
                        }
                      },
                child: Text(
                  push.optedIn
                      ? context.l10n.disableOnDevice
                      : context.l10n.enableOnDevice,
                ),
              ),
              TextButton(
                onPressed: push.configured ? push.openSettings : null,
                child: Text(context.l10n.androidNotificationSettings),
              ),
            ],
          ),
          if (push.failed)
            ListTile(
              title: Text(context.l10n.pushSyncFailed),
              trailing: TextButton(
                onPressed: push.refresh,
                child: Text(context.l10n.retry),
              ),
            ),
        ],
      );
    },
  );
}
