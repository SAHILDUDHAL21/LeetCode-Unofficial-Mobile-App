import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:leetcode_unofficial/screens/stats_page.dart';


class LoginPage extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('userBox');
    String? savedUsername = box.get('username');

    // skip login and go to stats page
    if (savedUsername != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StatsPage()),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text('LeetCode Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'LeetCode Username',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String username = _usernameController.text.trim();
                if (username.isNotEmpty) {
                  box.put('username', username); // Store username
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => StatsPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a username')),
                  );
                }
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}