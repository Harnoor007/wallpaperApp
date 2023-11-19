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
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.indigo,
        colorScheme: ColorScheme.dark().copyWith(
          secondary: Colors.pink,
        ),
        // Other theme configurations for dark mode
      ),
      themeMode: ThemeMode.system, // This makes the app follow the system theme
      // Add the 'routes' property and define your routes here
      routes: {
        '/wallpapers': (context) => WallpapersScreen(user: FirebaseAuth.instance.currentUser!),
        '/upload': (context) => ImageUploadScreen(user: FirebaseAuth.instance.currentUser!),
      },
      home: StreamBuilder(
        stream: _auth.authStateChanges(),
        builder: (context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/ic_launcher.png', // Replace with the actual path to your app icon
              width: 100, // Adjust the size accordingly
              height: 100,
            ),
            SizedBox(height: 16),
            Text(
              'Share and Explore amazing wallpapers.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                User? user = await _signInWithGoogle();
              },
              child: Text('Sign In with Google'),
            ),
          ],
        ),
      ),
    );
  }
}

