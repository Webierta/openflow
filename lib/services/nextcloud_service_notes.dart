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

  int boolToInt(bool a) => a ? 1 : 0;

  Future<bool> updateNote({
    required Note note,
    String? title,
    String? content,
    String? category,
    bool? isFavorite,
  }) async {
    int? favorite;
    if (isFavorite != null) {
      favorite = boolToInt(isFavorite);
    }
    try {
      final responseUpdate = await client.notes.updateNote(
        id: note.id,
        title: title ?? note.title,
        content: content ?? note.content,
        category: category ?? note.category,
        favorite: favorite ?? boolToInt(note.favorite),
      );
      if (responseUpdate.statusCode == 200) {
        return true;
      } else {
        throw Error();
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<Settings> getSettings() async {
    final response = await client.notes.getSettings();
    return response.body;
  }

  Future<bool> deleteNote(Note note) async {
    try {
      final responseDelete = await client.notes.deleteNote(id: note.id);
      if (responseDelete.statusCode == 200) {
        return true;
      } else {
        throw Error();
      }
    } catch (e) {
      print(e);
      return false;
    }
  }
}
