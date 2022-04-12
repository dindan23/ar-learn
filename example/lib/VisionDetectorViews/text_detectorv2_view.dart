import 'package:flutter/material.dart';

import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_ml_kit_example/api/pdf_api.dart';
import 'package:vector_math/vector_math.dart' as vec;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'myservice.dart';
import 'dart:typed_data';
import '../api/pdf_api.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:video_player/video_player.dart';

import 'camera_view.dart';
import 'painters/my_text_detector_painter.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class TextDetectorV2View extends StatefulWidget {
  @override
  _TextDetectorViewV2State createState() => _TextDetectorViewV2State();
}

final CollectionReference collectionRef = FirebaseFirestore.instance
    .collection('Content_User_C4U5KdZ9YVOPOfJLP23daGsOsEH2');

Map<String, Uint8List> keyToDataMap = {};
Map<String, String> keyToLinkMap = {};

class DatabaseServices {
  List rawDatabase = [];

  SetPackage(String pck) async {
    // TODO: Package-Auswahl mit If-Abfrage oder Alternativweg
    if (pck == 'A') {
      //to get data from a single/particular document alone.
      //var temp = await collectionRef.doc("<your document ID here>").get();

      // to get data from all documents sequentially
      await collectionRef.get().then((querySnapshot) {
        for (var result in querySnapshot.docs) {
          rawDatabase.add(result.data());
        }
      });
      rawDatabase.forEach((element) {
        var keyword = element["Keyword"];
        var link = element["Link"];
        keyToLinkMap.putIfAbsent(keyword, () => link);

        print("downloaded database element: ");
        print(element);

        firebase_storage.Reference ref =
            firebase_storage.FirebaseStorage.instance.ref().child(link);
        ref.getData(10000000).then((data) {
          keyToDataMap.putIfAbsent(keyword, () => data!);
          if (link.toString().endsWith("pdf")) {
            print("There is a pdf file for " + keyword);
            PDFApi.storeFile(link, data!);
          }
        });
      });
    }
    ;
  }
}

class _BumbleBeeRemoteVideo extends StatefulWidget {
  @override
  _BumbleBeeRemoteVideoState createState() => _BumbleBeeRemoteVideoState();
}

class _BumbleBeeRemoteVideoState extends State<_BumbleBeeRemoteVideo> {
  late VideoPlayerController _controller;

  Future<ClosedCaptionFile> _loadCaptions() async {
    final String fileContents = await DefaultAssetBundle.of(context)
        .loadString('assets/bumble_bee_captions.vtt');
    return WebVTTCaptionFile(
        fileContents); // For vtt files, use WebVTTCaptionFile
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    _controller.addListener(() {
      setState(() {});
    });
    _controller.setLooping(true);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(padding: const EdgeInsets.only(top: 20.0)),
          const Text('With remote mp4'),
          Container(
            padding: const EdgeInsets.all(20),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(_controller),
                  ClosedCaption(text: _controller.value.caption.text),
                  _ControlsOverlay(controller: _controller),
                  VideoProgressIndicator(_controller, allowScrubbing: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({Key? key, required this.controller})
      : super(key: key);

  static const List<Duration> _exampleCaptionOffsets = <Duration>[
    Duration(seconds: -10),
    Duration(seconds: -3),
    Duration(seconds: -1, milliseconds: -500),
    Duration(milliseconds: -250),
    Duration(milliseconds: 0),
    Duration(milliseconds: 250),
    Duration(seconds: 1, milliseconds: 500),
    Duration(seconds: 3),
    Duration(seconds: 10),
  ];
  static const List<double> _examplePlaybackRates = <double>[
    0.25,
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    10.0,
  ];

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
            color: Colors.black26,
            child: const Center(
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 100.0,
                semanticLabel: 'Play',
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
        Align(
          alignment: Alignment.topLeft,
          child: PopupMenuButton<Duration>(
            initialValue: controller.value.captionOffset,
            tooltip: 'Caption Offset',
            onSelected: (Duration delay) {
              controller.setCaptionOffset(delay);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<Duration>>[
                for (final Duration offsetDuration in _exampleCaptionOffsets)
                  PopupMenuItem<Duration>(
                    value: offsetDuration,
                    child: Text('${offsetDuration.inMilliseconds}ms'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.captionOffset.inMilliseconds}ms'),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: controller.value.playbackSpeed,
            tooltip: 'Playback speed',
            onSelected: (double speed) {
              controller.setPlaybackSpeed(speed);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (final double speed in _examplePlaybackRates)
                  PopupMenuItem<double>(
                    value: speed,
                    child: Text('${speed}x'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.playbackSpeed}x'),
            ),
          ),
        ),
      ],
    );
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

  String titleVar = 'SCAN';

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
        barrierDismissible: true, // if false: user must tap button
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(word),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  // Bild anzeigen
                  //Image.network('https://picsum.photos/250?image=9'),
                  keyToLinkMap.containsKey(word)
                      ? (keyToLinkMap[word]!.endsWith('pdf')
                          ? TextButton(
                              child: Text("Open PDF"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PDFScreen(path: keyToDataMap[word]!),
                                  ),
                                );
                              })
                          : (keyToLinkMap[word]!.endsWith('PNG')
                              ?

                              //Image.network(definition),

                              Image.memory(
                                  keyToDataMap[word]!,
                                  fit: BoxFit.cover,
                                )
                              : _BumbleBeeRemoteVideo()))
                      : _BumbleBeeRemoteVideo(),//Text(errorMsg != null ? errorMsg : "No data stored"),
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
            onPressed: () => _showMyDialog(wBox.text, keyToLinkMap[wBox.text]!),
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
        words.retainWhere((element) => keyToLinkMap.containsKey(
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

class PDFScreen extends StatefulWidget {
  final Uint8List? path;

  PDFScreen({Key? key, this.path}) : super(key: key);

  _PDFScreenState createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> with WidgetsBindingObserver {
  final Completer<PDFViewController> _controller =
      Completer<PDFViewController>();
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Document"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            pdfData: widget.path,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: currentPage!,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            // if set to true the link is handled in flutter
            onRender: (_pages) {
              setState(() {
                pages = _pages;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
              print(error.toString());
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
              print('$page: ${error.toString()}');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _controller.complete(pdfViewController);
            },
            onLinkHandler: (String? uri) {
              print('goto uri: $uri');
            },
            onPageChanged: (int? page, int? total) {
              print('page change: $page/$total');
              setState(() {
                currentPage = page;
              });
            },
          ),
          errorMessage.isEmpty
              ? !isReady
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Container()
              : Center(
                  child: Text(errorMessage),
                )
        ],
      ),
      floatingActionButton: FutureBuilder<PDFViewController>(
        future: _controller.future,
        builder: (context, AsyncSnapshot<PDFViewController> snapshot) {
          if (snapshot.hasData) {
            return FloatingActionButton.extended(
              label: Text("Go to ${pages! ~/ 2}"),
              onPressed: () async {
                await snapshot.data!.setPage(pages! ~/ 2);
              },
            );
          }

          return Container();
        },
      ),
    );
  }
}
