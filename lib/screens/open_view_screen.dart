import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:nextcloud/files_sharing.dart';
import 'package:nextcloud/notes.dart';
import 'package:nextcloud/webdav.dart';
import 'package:openflow/screens/notes_screen.dart';
import 'package:openflow/screens/shared_screen.dart';
import 'package:openflow/utils/extension_webdavfile.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../models/cuenta_nextcloud.dart';
import '../services/nextcloud_service.dart';
import '../services/secure_storage_service.dart';
import '../theme/styles_app.dart';
import '../utils/extension_note.dart';
import '../utils/extension_share.dart';
import '../utils/format_bytes.dart';
import '../utils/format_dates.dart';
import '../widgets/snackbar_manager.dart';

class OpenViewScreen<T> extends StatefulWidget {
  final CuentaNextcloud cuenta;
  final T item;

  const OpenViewScreen({super.key, required this.cuenta, required this.item});

  @override
  State<OpenViewScreen> createState() => _OpenViewScreenState();
}

class _OpenViewScreenState extends State<OpenViewScreen> {
  late NextcloudService nextcloudService;
  final storageServiceGeneral = SecureStorageService('general');
  bool loading = false;
  String? itemName;
  String? itemType;
  Uint8List? bytesFile;
  String? txtContent;
  Note? nota;

  TextEditingController controllerNote = TextEditingController();
  bool modeEdit = false;

  @override
  void initState() {
    nextcloudService = NextcloudService(cuenta: widget.cuenta);
    setInit();
    super.initState();
  }

  @override
  void dispose() {
    controllerNote.dispose();
    super.dispose();
  }

  void setInit() {
    if (widget.item is WebDavFile) {
      setState(() {
        itemName = (widget.item as WebDavFile).name;
        itemType = (widget.item as WebDavFile).mimeType;
        loading = true;
      });
      readBytes();
    } else if (widget.item is Share) {
      setState(() {
        itemName = (widget.item as Share).fileTarget;
        itemType = (widget.item as Share).mimetype;
        loading = true;
      });
      readBytes();
    } else if (widget.item is Note) {
      final note = nota ?? (widget.item as Note);
      setState(() {
        itemName = note.title;
        txtContent = note.content;
        bytesFile = utf8.encode(note.content);
        controllerNote.text = note.content;
      });
    }
  }

  Future<void> readBytes() async {
    String? path;
    if (widget.item is WebDavFile) {
      final webDavFile = (widget.item as WebDavFile);
      path = webDavFile.path.parent!.path + webDavFile.name;
    } else if (widget.item is Share) {
      final share = (widget.item as Share);
      path = share.path;
    }
    if (path == null) return;
    try {
      final responseBytes = await nextcloudService.readFileBytes(path);
      if (responseBytes != null) {
        setState(() => bytesFile = responseBytes);
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => loading = false);
    }
  }

  List<Widget> buildDetalles() {
    if (widget.item is WebDavFile) return buildDetallesWebDavFile();
    if (widget.item is Share) return buildDetallesShare();
    if (widget.item is Note) return buildDetallesNote();
    return [Text('Error: datos no reconocidos')];
  }

  List<Widget> buildDetallesWebDavFile() {
    final webDavFile = (widget.item as WebDavFile);
    /*String ruta = 'Home';
    var dir = webDavFile.path.parent?.path;
    if (dir == null || dir.isEmpty) {
      ruta = 'Home';
    } else if (dir.isNotEmpty) {
      ruta = 'Home/${dir.substring(0, dir.length - 1)}';
    }*/
    return [
      Center(child: Text(webDavFile.name, style: TextStyle(fontSize: 22))),
      ListTile(
        title: Text(webDavFile.mimeType ?? 'N/D'),
        subtitle: Text('Type File'),
      ),
      if (webDavFile.size != null)
        ListTile(
          title: Text(FormatBytes.show(webDavFile.size!)),
          subtitle: Text('Size'),
        ),
      if (webDavFile.lastModified != null)
        ListTile(
          title: Text(FormatDates.dateToString(date: webDavFile.lastModified!)),
          subtitle: Text('Last Modified'),
        ),
      ListTile(title: Text(webDavFile.ruta()), subtitle: Text('Path')),
    ];
  }

  List<Widget> buildDetallesShare() {
    final share = (widget.item as Share);
    var modificadoShare = DateTime.fromMillisecondsSinceEpoch(share.stime);
    String ruta = 'Home';
    var dir = share.path;
    if (dir == null || dir.isEmpty || dir == '/' || dir == share.fileTarget) {
      ruta = 'Home';
    } else if (dir.isNotEmpty && dir.length > share.fileTarget.length) {
      ruta = dir.substring(1);
      ruta = ruta.substring(0, ruta.indexOf(share.fileTarget));
    }
    return [
      Center(child: Text(share.name, style: TextStyle(fontSize: 22))),
      ListTile(title: Text(share.mimetype), subtitle: Text('Type File')),
      ListTile(
        title: Text(FormatBytes.show(share.itemSize.toInt())),
        subtitle: Text('Size'),
      ),
      ListTile(
        title: Text(FormatDates.dateToString(date: modificadoShare)),
        subtitle: Text('Last Modified'),
      ),
      ListTile(title: Text(ruta), subtitle: Text('Path')),
    ];
  }

