import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nextcloud/notes.dart';
import 'package:path_provider/path_provider.dart';

import '../models/cuenta_nextcloud.dart';
import '../models/destino.dart';
import '../services/nextcloud_service.dart';
import '../services/secure_storage_service.dart';
import '../theme/styles_app.dart';
import '../utils/extension_note.dart';
import '../widgets/bottom_bar_app.dart';
import '../widgets/open_dialog.dart';
import '../widgets/snackbar_manager.dart';
import 'open_view_screen.dart';

class NotesScreen extends StatefulWidget {
  final CuentaNextcloud cuenta;

  const NotesScreen({super.key, required this.cuenta});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late NextcloudService nextcloudService;
  late Settings settings;
  final storageServiceGeneral = SecureStorageService('general');
  List<Note> notesApi = [];
  List<Note> notes = [];
  String? category;
  Set<String> categorias = {''};
  Map mapCategories = {};
  String dropdownValue = '';
  bool filterFavorites = false;
  bool isLoading = false;
  bool isGridView = false;

  //Map<Note, CloudFile> mapFiles = {};
  int totalNotes = 0;

  TextEditingController inputController = TextEditingController();

  @override
  void initState() {
    nextcloudService = NextcloudService(cuenta: widget.cuenta);
    getSettings();
    dropdownValue = categorias.first;
    initNotes();
    super.initState();
  }

  Future<void> getSettings() async {
    final responseSettings = await nextcloudService.client.notes.getSettings();
    Settings settingsNote = responseSettings.body;

    await storageServiceGeneral.saveNotesSettings(
      nameCuenta: widget.cuenta.name,
      settings: settingsNote,
      //settings: settingsNote.toJsonString(),
    );
    //print(jsonEncode(settingsNote));
    setState(() => settings = settingsNote);
  }

  @override
  void dispose() {
    //nextcloudService.client.close();
    inputController.dispose();
    super.dispose();
  }

  Future<void> initNotes() async {
    setState(() => isLoading = true);
    final responseNotes = await nextcloudService.getNotas();
    if (responseNotes == null) return;
    final List<Note> myNotes = List.from(responseNotes);
    myNotes.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    List<String> countCategorias = [];
    for (var note in myNotes) {
      if (note.category.isNotEmpty) {
        countCategorias.add(note.category);
        categorias.add(note.category);
      }
    }
    var map = {};
    for (var cat in countCategorias) {
      if (!map.containsKey(cat)) {
        map[cat] = 1;
      } else {
        map[cat] += 1;
      }
    }
    setState(() {
      notesApi = myNotes;
      notes = myNotes;
      mapCategories = map;
      isLoading = false;
    });
  }

  String removeFrom(String s, String marker) {
    final idx = s.indexOf(marker);
    return idx == -1 ? s : s.substring(0, idx);
  }

