import 'package:attendance_hacker_iith/attendance_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController rollNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isDevMode = false;

  @override
  void initState() {
    super.initState();
    loadLoginInfo();
  }

  Future<void> loadLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final rollNumber = prefs.getString('rollNumber');
    final password = prefs.getString('password');
    if (rollNumber != null && password != null) {
      rollNumberController.text = rollNumber;
      passwordController.text = password;
    }
  }

  void _submit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendancePage(
          rollNumber: rollNumberController.text,
          password: passwordController.text,
          devMode: _isDevMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IITH Attendance Hacker'),
        backgroundColor: Colors.black,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: rollNumberController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Roll Number',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: passwordController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureText,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                    textStyle: const TextStyle(fontSize: 18.0),
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Dev Mode', style: TextStyle(color: Colors.white)),
                Switch(
                  value: _isDevMode,
                  onChanged: (value) {
                    setState(() {
                      _isDevMode = value;
                    });
                  },
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.black87,
                  activeColor: Colors.deepPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
