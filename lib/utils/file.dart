import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<XFile> compressFile(File file) async {
  final targetPath =
      '${file.parent.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

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