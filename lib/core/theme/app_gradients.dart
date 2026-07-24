import 'package:flutter/material.dart';

class AppGradients {
  AppGradients._();

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFD4E1F3),
    ],
    stops: [0.0, 1.0],
  );

  static const LinearGradient resultScreenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFD5E2F4),
    ],
    stops: [0.1763, 0.4243],
  );
}

