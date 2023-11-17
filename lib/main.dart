import 'package:flutter/material.dart';
import 'image_upload_screen.dart'; // Import the new screen file
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallpaper App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallpaper App'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to the ImageUploadScreen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ImageUploadScreen()),
            );
          },
          child: Text('Upload Image'),
        ),
      ),
    );
  }
}
