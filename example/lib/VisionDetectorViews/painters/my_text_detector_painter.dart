import 'dart:collection';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

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
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.lightGreenAccent;

    final Paint background = Paint()..color = Color(0x99000000);
    final Map<String, String> dict = {
      "Analysis": "Die Analysis [aˈnaːlyzɪs] (ανάλυσις análysis ‚Auflösung‘, ἀναλύειν analýein ‚auflösen‘) ist ein Teilgebiet der Mathematik, dessen Grundlagen von Gottfried Wilhelm Leibniz und Isaac Newton als Infinitesimalrechnung unabhängig voneinander entwickelt wurden.",
      "Abitur": "Abitur is defined.",
      "Kapitel": "Kapitel is defined.",
      "Logarithmusfunktionen": "Durch die Umkehrung der Exponentialfunktion f(x) = a^x (a > 0) ergibt sich die Logarithmusfunktion: f(x) = log_a(x)."
    };

    var words = recognisedText;
    words.retainWhere((element) => dict.containsKey(element.text));
    for (final textWord in words) {
      final TextButton tb = TextButton(child: const Text('keyword'), onPressed: () => print("PRESSED"),autofocus: false);
      final Stack st = Stack(children: [Positioned(child: tb)]);

      final ParagraphBuilder builder = ParagraphBuilder(
        ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: 16,
            textDirection: TextDirection.ltr),
      );
      builder.pushStyle(
          ui.TextStyle(color: Colors.lightGreenAccent, background: background));
      builder.addText('${textWord.text}');
      builder.pop();

      final left =
          translateX(textWord.rect.left, rotation, size, absoluteImageSize);
      final top =
          translateY(textWord.rect.top, rotation, size, absoluteImageSize);
      final right =
          translateX(textWord.rect.right, rotation, size, absoluteImageSize);
      final bottom =
          translateY(textWord.rect.bottom, rotation, size, absoluteImageSize);

      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint,
      );

      canvas.drawParagraph(
        builder.build()
          ..layout(ParagraphConstraints(
            width: right - left,
          )),
        Offset(left, top),
      );
    }
  }

  @override
  bool shouldRepaint(MyTextDetectorPainter oldDelegate) {
    // TODO: return false if 3 words in new and old text are the same
    // TODO: actually in the case of 3 equal words sets of boxes should be merged
    return true;
    //return oldDelegate.recognisedText != recognisedText;
  }
}
