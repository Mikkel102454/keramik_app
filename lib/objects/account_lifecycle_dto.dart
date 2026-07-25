class DataExportDto {
  const DataExportDto({
    required this.exportId,
    required this.status,
    required this.createdAt,
    required this.downloadAvailable,
    this.completedAt,
    this.expiresAt,
    this.errorMessage,
  });

  final String exportId;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final String? errorMessage;
  final bool downloadAvailable;

  factory DataExportDto.fromJson(Map<String, dynamic> json) => DataExportDto(
    exportId: json['exportId'] as String,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
    errorMessage: json['errorMessage'] as String?,
    downloadAvailable: json['downloadAvailable'] as bool? ?? false,
  );
}

class AccountDeletionDto {
  const AccountDeletionDto({
    required this.status,
    required this.requestedAt,
    required this.scheduledFor,
    required this.canCancel,
    required this.retainedDataNotice,
  });

  final String status;
  final DateTime requestedAt;
  final DateTime scheduledFor;
  final bool canCancel;
  final String retainedDataNotice;

  factory AccountDeletionDto.fromJson(Map<String, dynamic> json) =>
      AccountDeletionDto(
        status: json['status'] as String,
        requestedAt: DateTime.parse(json['requestedAt'] as String),
        scheduledFor: DateTime.parse(json['scheduledFor'] as String),
        canCancel: json['canCancel'] as bool? ?? false,
        retainedDataNotice: json['retainedDataNotice'] as String,
      );
}
