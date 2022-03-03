import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import '../myservice.dart';
import 'coordinates_translator.dart';

class MyTextDetectorPainter extends CustomPainter {
  MyTextDetectorPainter(
      this.recognisedText, this.absoluteImageSize, this.rotation, this.context);

  final List<TextElement> recognisedText;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final BuildContext context;


  @override
  void paint(Canvas canvas, Size size) {
    MyService _myService = MyService();
    //print("Setting myVariable to:" + _myService.myVariable.toString());
    _myService.setMyVariable(size);
  }

  @override
  bool shouldRepaint(MyTextDetectorPainter oldDelegate) {
    // never repaint, because nothing is painted. We just use the canvas size in this class...
    return false;
  }

}
