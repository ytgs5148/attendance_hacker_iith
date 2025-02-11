import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AttendancePage extends StatefulWidget {
  final String rollNumber;
  final String password;
  final bool devMode;

  const AttendancePage({
    super.key,
    required this.rollNumber,
    required this.password,
    required this.devMode,
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
    const characters =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String randomString = List.generate(
        160, (index) => characters[random.nextInt(characters.length)]).join();
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
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('rollNumber', rollNumber);
          await prefs.setString('password', password);
          fetchTimetable(webIdentifier!);
        } else {
          setState(() => statusMessage = "Error: ${data["errorMessage"]}");
        }
      } else {
        setState(() => statusMessage =
            "HTTP Error: ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      setState(() =>
          statusMessage = "Request failed: $e\nProbably a server-side error.");
    }
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
        });
      } else {
        setState(() => statusMessage =
            "HTTP Error: ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      setState(() =>
          statusMessage = "Request failed: $e\nProbably a server-side error.");
    }
  }

  void submitCourse() {
    if (selectedCourse != null) {
      markAttendance(selectedCourse['timeTableId']);
    } else {
      setState(() => statusMessage = "No course selected.");
    }
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
          setState(() => statusMessage =
              "Attendance marked successfully for ${selectedCourse['courseName']}");
        } else {
          setState(() => statusMessage =
              "Error: ${data["errormessage"]}. Maybe you've already marked attendance for this course or the course is not ongoing right now");
        }
      } else {
        setState(() => statusMessage =
            "HTTP Error: ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      setState(() =>
          statusMessage = "Request failed: $e\nProbably a server-side error.");
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Attendance Status',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            statusMessage,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.deepPurple),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Page'),
        backgroundColor: Colors.black,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.devMode)
              Text(
                'Web Identifier: $webIdentifier',
                style: const TextStyle(color: Colors.white),
              ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Name: $name',
                style: const TextStyle(color: Colors.white, fontSize: 32),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: submitCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                child: const Text('Submit'),
              ),
            ),
            const SizedBox(height: 16),
            timetable.isNotEmpty
                ? Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 3,
                      ),
                      itemCount: timetable.length,
                      itemBuilder: (context, index) {
                        final course = timetable[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          color: Colors.grey[900],
                          elevation: 8,
                          shadowColor: Colors.deepPurple.withOpacity(0.7),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                course['courseName'],
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                course['courseCode'],
                                style: const TextStyle(color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Radio<dynamic>(
                                value: course,
                                groupValue: selectedCourse,
                                onChanged: (value) {
                                  setState(() {
                                    selectedCourse = value;
                                  });
                                },
                                fillColor:
                                    WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.deepPurple;
                                    }
                                    return Colors.white;
                                  },
                                ),
                                activeColor: Colors.deepPurple,
                              ),
                              contentPadding: const EdgeInsets.all(8.0),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: Text(
                      'No timetable data available.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
