import 'package:flutter/material.dart';

import '../models/cuenta_nextcloud.dart';

class FilesScreen extends StatefulWidget {
  final CuentaNextcloud cuenta;

  const FilesScreen({super.key, required this.cuenta});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
