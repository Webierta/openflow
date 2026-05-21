/*
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:nextcloud/files_sharing.dart';
import 'package:nextcloud/notes.dart';
import 'package:nextcloud/webdav.dart';
import 'package:printing/printing.dart';

import '../models/cuenta_nextcloud.dart';
import '../services/nextcloud_service.dart';
import '../theme/styles_app.dart';
import '../utils/extension_share.dart';
import '../utils/format_bytes.dart';
import '../utils/format_dates.dart';

class OpenFileScreen<T> extends StatefulWidget {
  final CuentaNextcloud cuenta;
  final T item; //final WebDavFile item;
  final String path;

  const OpenFileScreen({
    super.key,
    required this.cuenta,
    required this.item,
    required this.path,
  });

  @override
  State<OpenFileScreen> createState() => _OpenFileScreenState();
}

class _OpenFileScreenState extends State<OpenFileScreen> {
  late NextcloudService nextcloudService;
  Uint8List? bytesFile;
  bool loading = false;
  String? typeItem;
  String? nameItem;
  String? categoryItem;
  String? sizeItem;
  String? lastModifiedItem;
  String? pathItem;

  @override
  void initState() {
    nextcloudService = NextcloudService(cuenta: widget.cuenta);
    setType();
    super.initState();
  }

  void setType() {
    String? tipo;
    String? nombre;
    String? categoria;
    String? size;
    String? modificado;
    String? ruta;
    if (widget.item is WebDavFile) {
      final webDavFile = (widget.item as WebDavFile);
      tipo = webDavFile.mimeType;
      nombre = webDavFile.name;
      size = (webDavFile.size != null)
          ? FormatBytes.show(webDavFile.size!)
          : null;
      modificado = (webDavFile.lastModified != null)
          ? FormatDates.dateToString(date: webDavFile.lastModified!)
          : null;
      var dir = webDavFile.path.parent?.path;
      if (dir == null || dir.isEmpty) {
        ruta = 'Home';
      } else if (dir.isNotEmpty) {
        ruta = 'Home/${dir.substring(0, dir.length - 1)}';
      }
    } else if (widget.item is Share) {
      final share = (widget.item as Share);
      tipo = share.mimetype;
      nombre = share.name;
      var sizeShare = share.itemSize.toInt();
      size = FormatBytes.show(sizeShare);
      var modificadoShare = DateTime.fromMillisecondsSinceEpoch(share.stime);
      modificado = FormatDates.dateToString(date: modificadoShare);
      var dir = share.path;
      if (dir == null || dir.isEmpty || dir == '/' || dir == share.fileTarget) {
        ruta = 'Home';
      } else if (dir.isNotEmpty && dir.length > share.fileTarget.length) {
        ruta = dir.substring(1);
        ruta = ruta.substring(0, ruta.indexOf(share.fileTarget));
      }
    } else if (widget.item is Note) {
      print('ES NOTA');

      final note = (widget.item as Note);
      print(note.title);
      nombre = note.title;
      tipo = widget.path;
      print(tipo);
      categoria = note.category;
      ruta = nombre;
      var modificadoNote = DateTime.fromMillisecondsSinceEpoch(note.modified);
      modificado = FormatDates.dateToString(date: modificadoNote);
      //tipo = note.runtimeType.toString();
      //note.
      //print(note.toJson());
    } else {
      tipo = null;
      nombre = null;
    }
    if (tipo == null || nombre == null) return;
    setState(() {
      loading = true;
      typeItem = tipo;
      nameItem = nombre;
      categoryItem = categoria;
      sizeItem = size;
      lastModifiedItem = modificado;
      pathItem = ruta;
    });
    if (widget.item is Note) {
      readNote();
    } else {
      readFile();
    }
  }

  void readNote() {
    final note = (widget.item as Note);
    try {
      List<int> bytes = utf8.encode(note.content);
      setState(() {
        bytesFile = Uint8List.fromList(bytes);
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> readFile() async {
    try {
      final responseBytes = await nextcloudService.readFileBytes(widget.path);
      if (responseBytes != null) {
        setState(() => bytesFile = responseBytes);
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => loading = false);
    }
  }

  void showInfo(BuildContext context) {
    showModalBottomSheet<void>(
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      context: context,
      builder: (BuildContext context) {
        */
/*final Map<String, String> detalles = widget.item.showInfo(
          widget.cuenta.userName,
        );*/ /*

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
              children: [
                Center(
                  child: Text(
                    nameItem ?? '', //  widget.item.getName(),
                    style: TextStyle(fontSize: 22),
                  ),
                ),
                if (categoryItem != null && categoryItem!.trim().isNotEmpty)
                  ListTile(
                    title: Text(categoryItem!),
                    subtitle: Text('Category'),
                  ),
                if (typeItem != null)
                  ListTile(title: Text(typeItem!), subtitle: Text('Type File')),
                if (sizeItem != null)
                  ListTile(title: Text(sizeItem!), subtitle: Text('Size')),
                if (lastModifiedItem != null)
                  ListTile(
                    title: Text(lastModifiedItem!),
                    subtitle: Text('Last Modified'),
                  ),
                if (pathItem != null)
                  ListTile(title: Text(pathItem!), subtitle: Text('Path')),
                */
/*if (detalles.isNotEmpty)
                  for (String key in detalles.keys)
                    ListTile(title: Text(detalles[key]!), subtitle: Text(key)),*/ /*

              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildBody() {
    if (typeItem == null) {
      return Center(child: Text('Formato de archivo no encontrado'));
    }
    if (bytesFile == null) {
      return Center(child: Text('Error de lectura del archivo'));
    }
    if (typeItem!.startsWith('image/')) {
      return Center(
        child: Column(children: [Expanded(child: Image.memory(bytesFile!))]),
      );
    }
    if (typeItem!.startsWith('text/plain')) {
      return SingleChildScrollView(
        padding: .all(40),
        child: Text(utf8.decode(bytesFile!)),
      );
    }
    if (typeItem!.startsWith('application/pdf')) {
      return PdfPreview(
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        build: (format) => bytesFile!,
      );
    }
    if (typeItem!.startsWith('text/markdown')) {
      return MarkdownWidget(
        data: utf8.decode(bytesFile!),
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
        appBar: AppBar(title: Text(nameItem ?? 'N/D')),
        body: loading == true
            ? Center(child: CircularProgressIndicator())
            : buildBody(),
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
              IconButton(
                onPressed: null,
                */
/*onPressed: () => downloadFile(
                  context: context,
                  cuenta: widget.cuenta,
                  file: widget.file,
                ),*/ /*

                icon: Icon(Icons.download),
              ),
              IconButton(
                onPressed: () {
                  //shareFile();
                },
                icon: Icon(Icons.share),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
