import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:core';

class MyWallpapersScreen extends StatelessWidget {
  final User user;

  MyWallpapersScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Wallpapers'),
      ),
      body: MyWallpapersList(user: user),
    );
  }
}

class MyWallpapersList extends StatelessWidget {
  final User user;

  MyWallpapersList({required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('wallpapers')
          .where('uploadedBy', isEqualTo: user.email)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('You have not uploaded any wallpapers.'),
          );
        }

        return WallpaperGrid(snapshot.data!.docs);
      },
    );
  }
}

class WallpaperGrid extends StatelessWidget {
  final List<QueryDocumentSnapshot> wallpapers;

  WallpaperGrid(this.wallpapers);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // You can adjust the number of columns as needed
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: wallpapers.length,
      itemBuilder: (context, index) {
        var wallpaper = wallpapers[index];
        var wallpaperData = wallpaper.data() as Map<String, dynamic>;

        // Check if the required fields exist in the document
        if (wallpaperData.containsKey('url') &&
            wallpaperData.containsKey('timestamp')) {
          var imageUrl = wallpaperData['url'];
          var documentId = wallpaperData['timestamp'].toString();
          var title = wallpaperData['title'] ?? 'Untitled';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyWallpaperDetailScreen(
                    imageUrl: imageUrl,
                    documentId: documentId,
                  ),
                ),
              );
            },
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          );
        } else {
          // Display a more specific error message for debugging
          return ListTile(
            title: Text('Invalid Wallpaper Data: $wallpaperData'),
            // You might want to provide a different UI or message for these cases
          );
        }
      },
    );
  }
}

class MyWallpaperDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String documentId;

  MyWallpaperDetailScreen({required this.imageUrl, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Wallpaper Detail'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteWallpaper(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(imageUrl),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }



Future<void> _deleteWallpaper(BuildContext context) async {
  try {
    // Reference to the wallpaper in Firestore
    var firestoreReference = FirebaseFirestore.instance
        .collection('wallpapers')
        .where('url', isEqualTo: imageUrl);

    var wallpaperSnapshot = await firestoreReference.get();

    if (wallpaperSnapshot.docs.isNotEmpty) {
      var wallpaperData = wallpaperSnapshot.docs.first.data() as Map<String, dynamic>;
      var documentId = wallpaperSnapshot.docs.first.id;

      // Get the filename from the URL
      var url = wallpaperData['url'];
      var filename = url.split('/').last.split('?').first;

      print('Attempting to delete file with filename: $filename');

      // Remove the wallpaper from Firebase Storage
      var storageReference = FirebaseStorage.instance.ref().child(filename);

      try {
        await storageReference.delete();
        print('Wallpaper deleted from storage successfully!');
      } catch (storageError) {
        print('Error deleting wallpaper from storage: $storageError');
        // Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting wallpaper from storage'),
            duration: Duration(seconds: 2),
          ),
        );
        return; // Exit the function if storage deletion fails
      }

      // Remove the wallpaper from Cloud Firestore
      await FirebaseFirestore.instance
          .collection('wallpapers')
          .doc(documentId)
          .delete();
      print('Wallpaper deleted from Firestore successfully!');

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wallpaper deleted successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back to the My Wallpapers list screen
      Navigator.pop(context);
    } else {
      // Show an error message if the document is not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wallpaper document not found.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    // Print the error message to the console
    print('Error deleting wallpaper: $e');

    // Show a generic error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error deleting wallpaper'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

}

