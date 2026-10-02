import 'package:flutter/material.dart';

class PasswordRecoveryScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Password Recovery'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
              // Implement password recovery functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recovery email sent!')),
              );

                if (_emailController.text.isNotEmpty) {
                  // Proceed with password recovery
                  print('Recovering password for ${_emailController.text}');
                } else {
                  // Show error message
                  print('Please enter your email');
                }
              },

              child: Text('Recover Password'),
            ),
            const SizedBox(height: 20),
            const Text(
              "Security Question",
              style: TextStyle(fontSize: 16),
            ),
            TextField(
              decoration: const InputDecoration(labelText: "What is your pet's name?"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Navigate back to the login screen
              },


              child: Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
