import 'package:flutter/material.dart';
import 'package:clay_dock/app/entitlement_controller.dart';
import 'package:clay_dock/objects/entitlement_dto.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';
import 'package:clay_dock/app/purchase_coordinator.dart';

String featureLabel(BuildContext context, String feature) => switch (feature) {
  Features.ceramicImages => context.l10n.membershipImages,
  Features.firingRecords => context.l10n.firings,
  Features.publishedPieces => context.l10n.membershipPublications,
  Features.customGlazeCoats => context.l10n.membershipCoats,
  Features.projectTemplates => context.l10n.projectTemplates,
  Features.batchEditing => context.l10n.membershipBatchEditing,
  Features.privateCeramicSharing => context.l10n.shareCeramic,
  Features.practiceAnalytics => context.l10n.practiceAnalytics,
  Features.materialInventory => context.l10n.materialInventory,
  _ => context.l10n.membership,
};

Future<void> openMembershipWebsite(BuildContext context) async {
  await PurchaseCoordinator.instance.open(context);
}

/// Unknown/loading membership is distinct from a confirmed Free account.
/// The server remains authoritative, including idempotent retry and ownership.
Future<bool> requireFeature(
  BuildContext context,
  String feature, {
  int? currentUsage,
  int additions = 1,
  EntitlementController? controller,
}) async {
  final state = controller ?? EntitlementController.instance;
  if (!state.active) {
    return true;
  } // signed-out routes are handled by authentication
  if (state.value == null) await state.refresh();
  if (!context.mounted) {
    return false;
  }
  if (state.value == null) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.membership),
        content: Text(context.l10n.membershipLoadFailed),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              state.refresh();
              Navigator.pop(dialogContext);
            },
            child: Text(context.l10n.retry),
          ),
        ],
      ),
    );
    return false;
  }
  if (state.value!.allows(
    feature,
    currentUsage: currentUsage,
    additions: additions,
  )) {
    return true;
  }
  final access = state.value!.features[feature];
  await showFeatureLock(
    context,
    feature,
    limit: access?.limit,
    currentUsage: currentUsage ?? access?.currentUsage,
    offerMaker: state.value!.plan != 'Maker',
  );
  return false;
}

Future<void> showFeatureLock(
  BuildContext context,
  String feature, {
  int? limit,
  int? currentUsage,
  bool offerMaker = true,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: Text(featureLabel(context, feature)),
    content: Text(
      limit != null
          ? context.l10n.membershipLimitReached(currentUsage ?? 0, limit)
          : context.l10n.membershipRequired,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: Text(context.l10n.cancel),
      ),
      if (offerMaker)
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            openMembershipWebsite(context);
          },
          child: Text(context.l10n.viewMakerMembership),
        ),
    ],
  ),
);

class FeatureGate extends StatelessWidget {
  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.controller,
  });
  final String feature;
  final Widget child;
  final EntitlementController? controller;

  @override
  Widget build(BuildContext context) {
    final state = controller ?? EntitlementController.instance;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        if (!state.active || state.value?.allows(feature) == true) {
          return child;
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline),
                const SizedBox(height: 12),
                Text(
                  state.value == null
                      ? state.loading
                            ? context.l10n.membershipLoading
                            : context.l10n.membershipLoadFailed
                      : context.l10n.membershipRequired,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: state.loading ? null : state.refresh,
                  child: Text(context.l10n.refreshMembership),
                ),
                if (state.value != null)
                  FilledButton(
                    onPressed: () => openMembershipWebsite(context),
                    child: Text(context.l10n.viewMakerMembership),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class QuotaIndicator extends StatelessWidget {
  const QuotaIndicator({
    super.key,
    required this.feature,
    required this.currentUsage,
    this.controller,
  });
  final String feature;
  final int currentUsage;
  final EntitlementController? controller;

  @override
  Widget build(BuildContext context) {
    final state = controller ?? EntitlementController.instance;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final access = state.value?.features[feature];
        if (access == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            access.limit == null
                ? context.l10n.membershipUnlimitedUsage(
                    featureLabel(context, feature),
                    currentUsage,
                  )
                : context.l10n.membershipQuota(
                    featureLabel(context, feature),
                    currentUsage,
                    access.limit!,
                  ),
          ),
        );
      },
    );
  }
}
