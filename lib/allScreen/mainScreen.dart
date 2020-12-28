

import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: Text('Main Screen',style: TextStyle(color: Colors.black,
        fontWeight: FontWeight.bold,
        ),),
        centerTitle: true,
      ),
    );
  }
}
