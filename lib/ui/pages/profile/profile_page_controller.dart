import 'package:ceramic_app/objects/user_profile_dto.dart';
import 'package:ceramic_app/repositories/social_repository.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/repositories/ceramic_repository.dart';
import 'package:ceramic_app/repositories/clay_repository.dart';
import 'package:ceramic_app/repositories/glaze_repository.dart';
import 'package:ceramic_app/repositories/stage_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePageController extends ChangeNotifier {
  bool _disposed = false;
  AccountProfileDto? account;
  List<UserProfileDto> friends = const [];
  String? friendsCursor;
  List<CeramicDto> ceramics = const [];
  List<StageDto> stages = const [];
  List<ClayDto> clays = const [];
  List<GlazeDto> glazes = const [];
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
        CeramicRepository.getCeramics(),
        StageRepository.getStages(),
        ClayRepository.getClayTypes(),
        GlazeRepository.getGlazes(),
      ]);
      account = results[0] as AccountProfileDto;
      friends = (results[1] as CursorPage<UserProfileDto>).items;
      friendsCursor = (results[1] as CursorPage<UserProfileDto>).nextCursor;
      ceramics = results[2] as List<CeramicDto>;
      stages = results[3] as List<StageDto>;
      clays = results[4] as List<ClayDto>;
      glazes = results[5] as List<GlazeDto>;
    } catch (exception) {
      error = 'We could not load your profile.';
    } finally {
      isLoading = false;
      _notifySafely();
    }
  }

  List<CeramicDto> get finishedCeramics {
    final finishedIds = stages
        .where((stage) => stage.title.toLowerCase() == 'finished')
        .map((stage) => stage.id)
        .toSet();
    return ceramics.where((ceramic) => finishedIds.contains(ceramic.stageId)).toList()
      ..sort((a, b) => (b.updatedAt ?? DateTime(1970))
          .compareTo(a.updatedAt ?? DateTime(1970)));
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
