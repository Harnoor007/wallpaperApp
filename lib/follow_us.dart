import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FollowUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Follow Us'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _launchURL('https://www.instagram.com/harnoor.29/'),
              child: Text('Follow on Instagram'),
            ),
            ElevatedButton(
              onPressed: () => _launchURL('https://www.youtube.com/'),
              child: Text('Subscribe on YouTube'),
            ),
            ElevatedButton(
              onPressed: () => _launchURL('https://twitter.com/'),
              child: Text('Follow on Twitter'),
            ),
            ElevatedButton(
              onPressed: () => _launchURL('https://www.linkedin.com/in/harnoorbirdi/'),
              child: Text('Connect on LinkedIn'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw Exception('Could not launch $url');
    }
  }
}
