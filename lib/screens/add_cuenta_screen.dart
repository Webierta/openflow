import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cuenta_nextcloud.dart';
import '../providers/cuentas_provider.dart';
import '../services/storage_service.dart';
import '../theme/styles_app.dart';
import '../widgets/snackbar_manager.dart';
import 'main_screen.dart';

class AddCuentaScreen extends ConsumerStatefulWidget {
  final CuentaNextcloud? cuentaEdit;

  const AddCuentaScreen({super.key, this.cuentaEdit});

  @override
  ConsumerState createState() => _AddCuentaScreenState();
}

class _AddCuentaScreenState extends ConsumerState<AddCuentaScreen> {
  final serverController = TextEditingController();
  final userController = TextEditingController();
  final paswController = TextEditingController();
  bool obscureText = true;

  @override
  void initState() {
    if (widget.cuentaEdit != null) {
      serverController.text = widget.cuentaEdit!.server;
      userController.text = widget.cuentaEdit!.userName;
      paswController.text = widget.cuentaEdit!.password;
    }
    super.initState();
  }

  @override
  void dispose() {
    serverController.dispose();
    userController.dispose();
    paswController.dispose();
    super.dispose();
  }

  Future<void> addCuenta() async {
    if (serverController.text.trim().isEmpty ||
        userController.text.trim().isEmpty ||
        paswController.text.trim().isEmpty) {
      SnackbarManager.show(
        context: context,
        msg: 'Error: datos incompletos',
        error: true,
      );
      return;
    }

    if (widget.cuentaEdit != null) {
      await StorageService.deleteCuenta(widget.cuentaEdit!.name);
      ref.read(cuentasProvider.notifier).remove(widget.cuentaEdit!);
    }
    CuentaNextcloud newCuenta = CuentaNextcloud(
      server: serverController.text,
      userName: userController.text,
      password: paswController.text,
      statusAuth: StatusAuth.logout,
    );
    await StorageService.saveCuenta(newCuenta);
    ref.read(cuentasProvider.notifier).add(newCuenta);
    //ref.read(cuentasProvider.notifier).edit...
    if (mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (context) => const MainScreen()));
    }
  }

  void showInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, size: 42),
            const SizedBox(width: 10),
            Text('Security'),
          ],
        ),
        content: Text(
          'La contraseña se cifra y almacena segura solo en el dispositivo '
          'local utilizando el cifrado específico de la plataforma '
          '(RSA OAEP + AES-GCM en Android por defecto).',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: StylesApp.backgroundScreen(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Add a Nextcloud account'),
          actions: [
            IconButton(onPressed: () => showInfo(), icon: Icon(Icons.info)),
          ],
        ),
        body: SingleChildScrollView(
          padding: .symmetric(horizontal: 40),
          child: Column(
            children: [
              const SizedBox(height: 40),
              TextField(
                controller: serverController,
                decoration: InputDecoration(
                  icon: Icon(Icons.storage),
                  label: Text('URL server'),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: userController,
                decoration: InputDecoration(
                  icon: Icon(Icons.person),
                  label: Text('User name'),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: paswController,
                obscureText: obscureText,
                decoration: InputDecoration(
                  icon: Icon(Icons.password),
                  label: Text('Password'),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => obscureText = !obscureText);
                    },
                    icon: Icon(Icons.remove_red_eye_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              OutlinedButton(onPressed: addCuenta, child: Text('Add Account')),
            ],
          ),
        ),
      ),
    );
  }
}
