import 'package:nextcloud/files_sharing.dart';

extension ExtensionShare on Share {
  String get name {
    if (fileTarget.isEmpty || fileTarget.length == 1) return fileTarget;
    return fileTarget.substring(1);
  }

  bool get isDir => itemType.name == 'folder';

  String pathFile({required String currentPath}) => '$currentPath$fileTarget';
}
