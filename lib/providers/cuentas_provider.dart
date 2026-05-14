import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cuenta_nextcloud.dart';

final cuentasProvider =
    NotifierProvider<CuentasNotifier, List<CuentaNextcloud>>(
      CuentasNotifier.new,
    );

class CuentasNotifier extends Notifier<List<CuentaNextcloud>> {
  @override
  List<CuentaNextcloud> build() {
    return [];
  }

  void add(CuentaNextcloud cuenta) {
    final newCuenta = CuentaNextcloud(
      server: cuenta.server,
      userName: cuenta.userName,
      password: cuenta.password,
      statusAuth: cuenta.statusAuth,
      userId: cuenta.userId,
      avatar: cuenta.avatar,
      lastLogin: cuenta.lastLogin,
    );
    state = [...state, newCuenta];
  }

  void remove(CuentaNextcloud cuenta) =>
      state = state.where((c) => c.name != cuenta.name).toList();

  void edit(
    CuentaNextcloud cuenta, {
    String? newServer,
    String? newUser,
    String? newPassword,
    StatusAuth? newStatusAuth,
    String? newUserId,
    Uint8List? newAvatar,
    int? newLastLogin,
  }) {
    final newCuenta = CuentaNextcloud(
      server: newServer ?? cuenta.server,
      userName: newUser ?? cuenta.userName,
      password: newPassword ?? cuenta.password,
      statusAuth: newStatusAuth ?? cuenta.statusAuth,
      userId: newUserId ?? cuenta.userId,
      avatar: newAvatar ?? cuenta.avatar,
      lastLogin: newLastLogin ?? cuenta.lastLogin,
    );
    if (state.contains(cuenta)) {
      state[state.indexOf(cuenta)] = newCuenta;
    }
  }

  void desconectar(CuentaNextcloud cuenta) {
    state = state.map((c) {
      if (c.name == cuenta.name) {
        return c.copyWith(statusAuth: StatusAuth.logout);
      } else {
        return c;
      }
    }).toList();
  }

  void clear() {
    state = [];
  }
}
