import 'package:flutter/material.dart';

class TypeIcon extends StatelessWidget {
  final bool? isDirectory;
  final String? fileType;
  final double size;

  const TypeIcon({
    super.key,
    this.fileType,
    this.isDirectory = false,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    if (isDirectory == true) {
      return Icon(Icons.folder_open_outlined, size: size);
    }
    if (fileType == null) {
      return Icon(Icons.insert_drive_file_outlined, size: size);
    }

    if (fileType!.startsWith('image/')) {
      return Icon(Icons.image, size: size);
    }
    if (fileType!.contains('/pdf')) {
      return Icon(Icons.picture_as_pdf, size: size);
    }
    if (fileType!.contains('text/plain')) {
      return Icon(Icons.text_snippet, size: size);
    }
    if (fileType!.contains('android')) {
      return Icon(Icons.android, size: size);
    }
    if (fileType!.contains('text/markdown')) {
      return Icon(Icons.text_fields, size: size);
    }
    return Icon(Icons.insert_drive_file_outlined, size: size);
  }
}
