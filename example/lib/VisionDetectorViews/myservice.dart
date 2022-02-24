import 'dart:ui';

class MyService {

  static final MyService _instance = MyService._internal();

  // passes the instantiation to the _instance object
  factory MyService() => _instance;

  //initialize variables in here
  MyService._internal() {
    _myVariable = Size(320, 240);
  }

  Size _myVariable = Size(320, 240);

  //short getter for my variable
  Size get myVariable => _myVariable;

  //short setter for my variable
  set myVariable(Size value) => myVariable = value;

  void setMyVariable(Size value) {
    _myVariable = value;
  }
}
