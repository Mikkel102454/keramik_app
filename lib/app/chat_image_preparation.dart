import 'dart:io';

import 'package:ceramic_app/app/chat_media_controller.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ChatImagePreparation {
  /// Opens the system grid/camera and copies only the selected image to app cache.
  static Future<File?> pick(ImageSource source) async {
    XFile? picked;
    File? output;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (picked == null) return null;
      final bytes = await FlutterImageCompress.compressWithList(
        await picked.readAsBytes(),
        quality: 85,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        throw StateError('Image exceeds limit');
      }
      output = await ChatMediaFiles.create('jpg');
      await output.writeAsBytes(bytes, flush: true);
      return output;
    } catch (_) {
      try {
        await output?.delete();
      } catch (_) {
        /* Startup recovery retries. */
      }
      rethrow;
    } finally {
      if (picked != null) {
        try {
          final cache = await getTemporaryDirectory();
          final path = File(picked.path).absolute.path;
          final root = cache.absolute.path;
          if (path.startsWith('$root${Platform.pathSeparator}')) {
            await File(path).delete();
          }
        } catch (_) {
          /* Never remove photos outside the app's temporary cache. */
        }
      }
    }
  }
}
