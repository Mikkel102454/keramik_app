import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clay_dock/app/entitlement_controller.dart';
import 'package:clay_dock/l10n/l10n_extensions.dart';
import 'package:clay_dock/objects/purchase_options.dart';
import 'package:clay_dock/repositories/purchase_repository.dart';

/// All app upgrade entry points use this coordinator. Policy never authorizes a raw URL.
class PurchaseCoordinator {
  PurchaseCoordinator({PurchaseRepository? repository, MethodChannel? channel})
    : repository = repository ?? PurchaseRepository(),
      channel = channel ?? const MethodChannel('claydock/billing') {
    this.channel.setMethodCallHandler((call) async {
      if (call.method == 'purchases') {
        try {
          await _verifyPurchases(call.arguments);
          await EntitlementController.instance.refresh();
        } catch (_) {
          /* Retry using restore; never infer paid access. */
        }
      }
    });
  }
  static final instance = PurchaseCoordinator();
  final PurchaseRepository repository;
  final MethodChannel channel;
  bool _busy = false;
  Future<T?> _native<T>(String method, [Map<String, dynamic>? arguments]) =>
      channel
          .invokeMethod<T>(method, arguments)
          .timeout(const Duration(seconds: 35));

  Future<void> _verifyPurchases(dynamic result) async {
    if (result is! List) return;
    for (final raw in result) {
      final purchase = Map<String, dynamic>.from(raw as Map);
      if (purchase['purchased'] == true || purchase['pending'] == true) {
        await repository.verify(purchase['purchaseToken'] as String);
      }
    }
  }

  Future<void> restore(BuildContext context) async {
    if (_busy) return;
    _busy = true;
    try {
      await _verifyPurchases(await _native<dynamic>('restore'));
      await EntitlementController.instance.refresh();
    } catch (_) {
      if (context.mounted) _error(context);
    } finally {
      _busy = false;
    }
  }

  void _error(BuildContext context) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(context.l10n.purchaseUnavailable)));

  Future<void> open(BuildContext context) async {
    if (_busy) return;
    _busy = true;
    try {
      await _verifyPurchases(await _native<dynamic>('restore'));
      final country = await _native<String>('country');
      if (country == null || !RegExp(r'^[A-Z]{2}$').hasMatch(country)) {
        throw const FormatException('Unknown Play country');
      }
      var policy = await repository.load(country);
      if (policy.membershipProvider == 'PLAY') {
        await _native<void>('manage');
        return;
      }
      if (policy.membershipProvider == 'STRIPE') {
        // Existing Stripe membership stays earned. New purchase links still require native enrollment/eligibility.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.purchaseManageStripe)),
          );
        }
        return;
      }
      final choices = <_Choice>[];
      for (final route in policy.routes) {
        try {
          final offers =
              await _native<List<dynamic>>('offers', {
                'mode': route.mode,
                'productIds': route.products.map((p) => p.id).toList(),
              }) ??
              [];
          if (route.mode == 'EXTERNAL_OFFERS' ||
              route.mode == 'EXTERNAL_CONTENT_LINK') {
            choices.add(_Choice(route, null));
          }
          for (final raw in offers) {
            final offer = Map<String, dynamic>.from(raw as Map);
            if (route.products.any(
              (p) =>
                  p.id == offer['productId'] &&
                  p.basePlanId == offer['basePlanId'],
            )) {
              choices.add(_Choice(route, offer));
            }
          }
        } catch (_) {
          /* This route is withheld. Other independently verified routes may remain. */
        }
      }
      if (choices.isEmpty) {
        throw const FormatException('No verified purchase route');
      }
      if (!context.mounted) return;
      final selected = await showDialog<_Choice>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: Text(context.l10n.viewMakerMembership),
          children: [
            for (final choice in choices)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, choice),
                child: Text(choice.label(context)),
              ),
          ],
        ),
      );
      if (selected == null) return;
      // Refresh immediately before beginning checkout. This also rejects cross-instance emergency disablement.
      policy = await repository.load(country);
      final route = policy.routes.firstWhere(
        (r) => r.mode == selected.route.mode,
      );
      final freshOffers =
          await _native<List<dynamic>>('offers', {
            'mode': route.mode,
            'productIds': route.products.map((p) => p.id).toList(),
          }) ??
          [];
      Map<String, dynamic>? offer;
      if (selected.offer != null) {
        offer = Map<String, dynamic>.from(
          freshOffers.firstWhere(
                (raw) =>
                    raw['productId'] == selected.offer!['productId'] &&
                    raw['basePlanId'] == selected.offer!['basePlanId'] &&
                    raw['offerToken'] == selected.offer!['offerToken'],
              )
              as Map,
        );
        if (!route.products.any(
          (p) =>
              p.id == offer!['productId'] &&
              p.basePlanId == offer['basePlanId'],
        )) {
          throw const FormatException('Product changed');
        }
      }
      final operation = await repository.start(
        policy,
        route,
        country,
        offer?['productId'] as String?,
        offer?['basePlanId'] as String?,
      );
      String? destination;
      if (route.mode != 'PLAY') {
        final token = await _native<String>('reportingToken', {
          'mode': route.mode,
        });
        if (token == null || token.isEmpty) {
          throw const FormatException('No reporting token');
        }
        destination = await repository.external(operation, token, country);
        final expected = Uri.parse(route.destination!);
        final actual = Uri.parse(destination);
        if (expected.scheme != actual.scheme ||
            expected.host != actual.host ||
            expected.port != actual.port ||
            expected.path != actual.path) {
          throw const FormatException('Destination changed');
        }
      }
      if (offer == null) {
        await _native<bool>('externalLink', {'destination': destination});
      } else {
        final result = await channel
            .invokeMethod<dynamic>('purchase', {
              ...offer,
              'accountId': policy.accountId,
              'destination': destination,
            })
            .timeout(const Duration(minutes: 2));
        if (result is Map && result['canceled'] == true) {
          await repository.release(operation);
        } else {
          await _verifyPurchases(result);
        }
      }
      await EntitlementController.instance.refresh();
    } catch (_) {
      if (context.mounted) _error(context);
    } finally {
      _busy = false;
    }
  }
}

class _Choice {
  const _Choice(this.route, this.offer);
  final PurchaseRoute route;
  final Map<String, dynamic>? offer;
  String label(BuildContext context) {
    if (offer == null) return context.l10n.purchaseWebsite;
    final phases = (offer!['phases'] as List)
        .map((phase) {
          final period = RegExp(
            r'^P(\d+)([DWMY])$',
          ).firstMatch(phase['period'] as String);
          if (period == null) {
            throw const FormatException('Unsupported billing period');
          }
          final count = int.parse(period.group(1)!);
          final duration = switch (period.group(2)) {
            'D' => context.l10n.purchaseBillingDays(count),
            'W' => context.l10n.purchaseBillingWeeks(count),
            'M' => context.l10n.purchaseBillingMonths(count),
            'Y' => context.l10n.purchaseBillingYears(count),
            _ => throw const FormatException('Unsupported billing period'),
          };
          final cycles = phase['cycles'] as int? ?? 0;
          return '${phase['price']} / $duration${cycles > 0 ? ' ${context.l10n.purchasePayments(cycles)}' : ''}';
        })
        .join(', ');
    final provider =
        route.mode == 'BILLING_CHOICE' || route.mode == 'EXTERNAL_PAYMENTS'
        ? context.l10n.purchaseBillingChoice
        : 'Google Play';
    return '${offer!['name']} — $phases\n$provider';
  }
}
