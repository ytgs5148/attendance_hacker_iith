import 'package:attendance_hacker_iith/attendance_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController rollNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _submit() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AttendancePage(
              rollNumber: rollNumberController.text, password: passwordController.text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IITH Attendance Hacker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: rollNumberController,
              decoration: const InputDecoration(
                labelText: 'Roll Number',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
