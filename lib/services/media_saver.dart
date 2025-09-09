import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:mangayomi/providers/storage_provider.dart';

class MediaSaverService {
  static const MethodChannel _channel = MethodChannel('com.kodjodevf.mangayomi.media_saver');

  static Future<String?> saveImage({required Uint8List bytes, required String fileName, String album = 'Mangayomi'}) async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final String? savedPath = await _channel.invokeMethod<String>('saveImage', {
          'data': bytes,
          'name': fileName,
          'album': album,
        });
        return savedPath;
      } catch (e) {
        throw Exception('Failed to save image: $e');
      }
    }
    final dir = await StorageProvider().getGalleryDirectory();
    final filePath = p.join(dir!.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return filePath;
  }
}