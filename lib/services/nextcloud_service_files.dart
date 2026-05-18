part of 'nextcloud_service.dart';

extension NextcloudServiceFiles on NextcloudService {
  Future<List<WebDavFile>?>? getFiles({
    String path = '/',
    bool onlyDir = false,
    bool onlyImg = false,
    WebDavDepth depth = WebDavDepth.one,
  }) async {
    final uri = PathUri.parse(path);
    try {
      final responseWebDav = await client.webdav.propfind(uri, depth: depth);
      final listaItems = responseWebDav.toWebDavFiles();
      if (listaItems.isNotEmpty) {
        listaItems.removeAt(0);
      }

      final listaDir = listaItems.where((item) => item.isDirectory).toList();
      listaDir.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      if (onlyDir == true) return listaDir;

      final listaFile = listaItems.where((item) => !item.isDirectory).toList();
      listaFile.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      if (onlyImg == true) {
        return listaFile
            .where(
              (file) =>
                  (file.mimeType != null &&
                  file.mimeType!.startsWith('image/')),
            )
            .toList();
      }
      return listaDir + listaFile;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Uint8List?>? getThumbnail({
    required String path,
    int? x,
    int? y,
  }) async {
    try {
      final responseThumbnail = await client.files.api.getThumbnail(
        file: path,
        x: x ?? 64,
        y: y ?? 64,
      );
      return responseThumbnail.body;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Uint8List?>? readFileBytes(String path) async {
    try {
      var uri = PathUri.parse(path);
      final responseBytes = await client.webdav.get(uri);
      return responseBytes;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<bool> downloadFile({
    required String path,
    required String name,
  }) async {
    try {
      final responseBytes = await readFileBytes(path);
      if (responseBytes == null) {
        throw Error();
      }
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        throw Exception('Error en carpeta de descargas');
      }
      final file = File('${downloadsDir.path}/$name');
      await file.writeAsBytes(responseBytes);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
