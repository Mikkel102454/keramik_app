import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/repositories/social_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePageController extends ChangeNotifier {
  bool _disposed = false;
  AccountProfileDto? account;
  List<UserProfileDto> friends = const [];
  String? friendsCursor;
  bool isLoading = false;
  bool isUpdatingPhoto = false;
  String? error;

  Future<void> load() async {
    if (_disposed) return;
    isLoading = true;
    error = null;
    _notifySafely();
    try {
      final results = await Future.wait<dynamic>([
        SocialRepository.getMe(),
        SocialRepository.getFriends(),
      ]);
      account = results[0] as AccountProfileDto;
      friends = (results[1] as CursorPage<UserProfileDto>).items;
      friendsCursor = (results[1] as CursorPage<UserProfileDto>).nextCursor;
    } catch (exception) {
      error = exception.toString();
    } finally {
      isLoading = false;
      _notifySafely();
    }
  }

  Future<void> loadMoreFriends() async {
    if (_disposed) return;
    final cursor = friendsCursor;
    if (cursor == null) return;
    final page = await SocialRepository.getFriends(cursor: cursor);
    friends = [...friends, ...page.items];
    friendsCursor = page.nextCursor;
    _notifySafely();
  }

  Future<void> uploadPhoto(XFile file) async {
    if (_disposed) return;
    isUpdatingPhoto = true;
    _notifySafely();
    try {
      await SocialRepository.uploadProfilePhoto(file);
      await load();
    } finally {
      isUpdatingPhoto = false;
      _notifySafely();
    }
  }

  Future<void> removePhoto() async {
    if (_disposed) return;
    isUpdatingPhoto = true;
    _notifySafely();
    try {
      await SocialRepository.removeProfilePhoto();
      await load();
    } finally {
      isUpdatingPhoto = false;
      _notifySafely();
    }
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