  List<Widget> buildDetallesNote() {
    final note = nota ?? (widget.item as Note);
    String categoria = note.category;
    if (categoria.isEmpty) {
      categoria = 'Ninguna';
    }
    var modificadoNote = DateTime.fromMillisecondsSinceEpoch(note.modified);
    List<int> bytes = utf8.encode(note.content);
    var uint = Uint8List.fromList(bytes);
    var size = uint.lengthInBytes;
    return [
      Center(child: Text(note.title, style: TextStyle(fontSize: 22))),
      //ListTile(title: Text(note.mimetype), subtitle: Text('Type File')),
      ListTile(title: Text(categoria), subtitle: Text('Category')),
      ListTile(title: Text(FormatBytes.show(size)), subtitle: Text('Size')),
      ListTile(
        title: Text(FormatDates.dateToString(date: modificadoNote)),
        subtitle: Text('Last Modified'),
      ),
    ];
  }

  void showInfo(BuildContext context) {
    showModalBottomSheet<void>(
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          //height: 200,
          width: double.infinity,
          child: SingleChildScrollView(
            padding: .only(bottom: 40),
            child: Column(
              //mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: .start,
              mainAxisSize: MainAxisSize.min,
              children: buildDetalles(),
            ),
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

  Future<void> downloadFile() async {
    if (itemName == null) {
      showError(msg: 'Error de acceso al nombre del archivo');
      return;
    }
    if (bytesFile == null) {
      showError(msg: 'Error de lectura del archivo');
      return;
    }
    final Directory? downloadsDir = await getDownloadsDirectory();
    if (downloadsDir == null) {
      showError(msg: 'Error de acceso a la carpeta de descargas');
      return;
    }
    final file = File('${downloadsDir.path}/$itemName');
    try {
      await file.writeAsBytes(bytesFile!);
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

  Future<void> unShareItem() async {
    if (widget.item is Share) {
      final share = (widget.item as Share);
      var unShareResponse = await nextcloudService.unshareFile(share.id);
      if (unShareResponse == true && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => SharedScreen(cuenta: widget.cuenta),
          ),
        );
        SnackbarManager.show(
          context: context,
          msg: unShareResponse == true
              ? 'El archivo ha dejado de estar compartido'
              : 'Error al dejar de compartir',
          error: unShareResponse == false,
        );
      }
    }
  }

  Future<void> sharePath(String path) async {
    final responseShare = await nextcloudService.shareFile(path: path);
    if (responseShare.$1 == true) {
      await Clipboard.setData(ClipboardData(text: responseShare.$2));
      //initNotes();
      //setState(() {});
    }
    if (!mounted) return;
    SnackbarManager.show(
      context: context,
      msg: responseShare.$1 == true
          ? 'Shared link copied to clipboard'
          : 'Error al compartir.',
      error: !responseShare.$1,
    );
  }

  Future<void> shareItem() async {
    if (widget.item is Note) {
      final note = nota ?? (widget.item as Note);
      Settings? settingsNote;
      try {
        final String? settingsStore = await storageServiceGeneral
            .getNotesSettings(nameCuenta: widget.cuenta.name);
        if (settingsStore != null) {
          settingsNote = Settings.fromJson(jsonDecode(settingsStore));
        } else {
          final responseSettings = await nextcloudService.client.notes
              .getSettings();
          settingsNote = responseSettings.body;
        }
        String path = note.getPath(settings: settingsNote);
        final isShare = await nextcloudService.isFileShared(path);
        if (isShare == true) {
          if (!mounted) return;
          SnackbarManager.show(
            context: context,
            msg: 'Nada que hacer: Esta nota ya está compartida.',
            error: true,
          );
        } else {
          sharePath(path);
        }
      } catch (e) {
        if (!mounted) return;
        SnackbarManager.show(
          context: context,
          msg: 'Error al compartir. Comprueba la extensión del archivo.',
          error: true,
        );
      }
    } else if (widget.item is WebDavFile) {
      final webDavFile = (widget.item as WebDavFile);
      String path = webDavFile.path.parent!.path + webDavFile.name;
      final isShare = await nextcloudService.isFileShared(path);
      if (isShare == true) {
        if (!mounted) return;
        SnackbarManager.show(
          context: context,
          msg: 'Nada que hacer: este archivo ya está compartido.',
          error: true,
        );
      } else {
        sharePath(path);
      }
    }
  }

  Widget buildBody() {
    if (loading == true) {
      return Center(child: CircularProgressIndicator());
    }
    if (widget.item is Note) {
      final note = nota ?? (widget.item as Note);
      if (modeEdit == true) {
        return SingleChildScrollView(
          padding: .all(40),
          child: TextField(
            controller: controllerNote,
            //readOnly: note.id == null,
            maxLines: null,
            decoration: InputDecoration.collapsed(
              hintText: '',
              border: InputBorder.none,
            ),
          ),
        );
      }
      return MarkdownWidget(
        data: note.content,
        padding: .all(40),
        selectable: true,
        config: MarkdownConfig(
          configs: [
            PreConfig.darkConfig,
            LinkConfig(style: TextStyle(color: Colors.yellow)),
            CodeConfig(
              style: TextStyle(
                color: Colors.black,
                backgroundColor: Colors.grey,
              ),
            ),
            ListConfig(marginBottom: 0),
            BlockquoteConfig(textColor: Colors.white54),
          ],
        ),
      );
    }
    if (itemType == null) {
      return Center(child: Text('Formato de archivo no encontrado'));
    }
    if (itemType!.startsWith('image/') && bytesFile != null) {
      return Center(
        child: Column(children: [Expanded(child: Image.memory(bytesFile!))]),
      );
    }
    if (itemType!.startsWith('text/plain')) {
      String? data;
      if (bytesFile != null) {
        data = utf8.decode(bytesFile!);
      }
      if (txtContent != null) {
        data = txtContent!;
      }
      if (data == null) {
        return Center(child: Text('Error de lectura de archivo'));
      }
      return SingleChildScrollView(padding: .all(40), child: Text(data));
    }
    if (itemType!.startsWith('application/pdf')) {
      return PdfPreview(
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        build: (format) => bytesFile!,
      );
    }
    if (itemType!.startsWith('text/markdown')) {
      String? data;
      if (bytesFile != null) {
        data = utf8.decode(bytesFile!);
      }
      if (txtContent != null) {
        data = txtContent!;
      }
      if (data == null) {
        return Center(child: Text('Error de lectura de archivo'));
      }
      return MarkdownWidget(
        data: data,
        padding: .all(40),
        config: MarkdownConfig(
          configs: [
            PreConfig.darkConfig,
            LinkConfig(style: TextStyle(color: Colors.yellow)),
            CodeConfig(
              style: TextStyle(
                color: Colors.black,
                backgroundColor: Colors.grey,
              ),
            ),
            ListConfig(marginBottom: 0),
            BlockquoteConfig(textColor: Colors.white54),
          ],
        ),
      );
    }
    // Ofrecer preview o tumb
    return Center(child: Text('Formato de archivo no reconocido'));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: StylesApp.gradient(Theme.of(context).colorScheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              if (widget.item is Note && nota != null) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => NotesScreen(cuenta: widget.cuenta),
                  ),
                );
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: Icon(Icons.arrow_back),
          ),
          title: Text(itemName ?? 'N/D'),
          actions: [
            if (widget.item is Note && modeEdit == true)
              IconButton(
                onPressed: () async {
                  setState(() => loading = true);

                  final updateNote = await nextcloudService.updateNote(
                    note: (widget.item as Note),
                    content: controllerNote.text,
                  );
                  if (updateNote == true) {
                    final notaNew = await nextcloudService.getNota(
                      id: (widget.item as Note).id,
                    );
                    if (notaNew != null) {
                      setState(() {
                        nota = notaNew;
                      });
                      //ACTUALIZAR NOTA A NUEVA NOTA
                    }
                  }
                  setState(() {
                    loading = false;
                    modeEdit = false;
                  });
                  if (!context.mounted) return;
                  //Navigator.of(context).pop();
                  SnackbarManager.show(
                    context: context,
                    msg: updateNote == true
                        ? 'Note changed successfully!'
                        : 'Failed to update note',
                    error: updateNote != true,
                  );
                },
                icon: Icon(Icons.save, color: Colors.white),
              ),
            if ((widget.item is Note) && modeEdit == false)
              IconButton(
                onPressed: () {
                  setState(() => modeEdit = true);
                },
                icon: Icon(Icons.edit, color: Colors.white),
              ),
          ],
        ),
        body: buildBody(),
        bottomNavigationBar: BottomAppBar(
          height: 45,
          color: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.only(left: 14),
          child: Row(
            children: [
              IconButton(
                onPressed: () => showInfo(context),
                icon: const Icon(Icons.info),
              ),
              IconButton(onPressed: downloadFile, icon: Icon(Icons.download)),
              widget.item is Share
                  ? IconButton(
                      onPressed: unShareItem,
                      icon: Icon(Icons.link_off),
                    )
                  : IconButton(
                      onPressed: shareItem,
                      icon: Icon(Icons.add_link),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
