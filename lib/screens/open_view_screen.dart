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

class OpenViewScreen<T> extends StatefulWidget {
  final CuentaNextcloud cuenta;
  final T item;

  const OpenViewScreen({super.key, required this.cuenta, required this.item});

  @override
  State<OpenViewScreen> createState() => _OpenViewScreenState();
}

class _OpenViewScreenState extends State<OpenViewScreen> {
  late NextcloudService nextcloudService;
  bool loading = false;
  String? itemName;
  String? itemType;
  Uint8List? bytesFile;
  String? txtContent;

  @override
  void initState() {
    nextcloudService = NextcloudService(cuenta: widget.cuenta);
    setInit();
    super.initState();
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
      final note = (widget.item as Note);
      setState(() {
        itemName = note.title;
      });
    }
    print(itemName);
    print(itemType);
  }

  Future<void> readBytes() async {
    String? path;
    if (widget.item is WebDavFile) {
      final webDabFile = (widget.item as WebDavFile);
      path = webDabFile.path.parent!.path + webDabFile.name;
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
    String ruta = 'Home';
    var dir = webDavFile.path.parent?.path;
    if (dir == null || dir.isEmpty) {
      ruta = 'Home';
    } else if (dir.isNotEmpty) {
      ruta = 'Home/${dir.substring(0, dir.length - 1)}';
    }
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
      ListTile(title: Text(ruta), subtitle: Text('Path')),
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
    final note = (widget.item as Note);
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

  Widget buildBody() {
    if (loading == true) {
      return Center(child: CircularProgressIndicator());
    }
    if (widget.item is Note) {
      final note = (widget.item as Note);
      return MarkdownWidget(
        data: note.content,
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
      /*try {
        return SingleChildScrollView(
          padding: .all(40),
          child: Text(note.content),
        );
      } catch (e) {
        return Center(child: Text('Error de lectura de archivo'));
      }*/
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
        appBar: AppBar(title: Text(itemName ?? 'N/D')),
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
              IconButton(
                onPressed: null,
                /*onPressed: () => downloadFile(
                  context: context,
                  cuenta: widget.cuenta,
                  file: widget.file,
                ),*/
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
