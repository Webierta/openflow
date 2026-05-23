import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nextcloud/notes.dart';

import '../models/cuenta_nextcloud.dart';
//import '../utils/extension_note.dart';

class SecureStorageService {
  final String scope;

  /*// Instancia única (Singleton)
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();*/

  static final Map<String, SecureStorageService> _instances = {};

  // Singleton por scope
  factory SecureStorageService(String scope) {
    return _instances.putIfAbsent(
      scope,
      () => SecureStorageService._internal(scope),
    );
  }

  SecureStorageService._internal(this.scope);

  //String _k(String key) => '$scope::$key';
  String _scopedKey(String key) => '$scope::$key';

  //String _scopedKey(String nameCuenta, String key) => '$scope::$nameCuenta:$key';

  // 1. Definición interna de los almacenes independientes
  final FlutterSecureStorage _storageCuentas = const FlutterSecureStorage(
    aOptions: AndroidOptions(storageNamespace: 'storage cuentas'),
    lOptions: LinuxOptions(),
  );

  final FlutterSecureStorage _storageGeneral = const FlutterSecureStorage(
    aOptions: AndroidOptions(storageNamespace: 'storage general'),
    lOptions: LinuxOptions(),
  );

  // 2.1. Métodos para el Almacén de Cuentas

  Future<void> saveCuenta(CuentaNextcloud cuenta) async {
    bool existeKey = await existeCuenta(cuenta);
    if (existeKey == true) await deleteCuenta(cuenta.name);
    await _storageCuentas.write(
      key: _scopedKey(cuenta.name),
      value: CuentaNextcloud.serialize(cuenta),
    );
  }

  Future<bool> existeCuenta(CuentaNextcloud cuenta) async {
    return await _storageCuentas.containsKey(key: _scopedKey(cuenta.name));
  }

  Future<CuentaNextcloud?> getCuenta(String name) async {
    String? cuenta = await _storageCuentas.read(key: _scopedKey(name));
    if (cuenta != null) {
      return CuentaNextcloud.deserialize(cuenta);
    }
    return null;
  }

  Future<Map<String, String>> getAllCuentas() async {
    final all = await _storageCuentas.readAll();
    return Map.fromEntries(
      all.entries
          .where((e) => e.key.startsWith('$scope::'))
          .map((e) => MapEntry(e.key.replaceFirst('$scope::', ''), e.value)),
    );
    // return await _storageCuentas.readAll();
  }

  Future<void> deleteCuenta(String name) async {
    await _storageCuentas.delete(key: _scopedKey(name));
  }

  Future<void> clearStorageCuentas() async {
    final all = await _storageCuentas.readAll();
    final scopedKeys = all.keys.where((k) => k.startsWith('$scope::'));
    for (final key in scopedKeys) {
      await _storageCuentas.delete(key: key);
    }
    //await _storageCuentas.deleteAll();
  }

  // 2.2 Métodos para el Almacén General

  // 2.2.1 DIRECTORIO GALLERY
  static const String _dirGalleryKey = 'dir_gallery';

  Future<void> saveDirGallery({
    required String nameCuenta,
    required String dir,
  }) async {
    await _storageGeneral.write(
      key: _scopedKey('$nameCuenta:$_dirGalleryKey'),
      value: dir,
    );
  }

  Future<String?> getDirGallery({required String nameCuenta}) async {
    return await _storageGeneral.read(
      key: _scopedKey('$nameCuenta:$_dirGalleryKey'),
    );
  }

  Future<bool> isDirGallery({required String nameCuenta}) async {
    final dir = await getDirGallery(nameCuenta: nameCuenta);
    return dir != null && dir.isNotEmpty;
  }

  Future<void> deleteDirGallery({required String nameCuenta}) async {
    await _storageGeneral.delete(
      key: _scopedKey('$nameCuenta:$_dirGalleryKey'),
    );
  }

  // 2.2.2 NOTES SETTINGS
  static const String _notesSettingsKey = 'notes_settings';

  Map<String, dynamic> toMap(Settings settings) => <String, dynamic>{
    'notesPath': settings.notesPath,
    'fileSuffix': settings.fileSuffix,
    'noteMode': settings.noteMode.name,
  };

  Future<void> saveNotesSettings({
    required String nameCuenta,
    required Settings settings,
  }) async {
    await _storageGeneral.write(
      key: _scopedKey('$nameCuenta:$_notesSettingsKey'),
      value: json.encode(toMap(settings)),
    );
  }

  Future<String?> getNotesSettings({required String nameCuenta}) async {
    String? settings = await _storageGeneral.read(
      key: _scopedKey('$nameCuenta:$_notesSettingsKey'),
    );
    if (settings != null) return settings;
    return null;
  }

  /*Future<bool> isNotesSettings({required String nameCuenta}) async {
    final settings = await getNotesSettings(nameCuenta: nameCuenta);
    return settings != null && settings.isNotEmpty;
  }

  Future<void> deleteNotesSettings({required String nameCuenta}) async {
    await _storageGeneral.delete(
      key: _scopedKey('$nameCuenta:$_notesSettingsKey'),
    );
  }*/

  // 2.2.3 Métodos generales para este almacén

  Future<Map<String, String>> readAllGeneral() async {
    //return await _storageGeneral.readAll();
    final all = await _storageGeneral.readAll();
    return Map.fromEntries(
      all.entries
          .where((e) => e.key.startsWith('$scope::'))
          .map((e) => MapEntry(e.key.replaceFirst('$scope::', ''), e.value)),
    );
  }

  Future<void> clearStorageGeneral() async {
    //await _storageGeneral.deleteAll();
    final all = await _storageGeneral.readAll();
    final scopedKeys = all.keys.where((k) => k.startsWith('$scope::'));
    for (final key in scopedKeys) {
      await _storageGeneral.delete(key: key);
    }
  }
}

/*extension on Settings {
  static Map<String, dynamic> toMap(Settings settings) => <String, dynamic>{
    'notesPath': settings.notesPath,
    'fileSuffix': settings.fileSuffix,
    'noteMode': settings.noteMode.name,
  };

  String serialize(Settings settings) => json.encode(toMap(settings));

  //Future<Settings?> deserialize(String settings) {}

  Settings deserialize(String json) => Settings.fromDataJson(jsonDecode(json));

  //static MyUserModel deserialize(String json) =>
  //    MyUserModel.fromJson(jsonDecode(json));
}*/
