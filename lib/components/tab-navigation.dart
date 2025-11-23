import 'package:flutter/material.dart';

class BottomTabNavigation extends StatefulWidget {
  @override
  _BottomTabNavigationState createState() => _BottomTabNavigationState();
}

class _BottomTabNavigationState extends State<BottomTabNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    Center(child: Text('Home Screen', style: TextStyle(fontSize: 24))),
    Center(child: Text('Reader Screen', style: TextStyle(fontSize: 24))),
    Center(child: Text('Profile Screen', style: TextStyle(fontSize: 24))),
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
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book), // or Icons.book, Icons.import_contacts
            label: 'Reader',
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