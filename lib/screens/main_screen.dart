import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cuenta_nextcloud.dart';
import '../models/destino.dart';
import '../providers/cuentas_provider.dart';
import '../services/nextcloud_service.dart';
import '../theme/styles_app.dart';
import '../widgets/drawer_app.dart';
import '../widgets/open_dialog.dart';
import '../widgets/snackbar_manager.dart';
import 'add_cuenta_screen.dart';
import 'files_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  final CuentaNextcloud? cuentaSelect;

  const MainScreen({super.key, this.cuentaSelect});

  @override
  ConsumerState createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  CuentaNextcloud? cuentaSelect;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    loadCuenta();
    super.initState();
  }

  void loadCuenta() {
    if (widget.cuentaSelect != null) {
      setState(() {
        cuentaSelect = widget.cuentaSelect;
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> selectCuenta(List<CuentaNextcloud> cuentas) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Conecta la nube'),
          content: SizedBox(
            //width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: .min,
              children: [
                FittedBox(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CuentaNextcloud>(
                      padding: .all(0),
                      hint: cuentaSelect == null
                          ? Text('Selecciona una cuenta')
                          //: RowAvatar(cuenta: cuentaSelect!),
                          : Row(
                              mainAxisSize: .min,
                              children: [
                                // CuentaAvatar(cuenta: cuenta, size: 30, onlyAvatar: true),
                                if (cuentaSelect!.avatar != null)
                                  Badge(
                                    label: Text('✔'),
                                    backgroundColor: Colors.green,
                                    alignment: AlignmentGeometry.bottomRight,
                                    offset: Offset(0, -10),
                                    child: Image.memory(
                                      cuentaSelect!.avatar!,
                                      height: 30,
                                      width: 30,
                                    ),
                                  )
                                else
                                  Badge(
                                    label: Text('✖'),
                                    alignment: AlignmentGeometry.bottomRight,
                                    offset: Offset(0, -10),
                                    child: Icon(
                                      Icons.person_off,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                                  ),
                                const SizedBox(width: 20),
                                Text(
                                  cuentaSelect!.name,
                                  style: TextStyle(fontSize: 18),
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                ),
                              ],
                            ),
                      onChanged: (CuentaNextcloud? cuenta) async {
                        Navigator.of(context).pop();
                        if (cuenta != null) {
                          setState(() => cuentaSelect = cuenta);
                          await connectCuenta();
                        }
                      },
                      items: cuentas
                          .map<DropdownMenuItem<CuentaNextcloud>>(
                            (CuentaNextcloud cuenta) =>
                                DropdownMenuItem<CuentaNextcloud>(
                                  value: cuenta,
                                  /*child: FittedBox(
                                      child: RowAvatar(cuenta: cuenta),
                                    ),*/
                                  child: Text(
                                    cuenta.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> connectCuenta() async {
    if (cuentaSelect == null) {
      SnackbarManager.show(
        context: context,
        msg: 'Ninguna cuenta seleccionada',
        error: true,
      );
      return;
    }
    SnackbarManager.show(
      context: context,
      msg: 'Conectando a ${cuentaSelect!.name}...',
    );
    var nextcloudService = NextcloudService(cuenta: cuentaSelect!);
    final connect = await nextcloudService.connect();
    if (connect != null) {
      Uint8List? newAvatar =
          await nextcloudService.getAvatar(connect.id) ?? cuentaSelect!.avatar;
      final lastLogin = connect.lastLogin;
      ref
          .read(cuentasProvider.notifier)
          .edit(
            cuentaSelect!,
            newStatusAuth: StatusAuth.login,
            newLastLogin: lastLogin,
            newAvatar: newAvatar,
          );
      setState(() {
        cuentaSelect = cuentaSelect!.copyWith(
          statusAuth: StatusAuth.login,
          lastLogin: lastLogin,
          avatar: newAvatar,
        );
      });
    } else {
      if (cuentaSelect != null) {
        setState(() => cuentaSelect = null);
      }
      if (mounted) {
        SnackbarManager.show(
          context: context,
          msg: 'Error de conexión',
          error: true,
        );
      }
    }
  }

  void disconnectCuenta() {
    if (cuentaSelect == null) return;
    var nextcloudService = NextcloudService(cuenta: cuentaSelect!);
    nextcloudService.disconnect();
    ref.read(cuentasProvider.notifier).desconectar(cuentaSelect!);
    setState(() {
      //cuentaSelect = cuentaSelect!.copyWith(statusAuth: StatusAuth.logout);
      //cuentaSelect = cuentaSelect!.copyWith(avatar: null);
      cuentaSelect = null;
    });
    if (mounted) {
      SnackbarManager.show(
        context: context,
        msg: 'Cuenta desconectada del servidor',
      );
    }
  }

  Future<void> searchGlobal() async {
    final search = await OpenDialog.inputName(
      context: context,
      title: 'Search Global',
      icon: Icons.search,
      controller: searchController,
    );
    searchController.clear();
    if (search != null && search.trim().isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) =>
              FilesScreen(cuenta: cuentaSelect!, inputSearch: search),
        ),
      );
    }
  }

  void onTapDestino({
    required BuildContext context,
    Destino? destino,
    bool? isSearch = false,
  }) {
    if (cuentaSelect != null && cuentaSelect!.statusAuth == StatusAuth.login) {
      if (destino != null) {
        var onPage = destino.onPageRoute(
          context: context,
          cuenta: cuentaSelect!,
        );
        onPage.call();
      } else if (isSearch == true) {
        searchGlobal();
      }
    } else {
      String msg = 'Ninguna cuenta seleccionada';
      if (cuentaSelect != null &&
          cuentaSelect!.statusAuth != StatusAuth.login) {
        msg = 'Acceso a la cuenta denegado';
      }
      SnackbarManager.show(context: context, msg: msg, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuentas = ref.watch(cuentasProvider);
    if (cuentas.isEmpty) {
      return Container(
        decoration: StylesApp.backgroundScreen(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: .center,
              children: [
                Text('The sky is clear. Add a cloud.'),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const AddCuentaScreen(),
                      ),
                    );
                  },
                  child: Text('Add a Nextcloud account'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: StylesApp.backgroundScreen(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const DrawerApp(),
        appBar: AppBar(
          leadingWidth: 30,
          title: cuentaSelect == null
              ? const Text(
                  'Openflow',
                  style: TextStyle(fontWeight: FontWeight.w200),
                )
              : Row(
                  children: [
                    //CuentaAvatar(cuenta: cuentaSelect!, size: 30),
                    if (cuentaSelect!.avatar != null)
                      Badge(
                        label: Text('✔'),
                        backgroundColor: Colors.green,
                        alignment: AlignmentGeometry.bottomRight,
                        offset: Offset(0, -10),
                        child: Image.memory(
                          cuentaSelect!.avatar!,
                          height: 30,
                          width: 30,
                        ),
                      )
                    else
                      const Badge(
                        label: Text('✖'),
                        alignment: AlignmentGeometry.bottomRight,
                        offset: Offset(0, -10),
                        child: Icon(
                          Icons.person_off,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(width: 10),
                    Text(cuentaSelect!.userName),
                  ],
                ),
          actions: [
            if (cuentaSelect == null)
              IconButton.outlined(
                tooltip: 'Select count',
                onPressed: () => selectCuenta(cuentas),
                icon: Icon(Icons.cloud, color: Colors.white),
              )
            else
              Padding(
                padding: const .only(right: 4),
                child: IconButton.outlined(
                  tooltip: cuentaSelect!.statusAuth == StatusAuth.login
                      ? 'Desconectar'
                      : 'Reconectar',
                  onPressed: cuentaSelect!.statusAuth == StatusAuth.login
                      ? disconnectCuenta
                      : connectCuenta,
                  icon: Icon(
                    cuentaSelect!.statusAuth == StatusAuth.login
                        ? Icons.cloud_off
                        : Icons.cloud_done,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            double childAspectRatio =
                constraints.maxWidth / constraints.maxHeight;
            double sizeIcon = childAspectRatio * 150;
            double sizeFont = childAspectRatio * 40;
            return Stack(
              children: [
                GridView.count(
                  childAspectRatio: childAspectRatio,
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  physics: NeverScrollableScrollPhysics(),
                  children: List.generate(Destino.values.length, (index) {
                    var destino = Destino.values[index];
                    //var color = destino.color.withAlpha(130);
                    var color = destino.color.withAlpha(100);
                    return Container(
                      padding: const EdgeInsets.all(20),
                      color: color,
                      child: InkWell(
                        onTap: () =>
                            onTapDestino(context: context, destino: destino),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            children: [
                              Icon(destino.icon, size: sizeIcon),
                              Text(
                                destino.name,
                                style: TextStyle(fontSize: sizeFont),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                Center(
                  child: FractionallySizedBox(
                    heightFactor: 0.3,
                    widthFactor: 0.3,
                    child: Container(
                      padding: .all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      child: FittedBox(
                        child: IconButton(
                          padding: .zero,
                          onPressed: () =>
                              onTapDestino(context: context, isSearch: true),
                          icon: Icon(
                            Icons.search,
                            size: sizeIcon / 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
