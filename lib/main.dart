import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_firebase_crud_app/screens/auth/auth_screen.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

Future<void> main() async {
  Gemini.init(
      apiKey:
          'AIzaSyBj2VLUb95TcjQU01sdTF6Zz0AvnMaCk1I'); //get api key ==> https://aistudio.google.com/app/apikey
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter firebase',
      home: AuthScreen(),
    );
  }
}
