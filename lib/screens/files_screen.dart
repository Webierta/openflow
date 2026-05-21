import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nextcloud/webdav.dart';
import 'package:path/path.dart' as path_dart;
import 'package:path_provider/path_provider.dart';

import '../models/cuenta_nextcloud.dart';
import '../models/destino.dart';
import '../services/nextcloud_service.dart';
import '../theme/styles_app.dart';
import '../utils/extension_webdavfile.dart';
import '../utils/format_bytes.dart';
import '../utils/format_dates.dart';
import '../widgets/bottom_bar_app.dart';
import '../widgets/open_dialog.dart';
import '../widgets/snackbar_manager.dart';
import '../widgets/type_icon.dart';
import 'gallery_screen.dart';
import 'open_view_screen.dart';

part 'files_screen_on_tap_more.dart';

class FilesScreen extends StatefulWidget {
  final CuentaNextcloud cuenta;
  final String? inputSearch;

  const FilesScreen({super.key, required this.cuenta, this.inputSearch});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  late NextcloudService nextcloudService;
  String currentPath = '/';
  List<String> paths = [];
  bool isLoading = false;

  //String titleLoading = '';
  //String txtLoading = '';
  bool isGridView = false;
  double progress = 0;
  int copiedFiles = 0;
  String copiedName = '';
  TextEditingController renameController = TextEditingController();

  //List<CloudFile> directorios = [];
  String folderPathSelect = '';
  TextEditingController folderController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  List<WebDavFile> allFiles = [];

  //String depth = '1';
  WebDavDepth depth = WebDavDepth.one;

  @override
  void initState() {
    nextcloudService = NextcloudService(cuenta: widget.cuenta);
    if (widget.inputSearch != null) {
      //depth = 'infinity';
      depth = WebDavDepth.infinity;
      searchController.text = widget.inputSearch!;
    }
    initFiles(true);
    super.initState();
  }

