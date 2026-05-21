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
                      renameFile(item.pathFile(currentPath: currentPath));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.move_down),
                    title: Text('Move'),
                    onTap: () {
                      Navigator.pop(contextBottomSheet);
                      moveFile(item.pathFile(currentPath: currentPath));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Copy'),
                    onTap: () {
                      Navigator.pop(contextBottomSheet);
                      //moveCopyFile(item.pathFile(currentPath), OnFile.copy);
                      if (item.isDirectory) {
                        copyFolder(item.pathFile(currentPath: currentPath));
                        //copyFile(item.pathFile(currentPath: currentPath));
                      } else {
                        copyFile(item.pathFile(currentPath: currentPath));
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
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => GalleryScreen(
                              cuenta: widget.cuenta,
                              pathGallery: item.pathFile(
                                currentPath: currentPath,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Delete'),
                    onTap: () {
                      Navigator.pop(contextBottomSheet);
                      deleteFile(item.pathFile(currentPath: currentPath));
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

  void showError({String msg = 'Error de descarga'}) {
    SnackbarManager.show(
      context: context,
      msg: 'Error de descarga',
      error: true,
    );
  }

  Future<void> downloadFile(WebDavFile item) async {
    String path = item.pathFile(currentPath: currentPath);
    final responseBytes = await nextcloudService.readFileBytes(path);
    if (responseBytes == null) {
      showError(msg: 'Error obteniendo archivo');
      return;
    }
    final Directory? downloadsDir = await getDownloadsDirectory();
    if (downloadsDir == null) {
      showError(msg: 'Error de acceso a la carpeta de descargas');
      return;
    }
    final file = File('${downloadsDir.path}/${item.name}');
    try {
      await file.writeAsBytes(responseBytes);
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

  Future<void> renameFile(String oldPath) async {
    var oldName = path_dart.basename(oldPath);
    renameController.text = oldName;
    var basePath = path_dart.dirname(oldPath);
    var newName = await OpenDialog.inputName(
      context: context,
      title: 'Input new name',
      icon: Icons.edit,
      controller: renameController,
    );
    if (newName == null) return;
    var newPath = '$basePath/$newName';
    var fileRename = await nextcloudService.moveFile(
      oldPath: oldPath,
      newPath: newPath,
    );
    if (fileRename == true) {
      initFiles();
    }
    if (mounted) {
      SnackbarManager.show(
        context: context,
        msg: fileRename == true
            ? 'File renamed successfully!'
            : 'Failed to rename file',
        error: fileRename == false,
      );
    }
  }

  Future<void> moveFile(String oldPath) async {
    var fileName = path_dart.basename(oldPath);
    final confirmation = await OpenDialog.confirm(
      context: context,
      title: 'Mover Archivo',
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text('Archivo: $fileName'),
          const SizedBox(height: 20),
          Text('Destino : $folderPathSelect/'),
        ],
      ),
    );
    if (confirmation != true) return;
    var returnApi = await nextcloudService.moveFile(
      oldPath: oldPath,
      newPath: '$folderPathSelect/$fileName',
    );
    if (returnApi == true) {
      initFiles();
    }
    if (mounted) {
      SnackbarManager.show(
        context: context,
        msg: returnApi == true ? 'File moved' : 'Failed to move file',
        error: returnApi == false,
      );
    }
  }

  Future<void> copyFile(String pathSource) async {
    var fileName = path_dart.basename(pathSource);
    final confirmation = await OpenDialog.confirm(
      context: context,
      title: 'Copiar Archivo',
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text('Archivo: $fileName'),
          const SizedBox(height: 20),
          Text('Destino : $folderPathSelect/'),
          const SizedBox(height: 20),
          Text(
            'Si en destino existe un archivo con el mismo nombre, '
            'se sobreescribirá.',
          ),
        ],
      ),
    );
    if (confirmation == true) {
      var responseCopy = await nextcloudService.copyFile(
        oldPath: Uri.decodeFull(pathSource),
        newPath: '$folderPathSelect/$fileName',
      );
      if (responseCopy == true) {
        initFiles();
      }
      if (mounted) {
        SnackbarManager.show(
          context: context,
          msg: responseCopy == true ? 'File copied' : 'Failed to copy file',
          error: responseCopy == false,
        );
      }
    }
  }

  Future<bool?> copiarCarpeta({
    required String rutaOrigen,
    required String rutaDestino,
    required int total,
  }) async {
    final allFiles = await nextcloudService.getFiles(
      path: rutaOrigen,
      //depth: WebDavDepth.infinity,
    );
    if (allFiles == null) return false;
    for (final item in allFiles) {
      updateCopiedFiles(item.name);
      onCopyProgress.call(totalFiles: total);
      if (item.isDirectory) {
        var nuevaRuta = '$rutaDestino/${item.name}';
        nuevaRuta = Uri.decodeFull(nuevaRuta);
        final responseCreate = await nextcloudService.createFolder(nuevaRuta);
        if (responseCreate == false) return false;
        await copiarCarpeta(
          rutaOrigen: '$rutaOrigen/${item.path.name}',
          rutaDestino: nuevaRuta,
          total: total,
        );
      } else {
        var rutaFile = '${item.path.parent?.path}${item.name}';
        final responseCopy = await nextcloudService.copyFile(
          oldPath: rutaFile,
          newPath: '$rutaDestino/${item.name}',
        );
        if (responseCopy == false) return false;
      }
    }
    return true;
  }

  Future<void> copyFolder(String pathSource) async {
    var fileName = path_dart.basename(pathSource);
    final confirmation = await OpenDialog.confirm(
      context: context,
      title: 'Copiar Directorio',
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text('Carpeta: $fileName'),
          const SizedBox(height: 20),
          Text('Destino : $folderPathSelect/'),
          const SizedBox(height: 20),
          Text(
            'Si en destino existe un archivo con el mismo nombre, '
            'el proceso se abortará.',
          ),
        ],
      ),
    );
    if (confirmation == true) {
      var pathDestino = '$folderPathSelect/$fileName';
      final total = await nextcloudService.getFiles(
        path: pathSource,
        depth: WebDavDepth.infinity,
      );
      //print(allFiles?.length);
      //return;
      // chequear si existe la carpeta ??
      final responseCreate = await nextcloudService.createFolder(pathDestino);
      if (responseCreate == false) {
        if (mounted) {
          SnackbarManager.show(
            context: context,
            msg: 'Error: proceso abortado',
            error: true,
          );
        }
        return;
      }
      //setLoading(loading: true, texto: 'Copiando archivos...');
      initCopyProgress();
      final responseCopy = await copiarCarpeta(
        rutaOrigen: pathSource,
        rutaDestino: pathDestino,
        total: total!.length,
      );
      if (responseCopy == false) {
        resetCopyProgress();
      }
      if (mounted) {
        SnackbarManager.show(
          context: context,
          msg: responseCopy == true ? 'Files copied!' : 'Error files copy!',
          error: responseCopy == false,
        );
      }
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

  Future<void> deleteFile(String path) async {
    final confirmation = await OpenDialog.confirm(
      context: context,
      title: 'Confirmación requerida',
      content: Text('Elimina este archivo:\n$path'),
    );
    if (confirmation == true) {
      var deleteFile = await nextcloudService.deleteFile(path);
      if (deleteFile == true) {
        initFiles();
      }
      if (mounted) {
        SnackbarManager.show(
          context: context,
          msg: deleteFile == true ? 'File deleted' : 'Error',
          error: deleteFile == false,
        );
      }
    }
  }
}
