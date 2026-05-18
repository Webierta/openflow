part of 'nextcloud_service.dart';

extension NextcloudServiceNotes on NextcloudService {
  Future<BuiltList<Note>?>? getNotas() async {
    try {
      final responseNotes = await client.notes.getNotes();
      return responseNotes.body;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
