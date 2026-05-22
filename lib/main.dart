import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/cuenta_nextcloud.dart';
import 'providers/cuentas_provider.dart';
import 'screens/main_screen.dart';
import 'services/secure_storage_service.dart';
import 'theme/theme_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // initializes all locales
  // await initializeDateFormatting('es_ES', null);
  runApp(ProviderScope(child: const MainApp()));
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  Future<void> getStorage() async {
    //await StorageCuentas.clearStorageCuentas();
    //final storage = await StorageCuentas.getCuentas();
    final storageServiceCuentas = SecureStorageService('cuentas');
    //storageService.clearStorageCuentas();
    //storageService.clearStorageGeneral();
    final storageCuentas = await storageServiceCuentas.getAllCuentas();
    List<String> cuentasName = [];
    storageCuentas.forEach((key, value) {
      cuentasName.add(key);
    });
    List<CuentaNextcloud> cuentasStorage = [];
    for (var name in cuentasName) {
      var cuenta = await storageServiceCuentas.getCuenta(name);
      if (cuenta != null) {
        cuentasStorage.add(cuenta);
      }
    }
    for (var cuenta in cuentasStorage) {
      ref.read(cuentasProvider.notifier).add(cuenta);
    }
  }

  @override
  void initState() {
    getStorage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeApp.lightThemeData,
      darkTheme: ThemeApp.darkThemeData,
      home: const MainScreen(),
    );
  }
}
