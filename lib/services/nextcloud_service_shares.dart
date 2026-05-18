part of 'nextcloud_service.dart';

extension NextcloudServiceShares on NextcloudService {
  Future<BuiltList<Share>?>? getShares() async {
    try {
      final responseShares = await client.filesSharing.shareapi.getShares();
      return responseShares.body.ocs.data;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<bool> unshareFile(String id) async {
    try {
      final responseDelete = await client.filesSharing.shareapi.deleteShare(
        id: id,
      );
      if (responseDelete.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<(bool, String)> shareFile({
    required String path,
    int? shareType = 3, // 3 = enlace público
    int? permissions = 1, // 1 = solo lectura, 3 = lectura y escritur
    int? expireDays = 7, // Opcional: días hasta que el enlace expire
    String? password, // Opcional: contraseña para el enlace
  }) async {
    Map<String, dynamic> json = {
      'path': path,
      'shareType': shareType,
      'permissions': permissions,
    };
    try {
      final responseShare = await client.filesSharing.shareapi.createShare(
        $body: ShareapiCreateShareRequestApplicationJson.fromJson(json),
      );
      if (responseShare.statusCode == 200) {
        var sharedUrl = responseShare.body.ocs.data.url;
        if (sharedUrl != null) {
          return (true, sharedUrl);
        } else {
          throw Exception('Error al compartir archivo: NO LINK');
        }
      } else {
        throw Exception(
          'Error al compartir archivo: ${responseShare.statusCode}',
        );
      }
    } catch (e) {
      print(e);
      return (false, '');
    }
  }

  Future<bool> isFileShared(String path) async {
    try {
      final responseShare = await client.filesSharing.shareapi.getShares(
        path: path,
      );
      return responseShare.body.ocs.data.isNotEmpty;
    } catch (e) {
      print('Error checking if file is shared: $e');
      return false;
    }
  }

  Future<String?>? getIdShare(String path) async {
    try {
      final responseShare = await client.filesSharing.shareapi.getShares(
        path: path,
      );
      if (responseShare.body.ocs.data.isNotEmpty) {
        return responseShare.body.ocs.data.first.id;
      } else {
        throw Error();
      }
    } catch (e) {
      print('Error checking if file is shared: $e');
      return null;
    }
  }
}
