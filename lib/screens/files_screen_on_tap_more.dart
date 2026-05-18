part of 'files_screen.dart';

extension _OnTapMore on _FilesScreenState {
  void onTapMore(WebDavFile item, void Function(String) setFolderPathSelect) {
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
              Center(child: Text(item.name, style: TextStyle(fontSize: 22))),
              Divider(),
              Column(
                mainAxisSize: .min,
                //crossAxisAlignment: .start,
                children: [
                  ListTile(
                    leading: Icon(Icons.download),
                    title: Text('Download'),
                    onTap: () {
                      Navigator.pop(contextBottomSheet);
                      downloadFile(item);
                    },
                  ),
                  FutureBuilder(
                    future: checkShare(item),
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
                                : 'Unshare File',
                          ),
                          onTap: () {
                            Navigator.pop(contextBottomSheet);
                            snapshot.data == false
                                ? shareFile(item)
                                : unShareFile(item);
                          },
                        );
                      } else if (snapshot.hasError) {
                        return ListTile(
                          leading: Icon(Icons.link),
                          title: Text('Error checking if the file is shared'),
                        );
                      }
                      return ListTile(
                        leading: Icon(Icons.link),
                        title: Text('Checking if the file is shared...'),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.drive_file_rename_outline),
                    title: Text('Rename'),
                    onTap: () {
                      Navigator.pop(contextBottomSheet);
                      //renameFile(item.pathFile(currentPath));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.move_down),
                    title: Text('Move'),
                    onTap: () {
                      Navigator.pop(contextBottomSheet);
                      //moveFile(item.pathFile(currentPath));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Copy'),
                    onTap: () {
                      Navigator.pop(contextBottomSheet);
                      //moveCopyFile(item.pathFile(currentPath), OnFile.copy);
                      if (item.isDirectory) {
                        //copyFolder(pathSource: item.pathFile(currentPath));
                      } else {
                        //copyFile(pathSource: item.pathFile(currentPath));
                      }
                    },
                  ),
                  if (item.isDirectory) ...[
                    Divider(),
                    ListTile(
                      leading:
                          //folderPathSelect == '${widget.cuenta.server}${item.href}'
                          //folderPathSelect == item.pathFile(currentPath)
                          //folderPathSelect == '${currentPath.substring(1)}/${item.name}'
                          //folderPathSelect == '/' + item.path.parent!.path + item.name
                          folderPathSelect ==
                              item.pathFile(
                                currentPath: currentPath,
                                bar: false,
                              )
                          /*folderPathSelect ==
                              (item.pathFileHome() ??
                                  '${currentPath.substring(1)}/${item.name}')*/
                          ? Icon(Icons.check_box)
                          : Icon(Icons.check_box_outline_blank),
                      title:
                          //folderPathSelect == '${widget.cuenta.server}${item.href}'
                          //folderPathSelect == item.pathFile(currentPath)
                          //folderPathSelect == '${currentPath.substring(1)}/${item.name}'
                          //folderPathSelect == '/' + item.path.parent!.path + item.name
                          /*folderPathSelect ==
                              (item.pathFileHome() ??
                                  '${currentPath.substring(1)}/${item.name}')*/
                          folderPathSelect ==
                              item.pathFile(
                                currentPath: currentPath,
                                bar: false,
                              )
                          ? Text('Unselect as the destination to move or copy')
                          : Text('Select as the destination to move or copy'),
                      onTap: () {
                        Navigator.pop(contextBottomSheet);
                        //final folderItem = '${widget.cuenta.server}${item.href}';
                        //final folderItem = item.pathFile(currentPath);
                        //final folderItem = '${currentPath.substring(1)}/${item.name}';
                        //final folderItem = '/' + item.path.parent!.path + item.name;
                        final folderItem = item.pathFile(
                          currentPath: currentPath,
                          bar: false,
                        );
                        if (folderPathSelect == folderItem) {
                          setFolderPathSelect('');
                        } else {
                          setFolderPathSelect(folderItem);
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.sync),
                      title: Text('Synchronize'),
                      onTap: () {
                        Navigator.pop(contextBottomSheet);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.photo_library_outlined),
                      title: Text('View content in Gallery'),
                      onTap: () {
                        Navigator.pop(contextBottomSheet);
                        /*Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => GalleryScreen(
                              cuenta: widget.cuenta,
                              pathGallery: item.pathFile(currentPath),
                            ),
                          ),
                        );*/
                      },
                    ),
                  ],
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Delete'),
                    onTap: () {
                      Navigator.pop(contextBottomSheet);
                      //deleteFile(item.pathFile(currentPath));
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

  Future<void> downloadFile(WebDavFile item) async {
    String path = item.pathFile(currentPath: currentPath);
    bool download = await nextcloudService.downloadFile(
      path: path,
      name: item.name,
    );
    if (download == true) {
      initFiles();
    }
    if (mounted) {
      SnackbarManager.show(
        context: context,
        msg: download == true
            ? 'File downloaded to downloads directory'
            : 'Error de descarga',
        error: !download,
      );
    }
  }

  Future<bool> checkShare(WebDavFile item) async {
    final path = item.pathFile(currentPath: currentPath, bar: true);
    return await nextcloudService.isFileShared(path);
  }

  Future<void> shareFile(WebDavFile item) async {
    String path = '$currentPath/${item.name}';
    final responseShare = await nextcloudService.shareFile(path: path);
    if (responseShare.$1 == true) {
      await Clipboard.setData(ClipboardData(text: responseShare.$2));
      initFiles();
    }
    if (!mounted) return;
    SnackbarManager.show(
      context: context,
      msg: responseShare.$1 == true
          ? 'Shared link copied to clipboard'
          : 'Error de shared',
      error: !responseShare.$1,
    );
  }

  Future<void> unShareFile(WebDavFile item) async {
    String path = '$currentPath/${item.name}';
    final responseId = await nextcloudService.getIdShare(path);
    if (responseId == null) return;
    final responseUnshare = await nextcloudService.unshareFile(responseId);
    if (!mounted) return;
    if (responseUnshare == true) {
      SnackbarManager.show(
        context: context,
        msg: 'El archivo ha dejado de ser compartido',
      );
      //initFiles();
    } else {
      SnackbarManager.show(
        context: context,
        msg: 'Error al dejar de compartir',
        error: true,
      );
    }
  }
}
