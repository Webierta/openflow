import 'package:flutter/material.dart';

import '../models/cuenta_nextcloud.dart';

class NotesScreen extends StatefulWidget {
  final CuentaNextcloud cuenta;

  const NotesScreen({super.key, required this.cuenta});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
