class UserProfileDto {
  const UserProfileDto({
    required this.userId,
    required this.username,
    required this.avatarInitials,
    required this.avatarColor,
    required this.relationshipState,
    required this.actions,
    this.avatarUrl,
    this.friendRequestId,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
  final String avatarInitials;
  final String avatarColor;
  final String relationshipState;
  final String? friendRequestId;
  final Set<String> actions;

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      avatarInitials: (json['avatarInitials'] as String?) ?? '?',
      avatarColor: (json['avatarColor'] as String?) ?? '#6D597A',
      relationshipState: (json['relationshipState'] as String?) ?? 'NONE',
      friendRequestId: json['friendRequestId'] as String?,
      actions: ((json['actions'] as List?) ?? const [])
          .whereType<String>()
          .toSet(),
    );
  }

  UserProfileDto copyWith({
    String? avatarUrl,
    bool clearAvatar = false,
    String? relationshipState,
    String? friendRequestId,
    Set<String>? actions,
  }) {
    return UserProfileDto(
      userId: userId,
      username: username,
      avatarUrl: clearAvatar ? null : avatarUrl ?? this.avatarUrl,
      avatarInitials: avatarInitials,
      avatarColor: avatarColor,
      relationshipState: relationshipState ?? this.relationshipState,
      friendRequestId: friendRequestId ?? this.friendRequestId,
      actions: actions ?? this.actions,
    );
  }
}

class AccountProfileDto {
  const AccountProfileDto({
    required this.userId,
    required this.username,
    required this.avatarInitials,
    required this.avatarColor,
    required this.forename,
    required this.surname,
    this.avatarUrl,
  });

  final String userId;
  final String username;
  final String? avatarUrl;
  final String avatarInitials;
  final String avatarColor;
  final String forename;
  final String surname;

  factory AccountProfileDto.fromJson(Map<String, dynamic> json) {
    return AccountProfileDto(
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      avatarInitials: (json['avatarInitials'] as String?) ?? '?',
      avatarColor: (json['avatarColor'] as String?) ?? '#6D597A',
      forename: (json['forename'] as String?) ?? '',
      surname: (json['surname'] as String?) ?? '',
    );
  }
}

class FriendRequestDto {
  const FriendRequestDto({
    required this.id,
    required this.user,
    required this.createdAt,
  });

  final String id;
  final UserProfileDto user;
  final DateTime createdAt;

  factory FriendRequestDto.fromJson(Map<String, dynamic> json) {
    return FriendRequestDto(
      id: json['id'] as String,
      user: UserProfileDto.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class CursorPage<T> {
  const CursorPage({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;

  factory CursorPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parser,
  ) {
    return CursorPage<T>(
      items: (json['items'] as List)
          .map((item) => parser(item as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  }
}
