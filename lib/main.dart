import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:guid_me/pages/landing-page.dart';
import 'package:guid_me/pages/result-view.dart';

void main(){
   runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       debugShowCheckedModeBanner: false,
       home:LandingPage(),
    );
  }
}
