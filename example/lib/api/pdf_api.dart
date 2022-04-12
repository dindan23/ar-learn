import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'dart:io';

class PDFApi {
  static Future<File> storeFile(String url, List<int> bytes) async {
    final filename = basename(url);
    final dir = await getApplicationDocumentsDirectory();

    final file = File('${dir.path}/$filename');
    print("ABSOLUTE");
    print(dir.path);
    List<int> intBytes = new List.from(bytes);
    await file.writeAsBytes(intBytes, flush: true);
    return file;
  }

  static Future<File> loadFirebase(String url) async {
    final refPDF = FirebaseStorage.instance.ref().child(url);
    final bytes = await refPDF.getData();

    return storeFile(url, bytes!);
  }
}
