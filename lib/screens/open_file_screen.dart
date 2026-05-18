import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:nextcloud/files_sharing.dart';
import 'package:nextcloud/webdav.dart';
import 'package:printing/printing.dart';

import '../models/cuenta_nextcloud.dart';
import '../services/nextcloud_service.dart';
import '../theme/styles_app.dart';
import '../utils/extension_share.dart';

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

  @override
  void initState() {
    nextcloudService = NextcloudService(cuenta: widget.cuenta);
    setType();
    super.initState();
  }

  void setType() {
    String? tipo;
    String? nombre;
    if (widget.item is WebDavFile) {
      tipo = widget.item.mimeType;
      nombre = widget.item.name;
    } else if (widget.item is Share) {
      tipo = widget.item.mimetype;
      nombre = (widget.item as Share).name;
    } else {
      tipo = null;
      nombre = null;
    }
    if (tipo == null || nombre == null) return;
    setState(() {
      loading = true;
      typeItem = tipo;
      nameItem = nombre;
    });
    readFile();
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
        appBar: AppBar(title: Text(nameItem!)),
        body: loading == true
            ? Center(child: CircularProgressIndicator())
            : buildBody(),
      ),
    );
  }
}
