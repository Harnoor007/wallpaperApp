import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'dart:typed_data';   
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'my_wallpapers_screen.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_sign_in/google_sign_in.dart';


class WallpapersScreen extends StatelessWidget {
  final User user;

  WallpapersScreen({required this.user});
 
  Future<void> _signOut(BuildContext context) async {
  try {
    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    // Clear the authentication state using google_sign_in
    await GoogleSignIn().signOut();

    // Navigate back to the sign-in screen or any other appropriate screen
    Navigator.pop(context);
  } catch (e) {
    print('Error signing out: $e');
    // Handle error, show a snackbar, etc.
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallpapers'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
  child: ListView(
    children: [
      UserAccountsDrawerHeader(
        accountName: Text(user.displayName ?? ''),
        accountEmail: Text(user.email ?? ''),
        currentAccountPicture: CircleAvatar(
          backgroundImage: NetworkImage(user.photoURL ?? ''),
        ),
      ),
      ListTile(
        title: Text('View Wallpapers'),
        onTap: () {
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: Text('Upload Image'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/upload');
        },
      ),
      ListTile(
        title: Text('My Wallpapers'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyWallpapersScreen(user: user),
            ),
          );
        },
      ),
      ListTile(
        title: Text('Follow Us'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/follow_us');
        },
      ),
      // Add the sign-out option
      ListTile(
        title: Text('Sign Out'),
        onTap: () async {
          // Call the sign-out function
          await _signOut(context);
        },
      ),
    ],
  ),
),

      body: WallpaperList(),
    );
  }
}

class WallpaperList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('wallpapers').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No wallpapers available.'),
          );
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var wallpaper = snapshot.data!.docs[index];
            var imageUrl = wallpaper['url'];
            var uploadedBy = wallpaper['uploadedBy'];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WallpaperDetailScreen(
                      imageUrl: imageUrl,
                      uploadedBy: uploadedBy, // Pass the actual uploadedBy information
                     ),
                  ),
                );
              },
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            );
          },
        );
      },
    );
  }
}
enum WallpaperLocation {
  HOME_SCREEN,
  LOCK_SCREEN,
  BOTH_SCREENS,
}

class WallpaperDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String uploadedBy;

  WallpaperDetailScreen({required this.imageUrl,required this.uploadedBy,});

Future<void> _setWallpaper(BuildContext context, String imageUrl) async {
  try {
    // Show loading indicator while fetching the image
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Fetch the image from the network in the background
    var imageBytes = await networkImageToByte(imageUrl);

    if (imageBytes == null) {
      throw Exception('Failed to fetch image from the network');
    }

    // Save the image to a temporary file
    File tempFile = await saveImageToTempFile(imageBytes);

    // Close the loading indicator dialog
    Navigator.pop(context);

    // Show dialog to choose wallpaper location
    WallpaperLocation? selectedLocation = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Wallpaper Location'),
          content: Column(
            children: [
              ListTile(
                title: Text('Home Screen'),
                onTap: () {
                  Navigator.pop(context, WallpaperLocation.HOME_SCREEN);
                },
              ),
              ListTile(
                title: Text('Lock Screen'),
                onTap: () {
                  Navigator.pop(context, WallpaperLocation.LOCK_SCREEN);
                },
              ),
              ListTile(
                title: Text('Both Screens'),
                onTap: () {
                  Navigator.pop(context, WallpaperLocation.BOTH_SCREENS);
                },
              ),
            ],
          ),
        );
      },
    );

    if (selectedLocation != null) {
      // Set the image as wallpaper
      int location = _convertLocation(selectedLocation);
      bool result = await WallpaperManager.setWallpaperFromFile(
        tempFile.path,
        location,
      );

      if (result) {
        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wallpaper set successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting wallpaper'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  } catch (e) {
    print('Error setting wallpaper: $e');
    // Show an error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error setting wallpaper'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}


  Future<Uint8List?> networkImageToByte(String url) async {
    var response = await http.get(Uri.parse(url));
    return response.bodyBytes;
  }

  Future<File> saveImageToTempFile(Uint8List imageBytes) async {
    Directory tempDir = await getTemporaryDirectory();
    File tempFile = File('${tempDir.path}/temp_wallpaper.jpg');
    await tempFile.writeAsBytes(imageBytes);
    return tempFile;
  } 

  Future<WallpaperLocation?> _showLocationDialog(BuildContext context) async {
    WallpaperLocation? selectedLocation;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Wallpaper Location'),
          content: Column(
            children: [
              ListTile(
                title: Text('Home Screen'),
                onTap: () {
                  Navigator.pop(context, WallpaperLocation.HOME_SCREEN);
                },
              ),
              ListTile(
                title: Text('Lock Screen'),
                onTap: () {
                  Navigator.pop(context, WallpaperLocation.LOCK_SCREEN);
                },
              ),
              ListTile(
                title: Text('Both Screens'),
                onTap: () {
                  Navigator.pop(context, WallpaperLocation.BOTH_SCREENS);
                },
              ),
            ],
          ),
        );
      },
    ).then((value) {
      selectedLocation = value;
    });

    return selectedLocation;
  }

int _convertLocation(WallpaperLocation location) {
  switch (location) {
    case WallpaperLocation.HOME_SCREEN:
      return WallpaperManager.HOME_SCREEN;
    case WallpaperLocation.LOCK_SCREEN:
      return WallpaperManager.LOCK_SCREEN;
    case WallpaperLocation.BOTH_SCREENS:
      return WallpaperManager.BOTH_SCREEN;
    default:
      throw Exception("Invalid wallpaper location");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallpaper Detail'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
                SizedBox(height: 20),
                // Display uploaded by information
                Text('Uploaded by: $uploadedBy'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await _setWallpaper(context, imageUrl);
                  },
                  child: Text('Set as Wallpaper'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}