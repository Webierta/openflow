part of 'nextcloud_service.dart';

class CopyJob {
  final String source;
  final String destination;

  CopyJob(this.source, this.destination);
}

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

  Future<bool> createFolder(String folderPath) async {
    var path = PathUri.parse(folderPath);
    try {
      final responseFolder = await client.webdav.mkcol(path);
      if (responseFolder.statusCode == 201) {
        return true;
      } else {
        throw Error();
      }
    } catch (e) {
      //if (e. statusCode != 405) rethrow;
      print(e);
      return false;
    }
  }

  Future<void> createFolders({
    required List<String> destinos,
    void Function(int done, int total)? onProgress,
  }) async {
    int done = 0;
    for (final destino in destinos) {
      //final destination = url + destino; // encodeFull ??
      var path = PathUri.parse(destino);
      try {
        final responseCreate = await client.webdav.mkcol(path);
        if (responseCreate.statusCode == 201) {
          done++;
          onProgress?.call(done, destinos.length);
        } else {
          throw Exception(
            'Error al crear carpeta: ${responseCreate.statusCode}',
          );
        }
      } catch (e) {
        print(e);
      }
    }
  }

  Future<bool> moveFile({
    required String oldPath,
    required String newPath,
    bool overwrite = true,
  }) async {
    var sourcePath = PathUri.parse(oldPath);
    var destinationPath = PathUri.parse(newPath);
    try {
      var responseMove = await client.webdav.move(
        sourcePath,
        destinationPath,
        overwrite: overwrite,
      );
      if (responseMove.statusCode == 201 || responseMove.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> copyFile({
    required String oldPath,
    required String newPath,
    bool overwrite = false,
  }) async {
    var sourcePath = PathUri.parse(oldPath);
    var destinationPath = PathUri.parse(newPath);
    try {
      final responseCopy = await client.webdav.copy(
        sourcePath,
        destinationPath,
        overwrite: overwrite,
      );
      if (responseCopy.statusCode == 201 || responseCopy.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> copyFolder({
    required List<CopyJob> copyJobs,
    void Function(int done, int total)? onProgress,
    bool overwrite = false,
  }) async {
    int done = 0;
    for (final job in copyJobs) {
      var sourcePath = PathUri.parse(job.source);
      var destinationPath = PathUri.parse(job.destination);
      try {
        final responseCopy = await client.webdav.copy(
          sourcePath,
          destinationPath,
          overwrite: overwrite,
        );
        if (responseCopy.statusCode == 201 || responseCopy.statusCode == 204) {
          done++;
          onProgress?.call(done, copyJobs.length);
        } else {
          throw Exception('Error al crear carpeta: ${responseCopy.statusCode}');
        }
      } catch (e) {
        print(e);
      }
    }
  }

  Future<bool> deleteFile(String path) async {
    var pathUri = PathUri.parse(path);
    try {
      var responseDelete = await client.webdav.delete(pathUri);
      if (responseDelete.statusCode == 204 ||
          responseDelete.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }
}
