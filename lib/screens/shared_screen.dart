import 'package:flutter/material.dart';

import '../models/cuenta_nextcloud.dart';

class SharedScreen extends StatefulWidget {
  final CuentaNextcloud cuenta;

  const SharedScreen({super.key, required this.cuenta});

  @override
  State<SharedScreen> createState() => _SharedScreenState();
}

class _SharedScreenState extends State<SharedScreen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
