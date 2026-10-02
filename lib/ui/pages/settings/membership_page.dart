import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ceramic_app/app/entitlement_controller.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/ui/widgets/feature_gate.dart';

class MembershipPage extends StatelessWidget {
  const MembershipPage({super.key, this.controller});
  final EntitlementController? controller;

  @override
  Widget build(BuildContext context) {
    final state = controller ?? EntitlementController.instance;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.membership)),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final value = state.value;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (state.loading) const LinearProgressIndicator(),
              if (state.failed && value != null)
                Text(context.l10n.membershipLoadFailed),
              Text(
                value == null
                    ? state.loading
                          ? context.l10n.membershipLoading
                          : context.l10n.membershipLoadFailed
                    : value.plan == 'Maker'
                    ? context.l10n.membershipMaker
                    : context.l10n.membershipFree,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (value != null && !value.enforcementEnabled)
                Text(context.l10n.membershipPreview),
              if (value?.plan == 'Maker' && value?.billingStatus == 'past_due')
                Text(context.l10n.membershipOverdue),
              if (value?.cancelAtPeriodEnd == true &&
                  value?.currentPeriodEnd != null)
                Text(
                  context.l10n.membershipEnds(
                    DateFormat.yMMMd(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).format(value!.currentPeriodEnd!.toLocal()),
                  ),
                ),
              const SizedBox(height: 12),
              Text(context.l10n.membershipDataPreserved),
              for (final entry in value?.features.entries ?? <Never>[])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(featureLabel(context, entry.key)),
                  subtitle: Text(
                    entry.value.currentUsage != null &&
                            entry.value.limit != null
                        ? context.l10n.membershipQuota(
                            featureLabel(context, entry.key),
                            entry.value.currentUsage!,
                            entry.value.limit!,
                          )
                        : entry.value.limit != null
                        ? context.l10n.membershipAllowance(entry.value.limit!)
                        : entry.value.available
                        ? context.l10n.membershipIncluded
                        : entry.value.readAccess
                        ? context.l10n.membershipReadOnly
                        : context.l10n.membershipRequired,
                  ),
                ),
              OutlinedButton(
                onPressed: state.loading ? null : state.refresh,
                child: Text(context.l10n.refreshMembership),
              ),
              FilledButton(
                onPressed: () => openMembershipWebsite(context),
                child: Text(context.l10n.viewMakerMembership),
              ),
              Text(context.l10n.membershipBrowserSignIn),
            ],
          );
        },
      ),
    );
  }
}
