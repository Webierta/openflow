import 'package:flutter/material.dart';
import 'package:nextcloud/webdav.dart';

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
  Widget body = Center(child: Text('Nada por aquí'));
  bool loading = false;

  @override
  void initState() {
    buildBody();
    super.initState();
  }

  Future<void> buildBody() async {
    String pathFile = widget.path;
    if (widget.item.path.parent?.path != null) {
      pathFile = widget.item.path.parent!.path + widget.item.name;
    }

    if (widget.item.mimeType != null &&
        widget.item.mimeType!.startsWith('image/')) {
      setState(() {
        loading = true;
      });
      final nextcloudService = NextcloudService(cuenta: widget.cuenta);

      try {
        final preview = await nextcloudService.getPreview(
          path: pathFile,
          x: -1,
          y: -1,
        );
        if (preview != null) {
          setState(() {
            body = Center(
              child: Column(
                children: [
                  Expanded(child: Image.memory(preview)),
                  Text(widget.path),
                  Text(pathFile),
                ],
              ),
            );
          });
        } else {
          setState(() {
            body = Center(child: Text('Error imagen'));
          });
        }
      } catch (e) {
        setState(() {
          body = Center(child: Text('Error imagen'));
        });
      } finally {
        setState(() {
          loading = false;
        });
      }
    } else {
      setState(() {
        body = Center(child: Text('No es imagen'));
      });
    }
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
            : body,
      ),
    );
  }
}
