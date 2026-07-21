import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

Future<XFile> compressFile(File file) async {
  final temporaryDirectory = await getTemporaryDirectory();
  final targetPath =
      '${temporaryDirectory.path}/${DateTime.now().microsecondsSinceEpoch}.jpg';

  final XFile? compressed =
      await FlutterImageCompress.compressAndGetFile(
    file.path,
    targetPath,
    quality: 80,
    format: CompressFormat.jpeg,
  );

  if (compressed == null) {
    throw Exception('Failed to compress image');
  }

  return compressed;
}