  Future<void> onTapNote(Note note) async {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            OpenViewScreen<Note>(cuenta: widget.cuenta, item: note),
      ),
    );
    return;
  }

  Future<bool> checkShare(Note note) async {
    String path = note.getPath(settings: settings);
    return await nextcloudService.isFileShared(path);
  }

  Future<void> shareNote(Note note) async {
    String path = note.getPath(settings: settings);
    final responseShare = await nextcloudService.shareFile(path: path);
    if (responseShare.$1 == true) {
      await Clipboard.setData(ClipboardData(text: responseShare.$2));
      initNotes();
    }
    if (!mounted) return;
    SnackbarManager.show(
      context: context,
      msg: responseShare.$1 == true
          ? 'Shared link copied to clipboard'
          : 'Error al dejar de compartir. Comprueba que la extensión del archivo ',
      error: !responseShare.$1,
    );
  }

  Future<void> unShareNote(Note note) async {
    String path = note.getPath(settings: settings);
    final responseId = await nextcloudService.getIdShare(path);
    if (responseId == null) return;
    final responseUnshare = await nextcloudService.unshareFile(responseId);
    if (!mounted) return;
    SnackbarManager.show(
      context: context,
      msg: responseUnshare == true
          ? 'El archivo ha dejado de ser compartido'
          : 'Error al dejar de compartir. Comprueba que la extensión del archivo ',
      error: responseUnshare != true,
    );
  }

  Future<void> updateNote({
    required Note note,
    String? title,
    String? content,
    String? category,
    bool? isFavorite,
  }) async {
    final responseUpdate = await nextcloudService.updateNote(
      note: note,
      title: title,
      content: content,
      category: category,
      isFavorite: isFavorite,
    );
    if (responseUpdate == true) initNotes();
    if (mounted) {
      SnackbarManager.show(
        context: context,
        msg: responseUpdate == true ? 'Note update!' : 'Failed to updated note',
        error: responseUpdate != true,
      );
    }
  }

  Future<void> deleteNote(Note note) async {
    final confirmation = await OpenDialog.confirm(
      context: context,
      title: 'Confirmación requerida',
      content: Text('Elimina esta nota:\n${note.title}'),
    );
    if (confirmation == true) {
      var deleteNote = await nextcloudService.deleteNote(note);
      if (deleteNote == true) initNotes();
      if (mounted) {
        SnackbarManager.show(
          context: context,
          msg: deleteNote == true ? 'Note deleted' : 'Error',
          error: deleteNote != true,
        );
      }
    }
  }

  Future<void> onTapMore(Note note) async {
    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: false,
      scrollControlDisabledMaxHeightRatio: 0.7,
      barrierColor: Colors.white70,
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      context: context,
      constraints: BoxConstraints(maxWidth: double.infinity),
      builder: (BuildContext contextBottomSheet) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: ListView(
            children: [
              Center(child: Text(note.title, style: TextStyle(fontSize: 22))),
              Divider(),
              Column(
                mainAxisSize: .min,
                children: [
                  ListTile(
                    leading: Icon(Icons.download),
                    title: Text('Download'),
                    onTap: () {
                      Navigator.pop(contextBottomSheet);
                      //downloadNote(note);
                    },
                  ),
                  FutureBuilder(
                    future: checkShare(note),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ListTile(
                          leading: Icon(
                            snapshot.data == false
                                ? Icons.add_link
                                : Icons.link_off,
                          ),
                          title: Text(
                            snapshot.data == false
                                ? 'Share link'
                                : 'Unshare Note',
                          ),
                          onTap: () {
                            Navigator.pop(contextBottomSheet);
                            snapshot.data == false
                                ? shareNote(note)
                                : unShareNote(note);
                          },
                        );
                      } else if (snapshot.hasError) {
                        return ListTile(
                          leading: Icon(Icons.link),
                          title: Text('Error checking if the file is shared'),
                        );
                      } else {
                        return ListTile(
                          leading: Icon(Icons.link),
                          title: Text('Checking if the file is shared...'),
                        );
                      }
                    },
                  ),
                  /*ListTile(
                    leading: Icon(Icons.link),
                    title: Text('Share link'),
                    onTap: () {
                      Navigator.pop(contextBottomSheet);
                      //sharedNote(note);
                    },
                  ),*/
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.drive_file_rename_outline),
                    title: Text('Rename'),
                    subtitle: Text('Solo formatos .md y .txt'),
                    onTap: () async {
                      Navigator.pop(contextBottomSheet);
                      var newName = await OpenDialog.inputName(
                        context: context,
                        title: 'Input new name for this note',
                        icon: Icons.edit,
                        controller: inputController,
                      );
                      if (newName == null) return;
                      updateNote(note: note, title: newName);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.category),
                    title: Text('Change Category'),
                    onTap: () async {
                      Navigator.pop(contextBottomSheet);
                      String? newCategory = await showDialog<String>(
                        context: context,
                        builder: (BuildContext context) {
                          inputController.text = note.category;
                          var width = MediaQuery.of(context).size.width;
                          return SimpleDialog(
                            contentPadding: .symmetric(horizontal: 24),
                            //insetPadding: EdgeInsets.zero,
                            //contentPadding: EdgeInsets.zero,
                            //clipBehavior: Clip.antiAliasWithSaveLayer,
                            title: Row(
                              mainAxisAlignment: .spaceBetween,
                              children: [
                                const Text('New category'),
                                IconButton(
                                  tooltip: 'Salir sin guardar',
                                  onPressed: () {
                                    Navigator.pop(context, null);
                                  },
                                  icon: CircleAvatar(child: Icon(Icons.close)),
                                ),
                              ],
                            ),
                            children: [
                              SizedBox(height: 14, width: width),
                              Card(
                                child: ListTile(
                                  leading: Icon(Icons.category, size: 42),
                                  title: TextField(controller: inputController),
                                  subtitle: Text('Categoría seleccionada'),
                                  trailing: IconButton(
                                    tooltip: 'Guardar',
                                    onPressed: () {
                                      Navigator.pop(
                                        context,
                                        inputController.text,
                                      );
                                    },
                                    icon: Icon(
                                      Icons.save,
                                      size: 42,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              for (final cat in categorias)
                                SimpleDialogOption(
                                  onPressed: () {
                                    inputController.text = cat;
                                  },
                                  child: cat.isEmpty
                                      ? Text('Ninguna')
                                      : Text(cat),
                                ),
                            ],
                          );
                        },
                      );
                      inputController.clear();
                      if (newCategory != null && note.category != newCategory) {
                        await updateNote(note: note, category: newCategory);
                      }
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Delete'),
                    onTap: () {
                      Navigator.pop(contextBottomSheet);
                      deleteNote(note);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void showError({String msg = 'Error de descarga'}) {
    SnackbarManager.show(
      context: context,
      msg: 'Error de descarga',
      error: true,
    );
  }

  Future<void> downloadNote(Note note) async {
    final Directory? downloadsDir = await getDownloadsDirectory();
    if (downloadsDir == null) {
      showError(msg: 'Error de acceso a la carpeta de descargas');
      return;
    }
    final file = File('${downloadsDir.path}/${note.title}');
    final bytesFile = utf8.encode(note.content);

    try {
      await file.writeAsBytes(bytesFile);
      if (mounted) {
        SnackbarManager.show(
          context: context,
          msg: 'File downloaded to downloads directory',
        );
      }
    } catch (e) {
      showError();
    }
  }

  Future<void> newNote() async {
    var noteName = await OpenDialog.inputName(
      context: context,
      title: 'Input note name',
      icon: Icons.note_add,
      controller: inputController,
    );
    if (noteName == null) return;
    inputController.clear();
    final responseNewNote = await nextcloudService.addNote(title: noteName);
    if (responseNewNote != null) {
      if (mounted) {
        SnackbarManager.show(context: context, msg: 'Add note successfully!');
      }
      initNotes();
      onTapNote(responseNewNote);
    } else {
      if (mounted) {
        SnackbarManager.show(
          context: context,
          msg: 'Add note failed',
          error: true,
        );
      }
    }
  }

  Widget filterCategory() {
    return Expanded(
      flex: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          //padding: EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: Colors.white30,
              style: BorderStyle.solid,
              width: 0.80,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: dropdownValue,
              //icon: const Icon(Icons.arrow_downward),
              icon: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(Icons.filter_alt_outlined, size: 32),
              ),
              elevation: 16,
              //style: const TextStyle(color: Colors.blueAccent),
              //underline: Container(height: 2, color: Colors.blueAccent),
              onChanged: (String? value) {
                setState(() {
                  category = value;
                  if (value == null || value.isEmpty) {
                    category = null;
                  }
                  dropdownValue = value!;
                });
              },
              items: categorias
                  .map<DropdownMenuItem<String>>(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: FittedBox(
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            CircleAvatar(
                              child: Text(
                                value.isEmpty
                                    //? '$totalNotes'
                                    ? '${notesApi.length}'
                                    : '${mapCategories[value]}',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(value.isEmpty ? 'All' : value),
                          ],
                        ),
                      ),
                      /*child: value.isEmpty
                          ? Text('All')
                          : FittedBox(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    child: Text('${mapCategories[value]}'),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(value),
                                ],
                              ),
                            ),*/
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> viewSettings() async {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Ajustes'),
          content: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              Text(
                'Ajustes generales utilizados por este servidor para Notas.',
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text(settings.notesPath),
                subtitle: Text('Directorio para notas.'),
              ),
              ListTile(
                title: Text(settings.fileSuffix),
                subtitle: Text(
                  'Extensión de archivo por defecto. Si utilizas otra extensión, '
                  'algunas funciones pueden no estar disponibles.',
                ),
              ),
              ListTile(
                title: Text(settings.noteMode.name),
                subtitle: Text('Note mode.'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (category != null) {
      notes = notesApi.where((note) => note.category == category).toList();
      if (filterFavorites == true) {
        notes = notes.where((note) => note.favorite == true).toList();
      }
    } else {
      notes = notesApi;
      if (filterFavorites == true) {
        notes = notes.where((note) => note.favorite == true).toList();
      }
    }

    return Container(
      decoration: StylesApp.backgroundScreen(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 40,
          leading: Padding(
            padding: const EdgeInsets.all(4.0),
            child: widget.cuenta.avatar != null
                ? Image.memory(widget.cuenta.avatar!, height: 30, width: 30)
                : Icon(Icons.person_off, size: 30, color: Colors.grey),
          ),
          title: const Text('Notes'),
          //title: Text('Notes: ${notesApi.length}'),
          actions: [
            IconButton(
              tooltip: 'Sort by name',
              onPressed: () {
                setState(() {
                  notes.sort(
                    (a, b) =>
                        a.title.toLowerCase().compareTo(b.title.toLowerCase()),
                  );
                });
              },
              icon: Icon(Icons.sort_by_alpha, size: 32, color: Colors.white),
            ),
            IconButton(
              tooltip: 'Sort by date',
              onPressed: () {
                setState(() {
                  notes.sort((a, b) => b.modified.compareTo(a.modified));
                });
              },
              icon: Icon(Icons.date_range, size: 32, color: Colors.white),
            ),
            IconButton(
              onPressed: () => setState(() => isGridView = !isGridView),
              icon: Icon(
                isGridView ? Icons.list : Icons.grid_view,
                size: 32,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: viewSettings,
              icon: Icon(
                Icons.settings_applications,
                size: 32,
                color: Colors.white,
              ),
            ),
          ],
          bottom: isLoading == false
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: Padding(
                    padding: .symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() => filterFavorites = !filterFavorites);
                          },
                          icon: Icon(
                            Icons.star,
                            size: 32,
                            color: filterFavorites == true
                                ? Colors.yellow
                                : Colors.grey,
                          ),
                        ),
                        //const SizedBox(width: 10),
                        const Spacer(),
                        filterCategory(),
                      ],
                    ),
                  ),
                )
              : null,
        ),
        bottomNavigationBar: BottomBarApp(
          cuenta: widget.cuenta,
          destino: Destino.notes,
          funcion: newNote,
          //cancelToken: nextcloudApi.cancelToken,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : notes.isEmpty
            ? Center(child: Text('Sin notas'))
            : LayoutBuilder(
                builder: (context, constraints) {
                  if (isGridView) {
                    int columns = (constraints.maxWidth / 200).floor();
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns, // Number of columns
                        crossAxisSpacing: 4, // Space between columns
                        mainAxisSpacing: 4, // Space between rows
                      ),
                      padding: .all(10),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        var note = notes[index];
                        return Card(
                          child: InkWell(
                            onTap: () => onTapNote(note),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: .spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        updateNote(
                                          note: note,
                                          isFavorite: !note.favorite,
                                        );
                                      },
                                      icon: Icon(
                                        Icons.star,
                                        color: note.favorite == true
                                            ? Colors.yellow
                                            : Colors.grey,
                                        size: 42,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => onTapMore(note),
                                      icon: Icon(Icons.more_vert),
                                    ),
                                  ],
                                ),
                                Spacer(flex: 1),
                                Text(note.title),
                                Spacer(flex: 2),
                                if (note.category.isNotEmpty)
                                  Container(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiaryContainer,
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Text(
                                      note.category,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    padding: .fromLTRB(4, 4, 4, 60),
                    itemCount: notes.length,
                    separatorBuilder: (context, index) {
                      return Divider(
                        color: Colors.white54,
                        thickness: 0.2,
                        indent: 20,
                        endIndent: 20,
                      );
                    },
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return ListTile(
                        onTap: () => onTapNote(note),
                        leading: IconButton(
                          onPressed: () {
                            //changeFavorite(note, !note.favorite);
                            updateNote(note: note, isFavorite: !note.favorite);
                          },
                          icon: Icon(
                            Icons.star,
                            color: note.favorite == true
                                ? Colors.yellow
                                : Colors.grey,
                            size: 42,
                          ),
                        ),
                        title: Text(note.title),
                        subtitle: note.category.isNotEmpty
                            ? Text(note.category)
                            : null,
                        trailing: IconButton(
                          onPressed: () => onTapMore(note),
                          icon: Icon(Icons.more_vert),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
