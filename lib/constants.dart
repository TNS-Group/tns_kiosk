import 'package:flutter/material.dart';

const double phi = 1.61803399;

const unavailableTextColor = Color.fromARGB(167, 255, 255, 255);
const unavailableBGColor = Color.fromARGB(64, 32, 32, 32);
const availableBGColor = Color.fromARGB(32, 128, 128, 128);
const availableTextColor = Color.fromARGB(255, 255, 255, 255);

const availableAvailabilityTextColor = Color.fromARGB(255, 98, 255, 98);
const unavailableAvailabilityTextColor = Color.fromARGB(255, 224, 139, 139);

const opacityUnavailable = 0.4;

final imageGradientAvailable = <Color>[
  Colors.black.withAlpha(200), 
  Colors.black.withAlpha(0), 
  Colors.black.withAlpha(0), 
];

final imageGradientUnavailable = <Color>[
  Colors.black.withAlpha(200), 
  Colors.black.withAlpha(0), 
];
