import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainState());
  }
}

class MainState extends StatefulWidget {
  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<MainState> {
  String? _filePath;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
	  _filePath = file.path;
      print(file.path);
      print(file.stat());
    } else {
      print("canceled input");
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text("something something file something"),
            ElevatedButton(onPressed: _pickFile, child: Text("Press me!")),
          ],
        ),
      ),
    );
  }
}
