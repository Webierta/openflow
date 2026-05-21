import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageDataService {
  static final StorageDataService _instance = StorageDataService._internal();

  factory StorageDataService() => _instance;

  StorageDataService._internal();

  static final _storage = const FlutterSecureStorage();

  // DIR GALLERY
  static const String _dirGalleryKey = 'dir_gallery';

  static Future<void> saveDirGallery(String dir) async {
    await _storage.write(key: _dirGalleryKey, value: dir);
  }

  static Future<String?> getDirGallery() async {
    return await _storage.read(key: _dirGalleryKey);
  }

  static Future<bool> isDirGallery() async {
    final dir = await getDirGallery();
    return dir != null && dir.isNotEmpty;
  }

  // Clear all data
  static Future<void> logout() async {
    await _storage.deleteAll();
  }
}
