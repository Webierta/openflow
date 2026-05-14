import 'dart:typed_data';

import 'package:built_collection/built_collection.dart';
import 'package:nextcloud/core.dart';
import 'package:nextcloud/files.dart';
import 'package:nextcloud/files_sharing.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:nextcloud/notes.dart';
import 'package:nextcloud/provisioning_api.dart';
import 'package:nextcloud/webdav.dart';

import '../models/cuenta_nextcloud.dart';

class NextcloudService {
  final CuentaNextcloud cuenta;

  NextcloudService({required this.cuenta});

  NextcloudClient get client => NextcloudClient(
    Uri.parse(cuenta.server),
    loginName: cuenta.userName,
    password: cuenta.password,
  );

  Future<UserDetails?>? connect() async {
    try {
      final responseUser = await client.provisioningApi.users.getCurrentUser();
      return responseUser.body.ocs.data;
      /*final userDetails = responseUser.body.ocs.data;
      cuenta.userId = userDetails.id;
      cuenta.lastLogin = userDetails.lastLogin;
      var avatar = await getAvatar(userDetails.id);
      cuenta.statusAuth = StatusAuth.login;*/
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Uint8List?>? getAvatar(String userId) async {
    try {
      final responseAvatar = await client.core.avatar.getAvatar(
        userId: userId,
        size: AvatarGetAvatarSize.$64,
      );
      if (responseAvatar.statusCode == 200) {
        //cuenta.avatar = responseAvatar.body;
        return responseAvatar.body;
      } else {
        return null;
      }
    } on DynamiteStatusCodeException catch (_) {
      final responseAvatarGuest = await client.core.guestAvatar.getAvatar(
        guestName: userId,
        size: GuestAvatarGetAvatarSize.$64,
      );
      if (responseAvatarGuest.statusCode == 201) {
        //cuenta.avatar = responseAvatarGuest.body;
        return responseAvatarGuest.body;
      } else {
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  void disconnect() {
    cuenta.statusAuth = StatusAuth.logout;
    client.close();
  }

  Future<List<WebDavFile>?>? getFiles({String path = '/'}) async {
    final uri = PathUri.parse(path);
    try {
      final responseWebDav = await client.webdav.propfind(
        uri,
        depth: WebDavDepth.one,
      );
      return responseWebDav.toWebDavFiles();
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<BuiltList<Share>?>? getShares() async {
    try {
      final responseShares = await client.filesSharing.shareapi.getShares();
      return responseShares.body.ocs.data;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<BuiltList<Note>?>? getNotas() async {
    try {
      final responseNotes = await client.notes.getNotes();
      return responseNotes.body;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Uint8List?>? getPreview(String path) async {
    try {
      final responsePreview = await client.core.preview.getPreview(file: path);
      return responsePreview.body;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Uint8List?>? getThumbnail(String path) async {
    try {
      final responseThumbnail = await client.files.api.getThumbnail(
        x: 64,
        y: 64,
        file: path,
      );
      return responseThumbnail.body;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
