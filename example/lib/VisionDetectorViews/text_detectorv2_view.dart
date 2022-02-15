import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:vector_math/vector_math.dart';
import 'package:fuzzy/fuzzy.dart';
import 'painters/coordinates_translator.dart';


import 'camera_view.dart';
import 'painters/my_text_detector_painter.dart';

class TextDetectorV2View extends StatefulWidget {
  @override
  _TextDetectorViewV2State createState() => _TextDetectorViewV2State();
}

class _TextDetectorViewV2State extends State<TextDetectorV2View> {
  TextDetectorV2 textDetector = GoogleMlKit.vision.textDetectorV2();
  bool isBusy = false;
  CustomPaint? customPaint;
  List<TextElement> allBoxes = [];
  List<TextElement> wBoxes = [];
  List<TextElement> oldAllBoxes = [];
  List<TextElement> oldWBoxes = [];
  int recCount = 0;
  final Map<String, String> dict = {
    "Analysis": "Die Analysis [aˈnaːlyzɪs] (ανάλυσις análysis ‚Auflösung‘, ἀναλύειν analýein ‚auflösen‘) ist ein Teilgebiet der Mathematik, dessen Grundlagen von Gottfried Wilhelm Leibniz und Isaac Newton als Infinitesimalrechnung unabhängig voneinander entwickelt wurden.",
    "Abitur": "Abitur is defined.",
    "Kapitel": "Kapitel is defined.",
    "Logarithmusfunktionen": "Durch die Umkehrung der Exponentialfunktion f(x) = a^x (a > 0) ergibt sich die Logarithmusfunktion: f(x) = log_a(x)."
  };
  List<Widget> widgets = <Widget>[];
  late InputImage inputImg;

  String titleVar = 'NOT FOUND';

  @override
  void dispose() async {
    super.dispose();
    await textDetector.close();
  }

  @override
  Widget build(BuildContext context) {


    Future<void> _showMyDialog(String word, String definition) async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(word),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(definition),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    widgets = <Widget>[CameraView(
      title: titleVar,
      customPaint: customPaint,
      onImage: (inputImage) {
        inputImg = inputImage;
        processImage(inputImage);
      },
    )];
    for (final wBox in wBoxes) {
      widgets.add(Positioned(top: translateY(wBox.rect.top, inputImg.inputImageData!.imageRotation, inputImg.inputImageData!.size, inputImg.inputImageData!.size), left: translateX(wBox.rect.left, inputImg.inputImageData!.imageRotation, inputImg.inputImageData!.size, inputImg.inputImageData!.size), width: wBox.rect.width, height: wBox.rect.height,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 14)),
          onPressed: () => _showMyDialog(wBox.text, dict[wBox.text]!),
          child: Text(wBox.text),)));
    }
    return Stack(
      children: widgets);
  }

  bool fuzzyContains(Map<String, String> dict, String word) {
    final bookList = [
      'Analysis',
      'Abitur',
      'Kapitel',
      'Logarithmusfunktionen',
    ];
    final fuse = Fuzzy(
      bookList,
      options: FuzzyOptions(
        tokenize: false,
        threshold: 0.15,
      ),
    );

    final result = fuse.search(word);

    if (result.isEmpty) {
      return false;
    } else {
      print(word + " " + result.first.item.toString());
      return true;
    }
  }

  // This is similar to the call to pytesseract.image_to_data()
  Future<void> processImage(InputImage inputImage) async {
    if (isBusy) return;
    isBusy = true;
    // TODO: maybe do the following expensive ocr call in an isolate or in the compute method???
    final recognisedText = await textDetector.processImage(inputImage,
        script: TextRecognitionOptions.DEFAULT);
    //print('Found ${recognisedText.blocks.length} textBlocks');
    // TODO: store allboxes and wboxes here
    // TODO: while doing that, use TEXT CORRECTION / SPELL CHECKING according to our dictionary

    oldAllBoxes = [];
    oldAllBoxes.addAll(allBoxes);
    oldWBoxes = [];
    oldWBoxes.addAll(wBoxes);
    wBoxes = [];
    allBoxes = [];
    for (final textBlock in recognisedText.blocks) {
      for (final textLine in textBlock.lines) {
        var words = textLine.elements;
        allBoxes.addAll(words);
        // TODO: do SPELL CHECKING here according to our dictionary
        words.retainWhere((element) => dict.containsKey(
            element.text)); // || fuzzyContains(dict, element.text));
        for (final textWord in words) {
          wBoxes.add(textWord);
        }
      }
    }
    // TODO: then analyse allboxes: if 3 are the same, we conclude that it's the same frame
    bool isSameFrame = false;
    int simCount = 0;
    int count = 0;
    for (final box1 in oldAllBoxes) {
      count += 1;
      if (count > 100) break;
      for (final box2 in allBoxes) {
        Vector4 v1 = Vector4.array([box1.rect.left, box1.rect.bottom, box1.rect.right, box1.rect.top]);
        Vector4 v2 = Vector4.array([box2.rect.left, box2.rect.bottom, box2.rect.right, box2.rect.top]);
        /*
        print("Vector 1: ");
        print(v1);
        print("Vector 2: ");
        print(v2);
        print((v1 - v2).distanceToSquared(Vector4.zero()));
        */
        if (box1.text == box2.text && (v1 - v2).distanceToSquared(Vector4.zero()) < 225) {
        //if (box1.text == box2.text /*&& box1.rect.overlaps(box2.rect)*/ && ) {
          simCount += 1;
          if (simCount >= 5) {
            isSameFrame = true;
            break;
          }
        }
      }
    }

    // TODO: now merge the boxes, if needed, and only repaint boxes, if wboxes have changed
    if (isSameFrame && wBoxes.length <= recCount) {
      // TODO: do not use old boxes, but mergedBoxes here
      for (final oldWBox in oldWBoxes) {
        bool foundOverlap = false;
        for (final wBox in wBoxes) {
          if (oldWBox.rect.overlaps(wBox.rect) || oldWBox.text == wBox.text) {
            foundOverlap = true;
            break;
          }
        }
        if (!foundOverlap) {
          wBoxes.add(oldWBox);
        }
      }
      //print("wBoxes.length: $wBoxes.length");
      //print("SAME FRAME");
    } else {
      //print("DIFFERENT FRAME");
      recCount = wBoxes.length;
    }
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      // TODO: do not pass recognisedText here. Instead pass the boxes and an indicator if repaint is necessary.
      final painter = MyTextDetectorPainter(
          wBoxes,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation, context);

      customPaint = CustomPaint(painter: painter);
    } else {
      customPaint = null;
    }
    isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
