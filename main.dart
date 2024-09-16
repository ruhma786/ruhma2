import 'package:flutter/material.dart';

void main() => runApp(ProfileApp());

class ProfileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProfilePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProfilePage extends StatelessWidget {
  final String name = 'Ruhma';
  final String email = 'ruhma123@gmail.com';
  final String phone = '+923039117110';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile App'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              //backgroundColor: Colors.amber,
              //https://images.app.goo.gl/5BN4cxFX2sPggP2J9
              //
              backgroundImage: NetworkImage('https://flutter.dev/assets/images/shared/brand/flutter/logo/flutter-lockup.png'),

            ),
            SizedBox(height: 16),
            Text(
              name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,),
            ),
            SizedBox(height: 8),
            Text(
              email,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              phone,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}