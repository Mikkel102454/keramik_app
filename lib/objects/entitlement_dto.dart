class Features {
  static const ceramicImages = 'ceramic_images';
  static const firingRecords = 'firing_records';
  static const publishedPieces = 'published_pieces';
  static const customGlazeCoats = 'custom_glaze_coats';
  static const projectTemplates = 'project_templates';
  static const batchEditing = 'batch_editing';
  static const privateCeramicSharing = 'private_ceramic_sharing';
  static const practiceAnalytics = 'practice_analytics';
  static const materialInventory = 'material_inventory';
}

class FeatureAccess {
  const FeatureAccess({
    required this.available,
    required this.readAccess,
    this.limit,
    this.currentUsage,
  });
  final bool available;
  final bool readAccess;
  final int? limit;
  final int? currentUsage;

  factory FeatureAccess.fromJson(Map<String, dynamic> json) => FeatureAccess(
    available: json['available'] == true,
    readAccess: json['readAccess'] == true,
    limit: (json['limit'] as num?)?.toInt(),
    currentUsage: (json['currentUsage'] as num?)?.toInt(),
  );
}

class EntitlementDto {
  const EntitlementDto({
    required this.plan,
    required this.billingStatus,
    required this.enforcementEnabled,
    required this.features,
    this.cancelAtPeriodEnd = false,
    this.currentPeriodEnd,
  });
  final String plan;
  final String billingStatus;
  final bool enforcementEnabled;
  final bool cancelAtPeriodEnd;
  final DateTime? currentPeriodEnd;
  final Map<String, FeatureAccess> features;

  factory EntitlementDto.fromJson(Map<String, dynamic> json) => EntitlementDto(
    plan: json['plan'] as String,
    billingStatus: json['billingStatus'] as String,
    enforcementEnabled: json['enforcementEnabled'] == true,
    cancelAtPeriodEnd: json['cancelAtPeriodEnd'] == true,
    currentPeriodEnd: DateTime.tryParse(
      json['currentPeriodEnd'] as String? ?? '',
    ),
    features: Map.unmodifiable(
      (json['features'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          FeatureAccess.fromJson(Map<String, dynamic>.from(value)),
        ),
      ),
    ),
  );

  bool allows(String feature, {int? currentUsage, int additions = 1}) {
    final access = features[feature];
    if (access == null) return false;
    if (!enforcementEnabled) return true;
    if (!access.available) return false;
    final limit = access.limit;
    final usage = currentUsage ?? access.currentUsage;
    return limit == null ||
        usage == null ||
        additions <= 0 ||
        usage + additions <= limit;
  }
}
