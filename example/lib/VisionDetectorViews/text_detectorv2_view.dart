import 'package:flutter/material.dart';

import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:vector_math/vector_math.dart' as vec;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'myservice.dart';
import 'dart:typed_data';

import 'camera_view.dart';
import 'painters/my_text_detector_painter.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class TextDetectorV2View extends StatefulWidget {
  @override
  _TextDetectorViewV2State createState() => _TextDetectorViewV2State();
}

final CollectionReference collectionRef =
FirebaseFirestore.instance.collection('Content_User_9F85Fl7sW4XXtE8vBfpecDgwvmr1');


Map<String, String> keyToLinkMap = {};
Map<String, String> dict = {};

class DatabaseServices {
  List rawDatabase = [];

  SetPackage(String pck)async{

    // TODO: Package-Auswahl mit If-Abfrage oder Alternativweg
    if(pck == 'A') {
      //to get data from a single/particular document alone.
      //var temp = await collectionRef.doc("<your document ID here>").get();

      // to get data from all documents sequentially
      await collectionRef.get().then((querySnapshot) {
        for (var result in querySnapshot.docs) {
          rawDatabase.add(result.data());
        }
      });
      rawDatabase.forEach((element) {
        var getKey = element["Keyword"];
        //dict["$getKey"] = element["Link"];
        print(getKey == 'Integral');
        keyToLinkMap.putIfAbsent(getKey, () => element["Link"]);

        firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
            .ref()
            .child(element["Link"]);
        ref.getDownloadURL().then((url) {dict["$getKey"] = url;});
      });
    };
  }
}


class _TextDetectorViewV2State extends State<TextDetectorV2View> {
  MyService _myService = MyService();
  TextDetectorV2 textDetector = GoogleMlKit.vision.textDetectorV2();
  bool isBusy = false;
  CustomPaint? customPaint;
  List<TextElement> allBoxes = [];
  List<TextElement> wBoxes = [];
  List<TextElement> oldAllBoxes = [];
  List<TextElement> oldWBoxes = [];
  int recCount = 0; // number of recognized words (wBoxes)


  List<Widget> widgets = <Widget>[];
  late InputImage inputImg;
  Uint8List imageBytes = Uint8List(0);
  String errorMsg = "Error";
  int testCount = 0;

  _TextDetectorViewV2State() {
    /*
    firebase_storage.FirebaseStorage.instance
        .ref().child('UserUpload/9F85Fl7sW4XXtE8vBfpecDgwvmr1/Hammerrrrr.PNG').getData(10000000).then((data) =>
        setState(() {
          imageBytes = data!;
        })
    ).catchError((e) =>
        setState(() {
          errorMsg = e.error;
        })
    );
     */
  }

  String titleVar = 'Sucht nach Definitionen';

  @override
  void dispose() async {
    super.dispose();
    await textDetector.close();
  }

  @override
  Widget build(BuildContext context) {
    var img = imageBytes != null ? Image.memory(
      imageBytes,
      fit: BoxFit.cover,
    ) : Text(errorMsg != null ? errorMsg : "Loading...");

    Future<void> _showMyDialog(String word, String definition) async {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // if false: user must tap button
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(word),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[

                  // Bild anzeigen
                  //Image.network('https://picsum.photos/250?image=9'),

                  //Image.network(definition),
                  img,
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

    final mediaQueryData = MediaQuery.of(context);
    final size = mediaQueryData.size;

    final camView = CameraView(
      title: titleVar,
      customPaint: customPaint,
      onImage: (inputImage) {
        inputImg = inputImage;
        processImage(inputImage);
      },
    );

    widgets = <Widget>[camView];

    for (final wBox in wBoxes) {
      final hFactor =
          _myService.myVariable.width / inputImg.inputImageData!.size.height;
      final vFactor =
          _myService.myVariable.height / inputImg.inputImageData!.size.width;

      final heurLeft = wBox.rect.left * hFactor;
      final heurTop = AppBar().preferredSize.height +
          (wBox.rect.top + (wBox.rect.bottom - wBox.rect.top) / 2) * vFactor;

      widgets.add(Positioned(
          left: heurLeft,
          top: heurTop,
          child: OutlinedButton(
            onPressed: () => _showMyDialog(wBox.text, dict[wBox.text]!),
            child: Text(wBox.text),
            style: OutlinedButton.styleFrom(
              primary: Colors.lightGreenAccent,
              backgroundColor: Color.fromRGBO(0, 0, 0, 0.3),
            ),
          )));
    }
    return Stack(
        alignment: Alignment.topLeft, fit: StackFit.expand, children: widgets);
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
            element.text)); //|| fuzzyContains(dict, element.text));
        for (final textWord in words) {
          wBoxes.add(textWord);
        }
      }
    }
    // TODO: then analyse allboxes: if 5 are the same, we conclude that it's the same frame
    bool isSameFrame = false;
    int simCount = 0;
    int count = 0;
    for (final box1 in oldAllBoxes) {
      count += 1;
      if (count > 100) break;
      for (final box2 in allBoxes) {
        vec.Vector4 v1 = vec.Vector4.array(
            [box1.rect.left, box1.rect.bottom, box1.rect.right, box1.rect.top]);
        vec.Vector4 v2 = vec.Vector4.array(
            [box2.rect.left, box2.rect.bottom, box2.rect.right, box2.rect.top]);
        /*
        print("Vector 1: ");
        print(v1);
        print("Vector 2: ");
        print(v2);
        double n123 = (v1 - v2).distanceToSquared(Vector4.zero());
        if(n123 < 225) {
          print(box1.text);
          print(box2.text);
          print(n123);
        }
        */
        if (box1.text == box2.text &&
            (v1 - v2).distanceToSquared(vec.Vector4.zero()) < 225) {
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
          // the next line means that it's ok if several same words are recognized,
          // (but in the merge, an old box is only taken if the word is not already in the new boxes)
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

    // cache images as soon as they are recognized
    wBoxes.forEach((wBox) {
      if(testCount < 1) {
        testCount += 1;
        print("in CACHING code...");
        if (keyToLinkMap.containsKey(wBox.text)) {
          firebase_storage.FirebaseStorage.instance
              .ref().child(keyToLinkMap[wBox.text]!).getData(
              10000000).then((data) =>
              setState(() {
                imageBytes = data!;
                print("IMAGE BYTES LENGTH: ");
                print(imageBytes.length);
              })
          ).catchError((e) =>
              setState(() {
                errorMsg = e.error;
              })
          );
        }
      }
    });

    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      // TODO: do not pass recognisedText here. Instead pass the boxes and an indicator if repaint is necessary.
      final painter = MyTextDetectorPainter(
          wBoxes,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation,
          context);

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
