import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


class ImageUploadScreen extends StatefulWidget {
  final User user;

  ImageUploadScreen(this.user);

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
        String imageUrl = await storageReference.getDownloadURL();

        await FirebaseFirestore.instance.collection('wallpapers').add({
          'url': imageUrl,
          'uploadedBy': widget.user.email, // Save the user's email
          'timestamp': FieldValue.serverTimestamp(), // Save the upload timestamp
        });

        setState(() {
          _image = null;
          _imageUrlController.clear();
        });

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload successful!'),
            duration: Duration(seconds: 2),
          ),
        );
      });
    } catch (error) {
      Navigator.pop(context);

      print('Error uploading image: $error');

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
