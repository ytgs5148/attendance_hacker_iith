import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

class AttendancePage extends StatefulWidget {
  final String rollNumber;
  final String password;

  const AttendancePage({
    super.key,
    required this.rollNumber,
    required this.password,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String? webIdentifier;
  String? name;
  String statusMessage = "Not logged in";
  late String fcmId;
  List<dynamic> timetable = [];
  dynamic selectedCourse;

  final String baseURL = "https://erp.iith.ac.in/MobileAPI/";
  final String loginPath = "GetMobileAppValidatePassword";
  final String timetablePath = "GetStudentTimeTableForAttendance";
  final String attendancePath = "UpSertStudentAttendanceDetails";

  @override
  void initState() {
    super.initState();
    loadConfig();
    attemptLogin(widget.rollNumber, widget.password);
  }

  void loadConfig() {
    setState(() {
      webIdentifier = null;
      name = null;
      fcmId = generateFakeFcmId();
    });
  }

  String generateFakeFcmId() {
    final random = Random();
    const characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String randomString =
        List.generate(160, (index) => characters[random.nextInt(characters.length)]).join();

    return "${randomString.substring(0, 14)}-${randomString.substring(14, 21)}:${randomString.substring(21, 47)}-${randomString.substring(47)}"
        ",OS:33,Model:SM-M325F,BRAND:samsung,MANUFACTURER:samsung,Build ID:TP1A.220624.014";
  }

  Future<void> attemptLogin(String rollNumber, String password) async {
    final body = {
      "UserID": rollNumber,
      "DeviceType": "android",
      "FCMID": fcmId,
      "Password": password,
    };

    try {
      final response = await http.post(
        Uri.parse(baseURL + loginPath),
        body: jsonEncode(body),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)[0];
        if (data["errorId"] == 0) {
          setState(() {
            webIdentifier = data["referenceId"];
            name = data["studentName"];
            statusMessage = "Login successful!";
          });
          fetchTimetable(webIdentifier!);
        } else {
          setState(() {
            statusMessage = "Error: ${data["errorMessage"]}";
          });
        }
      } else {
        setState(() {
          statusMessage = "HTTP Error: ${response.statusCode}\n${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = "Request failed: $e\nProbably a server-side error.";
      });
    }
    showSnackbar(statusMessage);
  }

  Future<void> fetchTimetable(String webIdentifier) async {
    final body = {"WebIdentifier": webIdentifier};

    try {
      final response = await http.post(
        Uri.parse(baseURL + timetablePath),
        body: jsonEncode(body),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          timetable = data["table"];
          statusMessage = "Timetable loaded successfully!";
        });
      } else {
        setState(() {
          statusMessage = "HTTP Error: ${response.statusCode}\n${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = "Request failed: $e\nProbably a server-side error.";
      });
    }
    showSnackbar(statusMessage);
  }

  void submitCourse() {
    if (selectedCourse != null) {
      markAttendance(selectedCourse['timeTableId']);
    } else {
      setState(() {
        statusMessage = "No course selected.";
      });
    }
    showSnackbar(statusMessage);
  }

  Future<void> markAttendance(String timeTableId) async {
    final body = {
      "Webidentifier": webIdentifier,
      "TimeTableId": timeTableId,
    };

    try {
      final response = await http.post(
        Uri.parse(baseURL + attendancePath),
        body: jsonEncode(body),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)["table"][0];
        if (data["errorid"] == 0) {
          setState(() {
            statusMessage = "Attendance marked successfully for ${selectedCourse['courseName']}";
          });
        } else {
          setState(() {
            statusMessage =
                "Error: ${data["errormessage"]}. Maybe you've already marked attendance for this course or the course is not ongoing right now";
          });
        }
      } else {
        setState(() {
          statusMessage = "HTTP Error: ${response.statusCode}\n${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = "Request failed: $e\nProbably a server-side error.";
      });
    }
    showSnackbar(statusMessage);
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Web Identifier: $webIdentifier'),
            Text('Name: $name'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: submitCourse,
              child: const Text('Submit'),
            ),
            const SizedBox(height: 16),
            timetable.isNotEmpty
                ? Expanded(
                    child: ListView.builder(
                      itemCount: timetable.length,
                      itemBuilder: (context, index) {
                        final course = timetable[index];
                        return ListTile(
                          title: Text(course['courseName']),
                          subtitle: Text(course['courseCode']),
                          trailing: Radio<dynamic>(
                            value: course,
                            groupValue: selectedCourse,
                            onChanged: (value) {
                              setState(() {
                                selectedCourse = value;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  )
                : const Text('No timetable data available.'),
          ],
        ),
      ),
    );
  }
}
