import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'dart:typed_data';   
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
class WallpapersScreen extends StatelessWidget {
  final User user;

  WallpapersScreen({required this.user});

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

            return GestureDetector(
                onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => WallpaperDetailScreen(imageUrl: imageUrl),
            ),
          );
        },

              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
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

  WallpaperDetailScreen({required this.imageUrl});

  Future<void> _setWallpaper(BuildContext context, String imageUrl) async {
  try {
    // Fetch the image from the network
    var imageBytes = await networkImageToByte(imageUrl);

    if (imageBytes == null) {
      throw Exception('Failed to fetch image from the network');
    }

    // Save the image to a temporary file
    File tempFile = await saveImageToTempFile(imageBytes);

    // Show dialog to choose wallpaper location
    WallpaperLocation? selectedLocation =
        await _showLocationDialog(context);

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(imageUrl),
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
    );
  }
}