import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nextcloud/webdav.dart';

import '../models/cuenta_nextcloud.dart';
import '../models/destino.dart';
import '../services/nextcloud_service.dart';
import '../theme/styles_app.dart';
import '../utils/format_dates.dart';
import '../widgets/bottom_bar_app.dart';
import 'open_file_screen.dart';

class GalleryScreen extends StatefulWidget {
  final CuentaNextcloud cuenta;
  final String pathGallery;

  const GalleryScreen({
    super.key,
    required this.cuenta,
    this.pathGallery = '/',
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late NextcloudService nextcloudService;
  StreamController<(WebDavFile, Uint8List)> streamController =
      StreamController<(WebDavFile, Uint8List)>();
  late StreamSubscription<(WebDavFile, Uint8List)> subscription;

  //final List<Uint8List> imagenes = [];
  //final List<WebDavFile> webDavFiles = [];
  Map<WebDavFile, Uint8List> galleryMap = {};

  //bool isLoading = false;

  @override
  void initState() {
    nextcloudService = NextcloudService(cuenta: widget.cuenta);
    initGallery();
    super.initState();
  }

  @override
  void dispose() {
    subscription.cancel();
    streamController.close();
    super.dispose();
  }

  void initGallery() async {
    streamController
        .addStream(
          nextcloudService.getGallery(path: widget.pathGallery),
          cancelOnError: true,
        )
        .whenComplete(() {
          streamController.close();
        });

    subscription = streamController.stream.listen(
      (data) {
        setState(() {
          //webDavFiles.add(data.$1);
          //imagenes.add(data.$2);
          //galleryMap = Map.fromIterables(webDavFiles, imagenes);
          galleryMap[data.$1] = data.$2;
        });
      },
      onError: (error) {
        print('Error: $error');
      },
      onDone: () {
        print('Stream closed: ${streamController.isClosed}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          title: Text('Gallery'),
          actions: [
            if (streamController.isClosed) ...[
              IconButton(
                tooltip: 'Sort by name',
                onPressed: () {
                  setState(() {
                    //imagesPreview.sort((a, b) => a.name.compareTo(b.name));
                    galleryMap = Map.fromEntries(
                      galleryMap.entries.toList()
                        ..sort((e1, e2) => e1.key.name.compareTo(e2.key.name)),
                    );
                  });
                },
                icon: Icon(Icons.sort_by_alpha, size: 32, color: Colors.white),
              ),
              IconButton(
                tooltip: 'Sort by date',
                onPressed: () {
                  setState(() {
                    galleryMap = Map.fromEntries(
                      galleryMap.entries.toList()..sort((e1, e2) {
                        final aDate = FormatDates.dateToString(
                          date: e1.key.lastModified!,
                        );
                        final bDate = FormatDates.dateToString(
                          date: e2.key.lastModified!,
                        );
                        return bDate.compareTo(aDate);
                      }),
                    );
                  });
                },
                icon: Icon(Icons.date_range, size: 32, color: Colors.white),
              ),
            ],
          ],
        ),
        bottomNavigationBar: BottomBarApp(
          cuenta: widget.cuenta,
          destino: Destino.gallery,
          //funcion: null, //uploadFile,
          //depth: depth,
          //cancelToken: nextcloudApi.cancelToken,
        ),
        body: !streamController.isPaused && galleryMap.isEmpty
            ? Center(child: CircularProgressIndicator())
            : streamController.isClosed && galleryMap.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: .center,
                  children: [
                    Icon(Icons.image_not_supported_outlined, size: 84),
                    const SizedBox(height: 42),
                    Text('No se han encontrado imágenes en el servidor'),
                  ],
                ),
              )
            : Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int columns = (constraints.maxWidth / 150).floor();
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 8.0,
                          crossAxisSpacing: 8.0,
                        ),
                        padding: EdgeInsets.all(12.0),
                        itemCount: galleryMap.length,
                        itemBuilder: (context, index) {
                          final webDavFile = galleryMap.keys.elementAt(index);
                          final image = galleryMap.values.elementAt(index);
                          //var image = galleryMap.values[index];
                          //var image = imagenes[index];
                          //var webDavFile = webDavFiles[index];
                          return Card(
                            color: Colors.white,
                            elevation: 4.0,
                            child: InkWell(
                              onTap: () {
                                var rutaFile =
                                    '${webDavFile.path.parent?.path}${webDavFile.name}';
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (context) =>
                                        OpenFileScreen<WebDavFile>(
                                          cuenta: widget.cuenta,
                                          item: webDavFile,
                                          path: rutaFile,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: MemoryImage(image),
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.all(
                                    const Radius.circular(10.0),
                                  ),
                                  border: BoxBorder.all(
                                    width: 0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                          /*return Image.memory(
                            imagenes[index],
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image),
                          );*/
                        },
                      );
                    },
                  ),
                  if (!streamController.isClosed)
                    Center(child: CircularProgressIndicator()),
                ],
              ),
        /*body: StreamBuilder<(WebDavFile, Uint8List)>(
          stream: nextcloudService.getImages(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData && snapshot.data != null) {
              final imageData = snapshot.data!.$2;
              imagenes.add(imageData);
            }
            if (imagenes.isEmpty &&
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return Stack(
              children: [
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: imagenes.length,
                  itemBuilder: (context, index) {
                    return Image.memory(
                      imagenes[index],
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    );
                  },
                ),
                if (snapshot.connectionState == ConnectionState.active)
                  Center(child: CircularProgressIndicator()),
              ],
            );
          },
        ),*/
      ),
    );
  }
}
