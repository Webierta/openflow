import 'package:flutter/material.dart';

import '../screens/files_screen.dart';
import '../screens/gallery_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/shared_screen.dart';
import 'cuenta_nextcloud.dart';

enum Destino {
  files(name: 'Files', icon: Icons.folder_open, color: Color(0xFF64B5F6)),
  shared(
    name: 'Shared',
    icon: Icons.folder_shared_outlined,
    color: Color(0xFF2196F3),
  ),
  notes(name: 'Notes', icon: Icons.article_outlined, color: Color(0xFF1976D2)),
  gallery(
    name: 'Gallery',
    icon: Icons.photo_library_outlined,
    color: Color(0xFF0D47A1),
  );

  final String name;
  final IconData icon;
  final Color color;

  Function() onPageRoute({
    required CuentaNextcloud cuenta,
    required BuildContext context,
    //CancelToken? cancelToken,
  }) {
    final page = switch (this) {
      Destino.files => FilesScreen(cuenta: cuenta),
      Destino.shared => SharedScreen(cuenta: cuenta),
      Destino.notes => NotesScreen(cuenta: cuenta),
      Destino.gallery => GalleryScreen(cuenta: cuenta),
    };
    return () {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      //cancelToken?.cancel();
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (context) => page));
    };
  }

  const Destino({required this.name, required this.icon, required this.color});
}
