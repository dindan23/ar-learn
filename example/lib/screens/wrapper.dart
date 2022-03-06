import 'package:google_ml_kit_example/screens/authenticate/authenticate.dart';
import 'package:google_ml_kit_example/screens/home/home.dart';
import 'package:flutter/material.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    // return either the Home or Authenticate widget
    return Authenticate();
    
  }
}