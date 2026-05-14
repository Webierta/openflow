import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/cuenta_nextcloud.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;

  StorageService._internal();

  static final FlutterSecureStorage _storageService = FlutterSecureStorage();

  static Future<Map<String, String>> getStorage() async {
    return await _storageService.readAll();
  }

  static Future<bool> existeCuenta(CuentaNextcloud cuenta) async {
    return await _storageService.containsKey(key: cuenta.name);
  }

  static Future<void> saveCuenta(CuentaNextcloud cuenta) async {
    bool existeKey = await existeCuenta(cuenta);
    if (existeKey == true) {
      deleteCuenta(cuenta.name);
    }
    await _storageService.write(
      key: cuenta.name,
      value: CuentaNextcloud.serialize(cuenta),
    );
  }

  static Future<CuentaNextcloud?> getCuenta(String name) async {
    String? cuenta = await _storageService.read(key: name);
    if (cuenta != null) {
      return CuentaNextcloud.deserialize(cuenta);
    }
    return null;
  }

  static Future<void> deleteCuenta(String name) async {
    await _storageService.delete(key: name);
  }

  static Future<void> clearStorage() async {
    await _storageService.deleteAll();
  }
}
