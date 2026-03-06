class UserDto {
  final String username;
  final bool isAuthorized;

  UserDto({
    required this.username,
    required this.isAuthorized,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      username: json['username'],
      isAuthorized: json['isAuthorized']
    );
  }
}