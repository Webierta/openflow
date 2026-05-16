import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nextcloud/files_sharing.dart';
import 'package:openflow/utils/extension_Share.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/cuenta_nextcloud.dart';
import '../models/destino.dart';
import '../services/nextcloud_service.dart';
import '../theme/styles_app.dart';
import '../utils/format_bytes.dart';
import '../widgets/bottom_bar_app.dart';
import '../widgets/snackbar_manager.dart';
import '../widgets/type_icon.dart';

class SharedScreen extends StatefulWidget {
  final CuentaNextcloud cuenta;

  const SharedScreen({super.key, required this.cuenta});

  @override
  State<SharedScreen> createState() => _SharedScreenState();
}

class _SharedScreenState extends State<SharedScreen> {
  late NextcloudService nextcloudService;

  //Map<SharedFile, CloudFile> mapFiles = {};
  List<Share> shares = [];

  bool isLoading = false;

  //List<SharedFile> allShared = [];

  @override
  void initState() {
    nextcloudService = NextcloudService(cuenta: widget.cuenta);
    initShared();
    super.initState();
  }

  Future<void> initShared() async {
    setState(() => isLoading = true);
    final responseShares = await nextcloudService.getShares();
    if (responseShares == null) return;
    final List<Share> myShares = List.from(responseShares);
    setState(() {
      shares = myShares;
      isLoading = false;
    });
  }

  void onTapShared(Share share) async {}

  void openShare(Share share) async {}

