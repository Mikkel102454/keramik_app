class PurchaseProduct {
  const PurchaseProduct(this.id, this.basePlanId);
  final String id;
  final String basePlanId;
}

class PurchaseRoute {
  const PurchaseRoute(this.mode, this.products, this.destination);
  final String mode;
  final List<PurchaseProduct> products;
  final String? destination;
  static const supported = {
    'PLAY',
    'EXTERNAL_CONTENT_LINK',
    'EXTERNAL_OFFERS',
    'BILLING_CHOICE',
    'EXTERNAL_PAYMENTS',
  };
}

class PurchaseOptions {
  PurchaseOptions({
    required this.revision,
    required this.validUntil,
    required this.accountId,
    required this.routes,
    this.membershipProvider,
    required this.overlappingSubscriptions,
  });
  final int revision;
  final DateTime validUntil;
  final String accountId;
  final String? membershipProvider;
  final bool overlappingSubscriptions;
  final List<PurchaseRoute> routes;

  factory PurchaseOptions.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1 ||
        json['revision'] is! int ||
        json['accountId'] is! String ||
        json['routes'] is! List) {
      throw const FormatException('Unsupported purchase policy');
    }
    final expiry = DateTime.parse(json['validUntil'] as String);
    if (!expiry.isAfter(DateTime.now().toUtc()) ||
        expiry.isAfter(
          DateTime.now().toUtc().add(const Duration(minutes: 1)),
        )) {
      throw const FormatException('Purchase policy is stale');
    }
    final routes = <PurchaseRoute>[];
    for (final raw in json['routes'] as List) {
      final route = Map<String, dynamic>.from(raw as Map);
      final mode = route['mode'] as String;
      if (!PurchaseRoute.supported.contains(mode)) continue;
      final destination = route['destination'] as String?;
      if (mode != 'PLAY' &&
          (destination == null ||
              Uri.tryParse(destination)?.scheme != 'https')) {
        continue;
      }
      routes.add(
        PurchaseRoute(mode, [
          for (final product in route['products'] as List)
            PurchaseProduct(
              product['id'] as String,
              product['basePlanId'] as String,
            ),
        ], destination),
      );
    }
    return PurchaseOptions(
      revision: json['revision'] as int,
      validUntil: expiry,
      accountId: json['accountId'] as String,
      routes: routes,
      membershipProvider: json['membershipProvider'] as String?,
      overlappingSubscriptions: json['overlappingSubscriptions'] == true,
    );
  }
}
