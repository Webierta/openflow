import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:nextcloud/webdav.dart';
import 'package:printing/printing.dart';

import '../models/cuenta_nextcloud.dart';
import '../services/nextcloud_service.dart';
import '../theme/styles_app.dart';

class OpenFileScreen extends StatefulWidget {
  final CuentaNextcloud cuenta;
  final WebDavFile item;
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

  @override
  void initState() {
    nextcloudService = NextcloudService(cuenta: widget.cuenta);
    loading = true;
    readFile();
    super.initState();
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
    if (widget.item.mimeType == null) {
      return Center(child: Text('Formato de archivo no encontrado'));
    }
    if (bytesFile == null) {
      return Center(child: Text('Error de lectura del archivo'));
    }
    if (widget.item.mimeType!.startsWith('image/')) {
      return Center(
        child: Column(children: [Expanded(child: Image.memory(bytesFile!))]),
      );
    }
    if (widget.item.mimeType!.startsWith('text/plain')) {
      return SingleChildScrollView(
        padding: .all(40),
        child: Text(utf8.decode(bytesFile!)),
      );
    }
    if (widget.item.mimeType!.startsWith('application/pdf')) {
      return PdfPreview(
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        build: (format) => bytesFile!,
      );
    }
    if (widget.item.mimeType!.startsWith('text/markdown')) {
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
        appBar: AppBar(title: Text(widget.item.name)),
        body: loading == true
            ? Center(child: CircularProgressIndicator())
            : buildBody(),
      ),
    );
  }
}
