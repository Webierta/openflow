import 'package:nextcloud/webdav.dart';

extension ExtensionWebdavfile on WebDavFile {
  /*String pathFile1(String currentPath) {
    if (path.parent?.path != null) return path.parent!.path + name;
    return '$currentPath/${path.name}';
  }

  String pathFileHomeSub2(String currentPath) {
    if (path.parent?.path == null) return '/${path.parent!.path}$name';
    return '${currentPath.substring(1)}/$name';
  }*/

  String pathFile({required String currentPath, bool bar = false}) {
    if (path.parent?.path != null) {
      return bar == false
          ? path.parent!.path + name
          : '/${path.parent!.path}$name';
    } else {
      return '$currentPath/$name';
      return bar == false
          ? '$currentPath/$name'
          : '${currentPath.substring(1)}/$name';
    }
  }
}
