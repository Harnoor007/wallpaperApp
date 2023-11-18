import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'image_upload_screen.dart';
import 'wallpapers_screen.dart'; // Import the new file
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallpaper App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Add the 'routes' property and define your routes here
      routes: {
        '/wallpapers': (context) => WallpapersScreen(user: FirebaseAuth.instance.currentUser!), // Replace with the actual User object
        '/upload': (context) => ImageUploadScreen(user: FirebaseAuth.instance.currentUser!), // Replace with the actual User object
      },
      home: StreamBuilder(
        stream: _auth.authStateChanges(),
        builder: (context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // or some loading indicator
          }

          if (snapshot.hasData) {
            return WallpapersScreen(user: snapshot.data!);
          } else {
            return MySignInPage();
          }
        },
      ),
    );
  }
}

class MySignInPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount = await GoogleSignIn().signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential authResult = await _auth.signInWithCredential(credential);
        return authResult.user;
      }
    } catch (error) {
      print('Error signing in with Google: $error');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            User? user = await _signInWithGoogle();
            
          },
          child: Text('Sign In with Google'),
        ),
      ),
    );
  }
}
