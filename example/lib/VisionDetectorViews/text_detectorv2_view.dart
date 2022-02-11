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

  String titleVar = 'NOT FOUND';
  String wordFinder = 'Kapitel';
  String varz = '';

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
    // TODO: maybe do this expensive ocr call in an isolate or in the compute method???
    final recognisedText = await textDetector.processImage(inputImage,
        script: TextRecognitionOptions.DEFAULT);
    print('Found ${recognisedText.blocks.length} textBlocks');
    // TODO: store allboxes and wboxes here
    // TODO: while doing that, use TEXT CORRECTION / SPELL CHECKING according to our dictionary
    // TODO: then analyse allboxes: if 3 are the same, we conclude that it's the same frame
    // TODO: now merge the boxes, if needed, and only repaint boxes, if wboxes have changed
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      // TODO: do not pass recognisedText here. Instead pass the boxes and an indicator if repaint is necessary.
      final painter = MyTextDetectorPainter(
          recognisedText,
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
