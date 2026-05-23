import 'package:nextcloud/notes.dart';

extension ExtensionNote on Note {
  String getNameWithExt({required Settings settings}) {
    String fileSuffix = settings.fileSuffix;
    return '$title$fileSuffix';
  }

  String getPath({required Settings settings}) {
    String notesPath = settings.notesPath;
    String fileSuffix = settings.fileSuffix;
    String path = '/$notesPath/$title$fileSuffix';
    if (category.isNotEmpty) {
      path = '/$notesPath/$category/$title$fileSuffix';
    }
    return path;
  }

  //String toJson({required Settings settings}) => jsonEncode(settings);

  //Settings toSettings(String json) => jsonDecode(json);
}

/*extension ExtensionSettings on Settings {
  // {"notesPath":"Notes","fileSuffix":".md","noteMode":"rich"}

  Settings fromDataJson(Map<String, dynamic> jsonData) {
    return Settings.fromJson(jsonData);
  }

  static Map<String, dynamic> toMap(Settings settings) => <String, dynamic>{
    'notesPath': settings.notesPath,
    'fileSuffix': settings.fileSuffix,
    'noteMode': settings.noteMode.name,
  };

  static String serialize(Settings settings) => json.encode(toMap(settings));

  static Settings deserialize(String json) =>
      Settings().fromDataJson(jsonDecode(json));
}*/
