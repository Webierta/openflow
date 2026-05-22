import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/cuenta_nextcloud.dart';

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

  Future<void> saveDirGallery(String dir) async {
    await _storageGeneral.write(key: _scopedKey(_dirGalleryKey), value: dir);
  }

  Future<String?> getDirGallery() async {
    return await _storageGeneral.read(key: _scopedKey(_dirGalleryKey));
  }

  Future<bool> isDirGallery() async {
    final dir = await getDirGallery();
    return dir != null && dir.isNotEmpty;
  }

  Future<void> deleteDirGallery() async {
    await _storageGeneral.delete(key: _scopedKey(_dirGalleryKey));
  }

  // 2.2.2 Métodos generales para este almacén

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
