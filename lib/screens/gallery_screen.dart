import 'package:flutter/material.dart';

import '../models/cuenta_nextcloud.dart';

class GalleryScreen extends StatefulWidget {
  final CuentaNextcloud cuenta;

  const GalleryScreen({super.key, required this.cuenta});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
