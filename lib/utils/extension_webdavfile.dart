import 'package:nextcloud/webdav.dart';

extension ExtensionWebdavfile on WebDavFile {
  String? get pathName {
    if (path.parent == null) return null;
    return path.parent!.path + name;
  }

  String? get pathNameBar {
    if (path.parent == null) return null;
    return '/${path.parent!.path}$name';
  }

  String pathCurrent(String currentPath) {
    return '$currentPath/$name';
  }

  String pathFile({required String currentPath, bool bar = false}) {
    if (path.parent == null) return pathCurrent(currentPath);
    return bar == false
        ? pathName ?? pathCurrent(currentPath)
        : pathNameBar ?? pathCurrent(currentPath);
  }

  String ruta() {
    String ruta = 'Home';
    var dir = path.parent?.path;
    if (dir != null && dir.isNotEmpty) {
      ruta = 'Home/${dir.substring(0, dir.length - 1)}';
    }
    return ruta;
  }
}
