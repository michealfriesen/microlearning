import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'home.dart'; // Import your home.dart file

void main() {
  // initialize logging 
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      home: MainTabNavigator(),
    );
  }
}

class MainTabNavigator extends StatefulWidget {
  @override
  State<MainTabNavigator> createState() => _MainTabNavigatorState();
}

class _MainTabNavigatorState extends State<MainTabNavigator> {
  int _currentIndex = 0;

  // List of screens for each tab
  final List<Widget> _screens = [
    HomePage(), // Your stretchy nodes screen
    FilePickerScreen(), // File picker screen
    ProfileScreen(), // Placeholder for third tab
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.bubble_chart),
            label: 'Graph',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Move your file picker logic to a separate screen
class FilePickerScreen extends StatefulWidget {
  @override
  State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  final Logger log = Logger('FilePicker');
  String? _filePath;
  String? _fileName;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() { 
        _fileName = result.files.single.name; 
        _filePath = result.files.single.path;
      });

      log.info('File selected: $_fileName'); 
      log.info('Path: $_filePath');

      if (result.files.single.bytes != null) {
        log.info('File size: ${result.files.single.bytes!.length} bytes');
      }
    } else { 
      log.info("Cancelled user pick");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Picker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Text("something something file something"),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _pickFile, child: Text("Press me!")), 
            SizedBox(height: 20), 
            if (_fileName != null)
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'File Uploaded!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Selected: $_fileName'),
                    if (_filePath != null)
                      Text('Path: $_filePath', 
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
          ],  
        ),   
      ),     
    );
  }
}

// Placeholder for the third tab
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Text('Profile Screen - Add your content here!'),
      ),
    );
  }
}