  void onTapMore(Share share) {
    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: false,
      scrollControlDisabledMaxHeightRatio: 0.7,
      barrierColor: Colors.white70,
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      context: context,
      constraints: BoxConstraints(maxWidth: double.infinity),
      builder: (BuildContext contextBottomSheet) {
        final link = share.url ?? share.shareWithLink;
        return Padding(
          padding: const .only(bottom: 20.0),
          child: ListView(
            children: [
              Padding(
                padding: const .symmetric(horizontal: 10),
                child: Center(
                  child: Text(share.name, style: TextStyle(fontSize: 22)),
                ),
              ),
              Divider(),
              Column(
                mainAxisSize: .min,
                children: [
                  ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Copiar link al portapapeles'),
                    subtitle: link != null
                        ? Text(
                            link,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    onTap: link == null
                        ? () {
                            Navigator.pop(contextBottomSheet);
                            if (!context.mounted) return;
                            SnackbarManager.show(
                              context: context,
                              msg: 'Error: Link no encontrado',
                              error: true,
                            );
                          }
                        : () async {
                            Navigator.pop(contextBottomSheet);
                            await Clipboard.setData(ClipboardData(text: link));
                            if (!mounted) return;
                            SnackbarManager.show(
                              context: context,
                              msg: 'Link copiado al portapapeles',
                            );
                          },
                  ),
                  ListTile(
                    leading: Icon(Icons.open_in_new),
                    title: Text('Abrir en el navegador'),
                    onTap: link == null
                        ? () => Navigator.pop(contextBottomSheet)
                        : () async {
                            Navigator.pop(contextBottomSheet);
                            if (!await launchUrl(
                              Uri.parse(link),
                              mode: LaunchMode.externalApplication,
                            )) {
                              //throw Exception('Could not launch ${item.sharedLink}',);
                              if (!mounted) return;
                              SnackbarManager.show(
                                context: context,
                                msg: 'Could not launch $link',
                                error: true,
                              );
                            }
                          },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.link_off),
                    title: Text('Dejar de compartir'),
                    onTap: int.tryParse(share.id) == null
                        ? () {
                            Navigator.pop(contextBottomSheet);
                            if (!context.mounted) return;
                            SnackbarManager.show(
                              context: context,
                              msg: 'Error: proceso abortado',
                              error: true,
                            );
                          }
                        : () async {
                            Navigator.pop(contextBottomSheet);
                            /*var noCompartir = await nextcloudApi.unshareFile(
                              int.parse(share.id),
                            );
                            if (!context.mounted) return;
                            if (noCompartir == true) {
                              //setState(() {});
                              SnackbarManager.show(
                                context: context,
                                msg: 'El archivo ha dejado de ser compartido',
                              );
                              initShared();
                            } else {
                              SnackbarManager.show(
                                context: context,
                                msg: 'Error al dejar de compartir',
                                error: true,
                              );
                            }*/
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
            /*child: CuentaAvatar(
              cuenta: widget.cuenta,
              size: 30,
              onlyAvatar: true,
            ),*/
            child: widget.cuenta.avatar != null
                ? Image.memory(widget.cuenta.avatar!, height: 30, width: 30)
                : Icon(Icons.person_off, size: 30, color: Colors.grey),
          ),
          title: Text('Shares files'),
          actions: [
            IconButton(
              tooltip: 'Sort by name',
              onPressed: () {
                setState(() {
                  shares.sort(
                    (a, b) => a.fileTarget.toLowerCase().compareTo(
                      b.fileTarget.toLowerCase(),
                    ),
                  );
                });
              },
              icon: Icon(Icons.sort_by_alpha, size: 32, color: Colors.white),
            ),
            IconButton(
              tooltip: 'Sort by date',
              onPressed: () {
                setState(() {
                  shares.sort((a, b) => b.itemMtime.compareTo(a.itemMtime));
                });
              },
              icon: Icon(Icons.date_range, size: 32, color: Colors.white),
            ),
          ],
        ),
        bottomNavigationBar: BottomBarApp(
          cuenta: widget.cuenta,
          destino: Destino.shared,
          //cancelToken: nextcloudApi.cancelToken,
          //funcion: null,
        ),
        body: (isLoading == true)
            ? Center(
                child: Transform.scale(
                  scale: 3,
                  child: CircularProgressIndicator(),
                ),
              )
            : shares.isEmpty
            ? Center(child: Text('Sin archivos compartidos'))
            : LayoutBuilder(
                builder: (context, constraints) {
                  if (shares.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: .center,
                        children: [
                          Icon(Icons.not_interested_rounded, size: 84),
                          const SizedBox(height: 42),
                          Text('No se han encontrado archivos compartidos'),
                        ],
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    physics: ScrollPhysics(),
                    padding: .fromLTRB(4, 4, 4, 60),
                    child: ListView.separated(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: shares.length,
                      separatorBuilder: (context, index) {
                        return Divider(
                          color: Colors.white54,
                          thickness: 0.2,
                          indent: 20,
                          endIndent: 20,
                        );
                      },
                      itemBuilder: (context, index) {
                        var share = shares[index];
                        return ListTile(
                          onTap: () => onTapShared(share),
                          titleAlignment: ListTileTitleAlignment.top,
                          leading: share.mimetype.startsWith('image/')
                              ? FutureBuilder(
                                  future: nextcloudService.getThumbnail(
                                    //path: '$currentPath/${item.path.name}',
                                    path: share.fileTarget,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        height: 48,
                                        width: 48,
                                        fit: BoxFit.fill,
                                      );
                                    }
                                    return Icon(Icons.image, size: 42);
                                  },
                                )
                              : TypeIcon(
                                  isDirectory: share.itemType.name == 'folder',
                                  fileType: share.mimetype,
                                ),
                          title: Text(
                            share.fileTarget.substring(1),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: .start,
                            children: [
                              Text(
                                'in ${share.path == share.fileTarget ? 'Home' : share.name}',
                              ),
                              FittedBox(
                                child: Row(
                                  children: [
                                    Text(
                                      FormatBytes.show(share.itemSize.toInt()),
                                      maxLines: 2,
                                    ),
                                    Text(' - '),
                                    Text(share.mimetype),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          trailing: IconButton(
                            onPressed: () => onTapMore(share),
                            icon: Icon(Icons.more_vert),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
