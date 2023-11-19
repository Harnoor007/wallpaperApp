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
              onPressed: () => _launchURL('https://www.instagram.com/your_instagram_username/'),
              child: Text('Follow on Instagram'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _launchURL('https://www.youtube.com/c/YourChannel'),
              child: Text('Subscribe on YouTube'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _launchURL('https://twitter.com/your_twitter_username'),
              child: Text('Follow on Twitter'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _launchURL('https://www.linkedin.com/in/your_linkedin_profile/'),
              child: Text('Connect on LinkedIn'),
            ),
          ],
        ),
      ),
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

