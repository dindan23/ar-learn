import 'dart:io';

import 'package:camera/camera.dart';
import 'package:google_ml_kit_example/NlpDetectorViews/entity_extraction_view.dart';
import 'package:google_ml_kit_example/NlpDetectorViews/language_translator_view.dart';
import 'package:google_ml_kit_example/NlpDetectorViews/smart_reply_view.dart';
import 'package:google_ml_kit_example/VisionDetectorViews/object_detector_view.dart';
import 'package:google_ml_kit_example/screens/wrapper.dart';

import 'NlpDetectorViews/language_identifier_view.dart';
import 'VisionDetectorViews/detector_views.dart';
import 'package:flutter/material.dart';

import 'VisionDetectorViews/text_detectorv2_view.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:google_ml_kit_example/VisionDetectorViews/text_detectorv2_view.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  cameras = await availableCameras();
  runApp(Init());

}

class Init extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Wrapper(),
    );
  }
}


class MyApp extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {

  String userSet = '';

  @override
  Widget build(BuildContext context) {

    String dropdownValue = 'Package';

    return Scaffold(
      appBar: AppBar(
        title: Text('Google ML Kit Demo App'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [


                  DropdownButton<String>(
                    items: <String>['MT-1', 'LinAlg-3', 'EIP-1', 'DigMed'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      userSet = newValue!;
                      DatabaseServices().SetPackage(newValue);
                      print('Package Set: ' + userSet);

                      },
                  ),


                      CustomCard(
                        'Text Detector',
                        TextDetectorView(),
                        featureCompleted: true,
                      ),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  final String _label;
  final Widget _viewPage;
  final bool featureCompleted;

  const CustomCard(this._label, this._viewPage,
      {this.featureCompleted = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Theme.of(context).primaryColor,
        title: Text(
          _label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          if (Platform.isIOS && !featureCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text(
                    'This feature has not been implemented for iOS yet')));
          } else
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => _viewPage));
        },
      ),
    );
  }
}
