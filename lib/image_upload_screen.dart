import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageUploadScreen extends StatefulWidget {
  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _image;
  TextEditingController _imageUrlController = TextEditingController();

  Future<void> _uploadImage() async {
  if (_image == null) {
    // Handle no image selected
    return;
  }

  try {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageReference.putFile(_image!);

    // Show a loading indicator while uploading
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Uploading...'),
              LinearProgressIndicator(),
            ],
          ),
        );
      },
    );

    await uploadTask.whenComplete(() async {
      // Get the image URL from Firebase Storage
      String imageUrl = await storageReference.getDownloadURL();

      // Save the image URL to Firestore
      await FirebaseFirestore.instance.collection('wallpapers').add({
        'url': imageUrl,
        // Add additional fields if needed (e.g., user ID, timestamp)
      });

      // Clear the image selection and URL controller
      setState(() {
        _image = null;
        _imageUrlController.clear();
      });

      // Close the loading indicator
      Navigator.pop(context);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload successful!'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  } catch (error) {
    // Handle errors
    print('Error uploading image: $error');
    // Close the loading indicator in case of an error
    Navigator.pop(context);
    // Show an error message or implement desired error handling
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error uploading image'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}


  Widget _buildImagePicker() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

            if (pickedFile != null) {
              setState(() {
                _image = File(pickedFile.path);
              });
            }
          },
          child: Text('Pick Image'),
        ),
        _image != null
            ? Image.file(
                _image!,
                height: 100,
              )
            : Container(),
      ],
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton(
      onPressed: () async {
        await _uploadImage();
      },
      child: Text('Upload Image'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Image'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildImagePicker(),
            SizedBox(height: 20),
            _buildUploadButton(),
          ],
        ),
      ),
    );
  }
}
