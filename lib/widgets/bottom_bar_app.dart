import 'package:flutter/material.dart';
import 'package:nextcloud/webdav.dart';

import '../models/cuenta_nextcloud.dart';
import '../models/destino.dart';
import '../screens/main_screen.dart';

class BottomBarApp extends StatelessWidget {
  final CuentaNextcloud cuenta;
  final Destino destino;
  final Future<void> Function()? funcion;
  final WebDavDepth? depth;

  //final CancelToken cancelToken;

  const BottomBarApp({
    super.key,
    required this.cuenta,
    required this.destino,
    this.funcion,
    //this.depth = '1',
    this.depth = WebDavDepth.one,
    //required this.cancelToken,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 70,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton.filledTonal(
              tooltip: 'Home',
              icon: const Icon(Icons.home, size: 32),
              onPressed: () {
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    //builder: (context) => CuentaScreen(cuentaSelect: cuenta),
                    builder: (context) => MainScreen(cuentaSelect: cuenta),
                  ),
                );
              },
            ),
          ),
          for (var dest in Destino.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: IconButton(
                tooltip: dest.name,
                icon: Icon(
                  dest.icon,
                  size: 32,
                  color: dest == destino ? Colors.blue : Colors.grey,
                ),
                onPressed: dest.onPageRoute(
                  context: context,
                  cuenta: cuenta,
                  //cancelToken: cancelToken,
                ),
              ),
            ),
          const Spacer(),
          if (funcion != null && depth == WebDavDepth.one)
            IconButton.filled(
              onPressed: funcion,
              icon: Icon(destino == Destino.notes ? Icons.add : Icons.upload),
              //iconSize: 32,
              tooltip: destino == Destino.notes ? 'Add note' : 'Upload file',
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              //style: ButtonStyle(shape: WidgetStatePropertyAll()),
            ),
        ],
      ),
    );
  }
}
