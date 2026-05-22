/*
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/cuenta_nextcloud.dart';

class StorageCuentas {
  static final StorageCuentas _instance = StorageCuentas._internal();

  factory StorageCuentas() => _instance;

  StorageCuentas._internal();

  static final _storageCuentas = FlutterSecureStorage();

  static Future<Map<String, String>> getCuentas() async {
    return await _storageCuentas.readAll();
  }

  static Future<bool> existeCuenta(CuentaNextcloud cuenta) async {
    return await _storageCuentas.containsKey(key: cuenta.name);
  }

  static Future<void> saveCuenta(CuentaNextcloud cuenta) async {
    bool existeKey = await existeCuenta(cuenta);
    if (existeKey == true) {
      deleteCuenta(cuenta.name);
    }
    await _storageCuentas.write(
      key: cuenta.name,
      value: CuentaNextcloud.serialize(cuenta),
    );
  }

  static Future<CuentaNextcloud?> getCuenta(String name) async {
    String? cuenta = await _storageCuentas.read(key: name);
    if (cuenta != null) {
      return CuentaNextcloud.deserialize(cuenta);
    }
    return null;
  }

  static Future<void> deleteCuenta(String name) async {
    await _storageCuentas.delete(key: name);
  }

  static Future<void> clearStorageCuentas() async {
    await _storageCuentas.deleteAll();
  }
}
*/
