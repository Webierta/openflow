import 'package:flutter/material.dart';

class StylesApp {
  static LinearGradient gradient(ColorScheme colorsScheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [colorsScheme.onPrimary, colorsScheme.inversePrimary],
    );
  }

  static LinearGradient nextcloudGradient() {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF0082C9), Color(0xFF1CAFFF)],
    );
  }

  static BoxDecoration backgroundScreen(BuildContext context) {
    return BoxDecoration(
      gradient: StylesApp.gradient(Theme.of(context).colorScheme),
      //gradient: StylesApp.nextcloudGradient(),
      image: DecorationImage(
        image: AssetImage('assets/images/fondo.png'),
        fit: BoxFit.fill,
        opacity: 0.2,
      ),
    );
  }
}
