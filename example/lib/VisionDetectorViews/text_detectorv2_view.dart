import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:vector_math/vector_math.dart';

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

  String titleVar = 'NOT FOUND';

  @override
  void dispose() async {
    super.dispose();
    await textDetector.close();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: titleVar,
      customPaint: customPaint,
      onImage: (inputImage) {
        /* TODO: add inputImage to frameQueue
         * Call processImage and pass frameQueue together with inputImage
         * If in processImage() isBusy is false,
         * then the bestFrame in frameQueue can be fetched and the frameQueue can be emptied again
         * Otherwise, if frameQueue is empty, then just use the inputImage
         */
        processImage(inputImage);
      },
    );
  }

  // This is similar to the call to pytesseract.image_to_data()
  Future<void> processImage(InputImage inputImage) async {
    if (isBusy) return;
    isBusy = true;
    // TODO: maybe do the following expensive ocr call in an isolate or in the compute method???
    final recognisedText = await textDetector.processImage(inputImage,
        script: TextRecognitionOptions.DEFAULT);
    print('Found ${recognisedText.blocks.length} textBlocks');
    // TODO: store allboxes and wboxes here
    // TODO: while doing that, use TEXT CORRECTION / SPELL CHECKING according to our dictionary
    final Map<String, String> dict = HashMap();
    dict.addAll({
      "Abitur": "Abitur is defined",
      "Kapitel": "Kapitel is defined.",
      "Logarithmusfunktionen": "log is defined"
    });
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
        words.retainWhere((element) => dict.containsKey(element.text));
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
        if (box1.text == box2.text && box1.rect.overlaps(box2.rect)) {
          simCount += 1;
          if (simCount >= 3) {
            isSameFrame = true;
            break;
          }
        }
      }
    }

    // TODO: now merge the boxes, if needed, and only repaint boxes, if wboxes have changed
    if (isSameFrame && wBoxes.length <= recCount) {
      // TODO: do not use old boxes, but mergedBoxes here
      wBoxes = [];
      wBoxes.addAll(oldWBoxes);
      print(wBoxes.length);
      print("SAME FRAME");
    } else {
      print("DIFFERENT FRAME");
      recCount = wBoxes.length;
    }
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      // TODO: do not pass recognisedText here. Instead pass the boxes and an indicator if repaint is necessary.
      final painter = MyTextDetectorPainter(
          wBoxes,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);

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
