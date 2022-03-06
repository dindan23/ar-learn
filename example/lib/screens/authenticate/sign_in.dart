import 'package:google_ml_kit_example/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit_example/main.dart';

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {

  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(

        title: Text('Sign In'),
      ),
      body: Container(
        alignment: Alignment.center,
        child: RaisedButton(
          child: Text('Anonymous Sign In'),
          onPressed: () async {
            dynamic result = await _auth.signInAnon();
            if(result == null){
              print('error signing in');
            } else {
              print('signed in');
              print(result);
              runApp(MyApp());
            }
          },
        ),
      ),
    );
  }
}