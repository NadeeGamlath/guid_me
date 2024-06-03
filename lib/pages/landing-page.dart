import 'package:flutter/material.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/getwidget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

import 'dashboard.dart';
import 'db-controller.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkStoredValue();
  }
Future<void> _showConfirmationDialog(String value){
    return showDialog<void>(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Do you want to save your name as "$value" '),
          actions: [
            TextButton(
                onPressed: (){
                  Navigator.of(context).pop();
                },
              child: Text("Cancle"),
            ),
            TextButton(
              onPressed: (){
                _saveToFile(value);
                Navigator.of(context).pop();
              },
              child: Text("Ok"),
            ),
          ],
        );
      }
    );
}
Future<void> _saveToFile(String value) async {
  Map<String, dynamic> data = {'name': value};
  await DatabaseController.instance.insertData('user_data', data);
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => Dashboard(storedValue: value)),
  );
  }
  Future<void> _checkStoredValue() async {
    Database db = await DatabaseController.instance.database;
    List<Map<String, dynamic>> result = await db.rawQuery('SELECT * FROM user_data');
    if (result.isNotEmpty) {
      String storedValue = result[0]['name'];
      if (storedValue.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard(storedValue: storedValue)),
        );
      }
    }
  }
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                child: Image.asset(
                  'images/bg.jpeg',
                  // Replace with the actual path to your image
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                color: Colors.white.withOpacity(
                    0.78), // Adjust the opacity as needed
              ),
              Positioned(
                left: 0.0,
                right:0.0,
                top:100.0,
                child:Image.asset(
                  'images/ab.png',
                  // Replace with the actual path to your image
                  fit: BoxFit.cover,
                  width: 100.0,
                  height: 92.0,
                ),
              ),
              Positioned(
                left: 20.0,
                top: 400.0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Name",
                      style: TextStyle(fontSize: 30),
                    ),
                  SizedBox(width: 30), // Add some space between text and text field
                    Container(
                      width: 200, // Adjust the width as needed
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned( // Aligns the button to the center horizontally
                  left: 0,
                  right: 0,
                  top: 600,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GFButton(
                          onPressed :(){
                            String value = _nameController.text;
                            _showConfirmationDialog(value);
                          },
                           child:Text("GO...",
                           style: TextStyle(
                             fontSize: 20
                           ),
                           ),
                           size: GFSize.LARGE,
                           color: hexColor("62A1AA"),
                      ),
                    ],
                  ),
                ),
            ]
        ),
      ),
    );
  }
  hexColor(String hexColor) {
    final hexCode = hexColor.replaceAll("#", "");
    return Color(int.parse("FF$hexCode", radix: 16));
  }
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