  Future<void> initFiles([bool isInit = false]) async {
    setState(() {
      isLoading = true;
      if (isInit == false) {
        //depth = '1';
        depth = WebDavDepth.one;
        searchController.clear();
      }
    });
    allFiles =
        await nextcloudService.getFiles(path: currentPath, depth: depth) ?? [];
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    //cancelToken.cancel();
    //nextcloudApi.cancelToken.cancel();
    renameController.dispose();
    folderController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void onTapItem(WebDavFile item) {
    if (item.isDirectory) {
      setState(() {
        paths.add(currentPath);
        currentPath = item.pathFile(currentPath: currentPath);
        paths.add(currentPath);
      });
      initFiles();
    } else {
      /*Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => OpenFileScreen<WebDavFile>(
            cuenta: widget.cuenta,
            item: item,
            path: item.pathFile(currentPath: currentPath),
          ),
        ),
      );*/
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) =>
              OpenViewScreen<WebDavFile>(cuenta: widget.cuenta, item: item),
        ),
      );
    }
  }

  void setFolderPathSelect(String newFolder) {
    setState(() => folderPathSelect = newFolder);
  }

  void _onUploadProgress(double pro) {
    setState(() {
      progress = pro / 100;
      if (pro >= 100) {
        progress = 0;
      }
    });
  }

  void updateCopiedFiles(String name) {
    setState(() {
      copiedFiles = copiedFiles + 1;
      copiedName = name;
    });
  }

  void resetCopiedFiles() {
    setState(() {
      copiedFiles = 0;
      copiedName = '';
    });
  }

  void initCopyProgress() {
    setState(() {
      progress = 0.001;
    });
  }

  void resetCopyProgress() {
    setState(() {
      progress = 0;
      copiedFiles = 0;
      copiedName = '';
    });
  }

  void onCopyProgress({required int totalFiles}) {
    var copied = copiedFiles;
    if (copied > 0) {
      setState(() {
        progress = copiedFiles / totalFiles;
        if (progress >= 1) {
          progress = 0;
          resetCopiedFiles();
        }
      });
    }
  }

  /*void onCopyProgress(double pro) {
    setState(() {
      progress = pro / 100;
      if (pro >= 100) {
        progress = 0;
      }
    });
  }*/

  void setLoading(bool loading) {
    setState(() {
      isLoading = loading;
    });
  }

  /*void onProgressCopy(int copied, int total) {
    setState(() {
      progress = copied / total;
      if (progress >= 100) {
        progress = 0;
      }
    });
  }*/

  Future<void> uploadFile() async {}

  Future<void> addFolder() async {
    var folderName = await OpenDialog.inputName(
      context: context,
      title: 'Input folder name',
      icon: Icons.create_new_folder,
      controller: folderController,
    );
    if (folderName == null) return;
    folderController.clear();
    var newPath = '$currentPath/$folderName';
    var folderCreate = await nextcloudService.createFolder(newPath);
    if (folderCreate == true) {
      initFiles();
    }
    if (mounted) {
      SnackbarManager.show(
        context: context,
        msg: folderCreate == true
            ? 'Folder created successfully!'
            : 'Failed to create folder',
        error: folderCreate == false,
      );
    }
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
          title: Text('Files'),
          bottom: isLoading == true
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child:
                        depth == WebDavDepth.one &&
                            searchController.text.isEmpty
                        ? Row(
                            children: [
                              IconButton(
                                onPressed: currentPath == '/'
                                    ? null
                                    : () {
                                        setState(() {
                                          if (paths.isNotEmpty) {
                                            int indexCurrentPath = paths
                                                .indexOf(currentPath);
                                            if (indexCurrentPath > 0) {
                                              currentPath =
                                                  paths[indexCurrentPath - 1];
                                            }
                                            initFiles();
                                          }
                                        });
                                      },
                                icon: Icon(
                                  Icons.drive_folder_upload_rounded,
                                  size: 32,
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    currentPath == '/'
                                        ? 'Home'
                                        : 'Home/$currentPath',
                                    //: 'Home${currentPath.substring(1)}',
                                    style: TextStyle(fontSize: 16),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : InputChip(
                            label: Text(
                              widget.inputSearch ?? searchController.text,
                            ),
                            onDeleted: () {
                              if (searchController.text.isNotEmpty) {
                                setState(() {
                                  searchController.clear();
                                });
                              }
                              if (widget.inputSearch != null) {
                                ScaffoldMessenger.of(
                                  context,
                                ).removeCurrentSnackBar();
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                  ),
                ),
          actions: [
            if (depth == WebDavDepth.one) ...[
              IconButton(
                tooltip: 'Search in this folder',
                onPressed: () async {
                  searchController.clear();
                  final search = await OpenDialog.inputName(
                    context: context,
                    title: 'Search in this folder',
                    icon: Icons.search,
                    controller: searchController,
                  );
                  if (search != null &&
                      search.trim().isNotEmpty &&
                      context.mounted) {
                    setState(() {
                      searchController.text = search;
                    });
                  }
                },
                icon: Icon(Icons.search, size: 32, color: Colors.white),
              ),
              IconButton(
                tooltip: 'Create new folder here',
                onPressed: addFolder,
                icon: Icon(
                  Icons.create_new_folder,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              IconButton(
                tooltip: 'Sort by name',
                onPressed: () {
                  setState(() {
                    allFiles.sort(
                      (a, b) =>
                          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                    );
                  });
                },
                icon: Icon(Icons.sort_by_alpha, size: 32, color: Colors.white),
              ),
              IconButton(
                tooltip: 'Sort by date',
                onPressed: () {
                  setState(() {
                    allFiles.sort((a, b) {
                      //final aDate = FormatDates.toDate(a.lastModified!);
                      //final bDate = FormatDates.toDate(b.lastModified!);
                      return b.lastModified!.compareTo(a.lastModified!);
                    });
                  });
                },
                icon: Icon(Icons.date_range, size: 32, color: Colors.white),
              ),
            ],
          ],
        ),
        bottomNavigationBar: BottomBarApp(
          cuenta: widget.cuenta,
          destino: Destino.files,
          funcion: uploadFile,
          depth: depth,
          //cancelToken: nextcloudApi.cancelToken,
        ),
        body: isLoading == true
            ? Center(
                child: Transform.scale(
                  scale: 3,
                  child: CircularProgressIndicator(),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  if (progress > 0) {
                    return Center(
                      child: Padding(
                        padding: .symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: .center,
                          children: [
                            Text(
                              copiedName.isEmpty
                                  ? 'Progreso en ejecución'
                                  : 'Copiando archivos: $copiedName',
                            ),
                            LinearProgressIndicator(value: progress),
                            Text('${(progress * 100).toStringAsFixed(1)} %'),
                          ],
                        ),
                      ),
                    );
                  }
                  List<WebDavFile> searchFiles = allFiles;
                  if (searchController.text.isNotEmpty) {
                    searchFiles = allFiles
                        .where(
                          (file) => file.name.toLowerCase().contains(
                            searchController.text.toLowerCase(),
                          ),
                        )
                        .toList();
                  }
                  if (searchFiles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: .center,
                        children: [
                          Icon(Icons.not_interested_rounded, size: 84),
                          const SizedBox(height: 42),
                          Text('No se han encontrado archivos en este lugar'),
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
                      itemCount: searchFiles.length,
                      separatorBuilder: (context, index) {
                        return Divider(
                          color: Colors.white54,
                          thickness: 0.2,
                          indent: 20,
                          endIndent: 20,
                        );
                      },
                      itemBuilder: (context, index) {
                        var item = searchFiles[index];
                        return ListTile(
                          //selected: folderPathSelect == item.pathFile(currentPath),
                          selected:
                              //folderPathSelect == '${currentPath.substring(1)}/${item.name}',
                              //folderPathSelect == '/' + item.path.parent!.path + item.name,
                              folderPathSelect ==
                              item.pathFile(
                                currentPath: currentPath,
                                bar: false,
                              ),
                          /*folderPathSelect ==
                              (item.pathFileHome() ??
                                  '${currentPath.substring(1)}/${item.name}'),*/
                          selectedColor: Colors.blueAccent,
                          onTap: () => onTapItem(item),
                          leading:
                              (item.mimeType != null &&
                                  item.mimeType!.startsWith('image/'))
                              ? FutureBuilder(
                                  /*future: nextcloudService.getPreview(
                                    //path: item.path.name,
                                    path: '$currentPath/${item.path.name}',
                                  ),*/
                                  future: nextcloudService.getThumbnail(
                                    path: '$currentPath/${item.path.name}',
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
                                  isDirectory: item.isDirectory,
                                  fileType: item.mimeType,
                                ),
                          title: Text(
                            item.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: .start,
                            children: [
                              /*if (searchController.text.isNotEmpty &&
                                  item.getDirName(widget.cuenta.userName) !=
                                      null)*/
                              if (depth == WebDavDepth.infinity)
                                // && item.getDirName(widget.cuenta.userName) != null)
                                //Text('in ${item.getDirName(widget.cuenta.userName)}'),
                                Text('in ${item.path.path}'),
                              if (item.lastModified != null)
                                //Text(FormatDates.show(item.lastModified!)),
                                Text(
                                  FormatDates.dateToString(
                                    date: item.lastModified!,
                                  ),
                                ),
                              if (!item.isDirectory && item.size != null)
                                Text(FormatBytes.show(item.size!)),
                              if (item.isDirectory &&
                                  item.props.davQuotaUsedBytes != null)
                                Text(
                                  FormatBytes.show(
                                    item.props.davQuotaUsedBytes!,
                                  ),
                                ),
                              //Text(item.props.davQuotaUsedBytes!.toString()),
                              if (item.mimeType != null) Text(item.mimeType!),
                              //if (item.href != null) Text(item.href!),
                              //Text(item.)
                              /*if (item.fileId != null)
                                FutureBuilder(
                                  future: nextcloudService.isShare(
                                    '${item.fileId}',
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      String isShare = snapshot.data.toString();
                                      return Text(isShare);
                                    }
                                    return Text('N/D');
                                  },
                                ),*/
                            ],
                          ),
                          trailing: IconButton(
                            onPressed: () =>
                                onTapMore(item, setFolderPathSelect),
                            /*onPressed: () => onTapMore(
                              context: context,
                              item: item,
                              path: currentPath,
                            ),*/
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
