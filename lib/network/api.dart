import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tns_kiosk/availability.dart';
import 'package:tns_kiosk/models/schedule.dart';
import 'package:tns_kiosk/models/school_class.dart';
import 'package:tns_kiosk/models/sse_connection.dart';
import 'package:tns_kiosk/models/teacher.dart';
import 'package:tns_kiosk/weekday.dart';
import 'package:tns_kiosk/globals.dart' as globals;

Stream<SseEvent> streamEvents(
  String path, {
  Map<String, String>? headers,
  Map<String, dynamic>? param,
}) async* {
  final client = http.Client();
  try {
    late final Uri url;
    if (globals.baseURL.startsWith('https://')) {
      url = Uri.https(
        globals.baseURL.replaceFirst('https://', ''),
        path,
        param,
      );
    } else if (globals.baseURL.startsWith('http://')) {
      url = Uri.http(globals.baseURL.replaceFirst('http://', ''), path, param);
    }

    final request = http.Request("GET", url);
    request.headers['Accept'] = 'text/event-stream';

    final response = await client.send(request);
    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    StringBuffer dataBuffer = StringBuffer();

    await for (final line in lines) {
      if (line.startsWith(':')) continue;

      if (line.isEmpty) {
        if (dataBuffer.isNotEmpty) {
          yield SseEvent(data: dataBuffer.toString().trim());
          dataBuffer.clear();
        }
        continue;
      }

      if (line.startsWith('data:')) {
        dataBuffer.writeln(line.substring(5).trim());
      }
    }
  } finally {
    client.close();
  }
}

Future<dynamic> getParse(
  String path, {
  Map<String, dynamic>? param,
  Map<String, String>? headers,
}) async {
  try {
    late final Uri url;
    if (globals.baseURL.startsWith('https://')) {
      url = Uri.https(
        globals.baseURL.replaceFirst('https://', ''),
        path,
        param,
      );
    } else if (globals.baseURL.startsWith('http://')) {
      url = Uri.http(globals.baseURL.replaceFirst('http://', ''), path, param);
    }

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("GET: ${url.path} returned code ${response.statusCode}");
    }
  } catch (e) {
    print("(getParse) ERROR: $e");
  }

  return null;
}

Future<dynamic> postParse(
  String path, {
  Map<String, dynamic>? params,
  Map<String, dynamic>? data,
  String? token,
}) async {
  Map<String, String> headers = {"Content-Type": "application/json"};

  if (token != null) {
    headers["Authorization"] = token;
  }

  try {
    late final Uri url;
    if (globals.baseURL.startsWith('https://')) {
      url = Uri.http(
        globals.baseURL.replaceFirst('https://', ''),
        path,
        params,
      );
    } else if (globals.baseURL.startsWith('http://')) {
      url = Uri.http(globals.baseURL.replaceFirst('http://', ''), path, params);
    }

    final response = await http.post(
      url,
      headers: headers,
      body: data == null ? null : json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("POST: ${url.path} returned code ${response.statusCode}");
    }
  } catch (e) {
    print("(postParse) ERROR: $e");
  }

  return null;
}

Future<dynamic> optionsParse(
  String path, {
  Map<String, dynamic>? data,
  required String token,
}) async {
  Map<String, String> headers = {
    "Content-Type": "application/json",
    "Authorization": token, // OPTIONS requests here require a token
  };

  try {
    late final Uri url;
    if (globals.baseURL.startsWith('https://')) {
      url = Uri.https(globals.baseURL.replaceFirst('https://', ''), path);
    } else if (globals.baseURL.startsWith('http://')) {
      url = Uri.http(globals.baseURL.replaceFirst('http://', ''), path);
    }

    // Note: Dart's http package uses http.send with the 'OPTIONS' method
    final request = http.Request('OPTIONS', url)..headers.addAll(headers);

    if (data != null) {
      request.body = json.encode(data);
    }

    final response = await http.Response.fromStream(
      await http.Client().send(request),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        "OPTIONS: ${url.path} returned code ${response.statusCode}",
      );
    }
  } catch (e) {
    print("(optionsParse) ERROR: $e");
  }

  return null;
}

Future<dynamic> deleteReq(
  String path, {
  Map<String, dynamic>? param,
  required String token,
}) async {
  Map<String, String> headers = {
    "Content-Type": "application/json",
    "Authorization": token,
  };

  try {
    late final Uri url;
    if (globals.baseURL.startsWith('https://')) {
      url = Uri.https(globals.baseURL.replaceFirst('https://', ''), path, param);
    } else if (globals.baseURL.startsWith('http://')) {
      url = Uri.http(globals.baseURL.replaceFirst('http://', ''), path, param);
    }

    final response = await http.delete(url, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        "DELETE: ${url.path} returned code ${response.statusCode}",
      );
    }
  } catch (e) {
    print("(deleteReq) ERROR: $e");
  }

  return null;
}

// Schedule
Future<Schedule?> getSchedule(int id) async {
  Map<String, dynamic>? data = await getParse(
    "/api/schedule",
    param: {"schedule_id": id},
    headers: {"Content-Type": "application/json"},
  );

  if (data == null) {
    return null;
  }

  final dtIn = DateTime.parse("1970-01-01 ${data["time_in"]}");
  final dtOut = DateTime.parse("1970-01-01 ${data["time_out"]}");

  return Schedule(
    id,
    data["classId"] as int,
    data["teacherId"] as int,
    data["subject"] as String,
    WeekDay.fromCode(data["weekday"] as int),
    TimeOfDay.fromDateTime(dtIn),
    TimeOfDay.fromDateTime(dtOut),
    data["is_break"] as bool? ?? false
  );
}

Future<int?> createSchedule(Schedule schedule, String token) async {
  // Server-side expects time_in and time_out as strings (e.g., "10:00:00")
  final timeIn =
      '${schedule.timeIn.hour.toString().padLeft(2, '0')}:${schedule.timeIn.minute.toString().padLeft(2, '0')}:00';
  final timeOut =
      '${schedule.timeOut.hour.toString().padLeft(2, '0')}:${schedule.timeOut.minute.toString().padLeft(2, '0')}:00';

  Map<String, dynamic>? data = await postParse(
    "/api/schedule",
    token: token,
    data: {
      "class_id": schedule.classId,
      "subject": schedule.subject,
      "weekday": schedule.weekday.code,
      "time_in": timeIn,
      "time_out": timeOut,
      "is_break": schedule.isBreak
    },
  );

  return data?["id"] as int?;
}

Future<int?> editSchedule(Schedule schedule, String token) async {
  final timeIn =
      '${schedule.timeIn.hour.toString().padLeft(2, '0')}:${schedule.timeIn.minute.toString().padLeft(2, '0')}:00';
  final timeOut =
      '${schedule.timeOut.hour.toString().padLeft(2, '0')}:${schedule.timeOut.minute.toString().padLeft(2, '0')}:00';

  Map<String, dynamic>? data = await optionsParse(
    "/api/schedule",
    token: token,
    data: {
      "id": schedule.id,
      "class_id": schedule.classId,
      "subject": schedule.subject,
      "weekday": schedule.weekday.code,
      "time_in": timeIn,
      "time_out": timeOut,
      "is_break": schedule.isBreak
    },
  );

  return data?["id"] as int?;
}

Future<int?> deleteSchedule(int id, String token) async {
  Map<String, dynamic>? data = await deleteReq(
    "/api/schedule",
    token: token,
    param: {"schedule_id": id.toString()},
  );

  return data?["id"] as int?;
}

Future<List<Schedule>> getAllSchedules() async {
  List<dynamic>? data = await getParse(
    "/api/allSchedules",
    // param: {"teacher_id": teacherId.toString()},
    headers: {"Content-Type": "application/json"},
  );

  if (data == null) {
    return [];
  }

  return data.map((item) {
    final dtIn = DateTime.parse("1970-01-01 ${item["time_in"]}");
    final dtOut = DateTime.parse("1970-01-01 ${item["time_out"]}");

    return Schedule(
      item["id"] as int,
      item["class_id"] as int,
      item["teacher_id"] as int,
      item["subject"] as String,
      WeekDay.fromCode(item["weekday"] as int),
      TimeOfDay.fromDateTime(dtIn),
      TimeOfDay.fromDateTime(dtOut),
      item["is_break"] as bool? ?? false
    );
  }).toList();
}

Future<List<Schedule>> getTeacherSchedules(int teacherId) async {
  List<dynamic>? data = await getParse(
    "/api/teacherSchedules",
    param: {"teacher_id": teacherId.toString()},
    headers: {"Content-Type": "application/json"},
  );

  if (data == null) {
    return [];
  }

  return data.map((item) {
    final dtIn = DateTime.parse("1970-01-01 ${item["time_in"]}");
    final dtOut = DateTime.parse("1970-01-01 ${item["time_out"]}");

    return Schedule(
      item["id"] as int,
      item["class_id"] as int,
      item["teacher_id"] as int,
      item["subject"] as String,
      WeekDay.fromCode(item["weekday"] as int),
      TimeOfDay.fromDateTime(dtIn),
      TimeOfDay.fromDateTime(dtOut),
      item["is_break"] as bool? ?? false
    );
  }).toList();
}

// Teacher
Future<Teacher?> getTeacherSelf(String token) async {
  Map<String, dynamic>? data = await getParse(
    "/api/self",
    headers: {"Authorization": token},
  );

  if (data == null) {
    return null;
  }

  return Teacher(
    data["id"] as int,
    data["full_name"] as String,
    prefix: data["prefix"] as String?,
    suffix: data["postfix"] as String?, // Note: Server uses 'postfix'
    subject: data["main_subject"] as String?,
    token: token, // We pass the token back
    email: data["email_address"] as String?,
    availability: availabilityFromCode(data["availability"] as int),
  );
}

Future<Teacher?> getTeacher(int teacherId) async {
  Map<String, dynamic>? data = await getParse(
    "/api/teacher",
    param: {"teacher_id": teacherId.toString()},
  );

  if (data == null) {
    return null;
  }

  return Teacher(
    data["id"] as int,
    data["full_name"] as String,
    prefix: data["prefix"] as String?,
    suffix: data["postfix"] as String?,
    subject: data["main_subject"] as String?,
    email: data["email_address"] as String?,
    availability: availabilityFromCode(data["availability"] as int),
  );
}

Future<List<Teacher>> getTeacherList() async {
  List<dynamic>? data = await getParse("/api/teacherList");

  if (data == null) {
    return [];
  }

  return data.map((item) {
    return Teacher(
      item["id"] as int,
      item["full_name"] as String,
      prefix: item["prefix"] as String?,
      suffix: item["postfix"] as String?,
      subject: item["main_subject"] as String?,
      email: item["email_address"] as String?,
      availability: availabilityFromCode(item["availability"] as int),
    );
  }).toList();
}

Future<Map<String, dynamic>?> updateProfile({
  required String token,
  String? fullName,
  String? prefix,
  String? suffix,
  String? mainSubject,
  String? emailAddress,
  String? oldPassword,
  String? newPassword,
}) async {
  Map<String, dynamic> body = {
    // These keys must match the server's expected schema (schemas.TeacherUpdate)
    "full_name": fullName,
    "prefix": prefix,
    "postfix": suffix,
    "main_subject": mainSubject,
    "email_address": emailAddress,
    "old_password": oldPassword,
    "new_password": newPassword,
  };

  // Remove null values to avoid sending them unnecessarily, though the server handles it.
  body.removeWhere((key, value) => value == null);

  Map<String, dynamic>? data = await optionsParse(
    "/api/profile",
    token: token,
    data: body,
  );

  return data; // Returns {'id': id, 'token': newTokenOrNull}
}

Future<Teacher?> login(
  String email,
  String password, [
  String? firebaseToken,
]) async {
  Map<String, dynamic>? data = await postParse(
    "/api/login",
    params: {
      "email": email,
      "password": password,

      // if (firebaseToken != null)
      "firebase_token": firebaseToken ?? "",
    },
  );

  if (data == null) {
    return null;
  }

  return Teacher(
    data["id"] as int,
    data["full_name"] as String,
    prefix: data["prefix"] as String?,
    suffix: data["postfix"] as String?,
    subject: data["main_subject"] as String?,
    token: data["token"] as String?, // The server returns the new token on login
    email: data["email_address"] as String?,
    availability: availabilityFromCode(data["availability"] as int),
  );
}

Future<bool> respond(String message, String tabletSession, String token) async {
  final data = await postParse(
    "/api/respond",
    token: token,
    params: {"tablet_session": tabletSession, "message": message},
  );

  return (data != null);
}

Future<void> forceAvailability(
  Availability availability,
  TimeOfDay until,
  String token,
) async {
  final time =
      '${until.hour.toString().padLeft(2, '0')}:${until.minute.toString().padLeft(2, '0')}:00';
  await postParse(
    "/api/forceAvailability",
    token: token,
    params: {"until": time},
  );
}

Future<void> setTeacherPrefs(String token, {bool dndVacant = true}) async {
  await optionsParse(
    "/api/setPreferences",
    token: token,
    data: {"dnd_vacant": dndVacant},
  );
}

Future<Map<String, dynamic>?> getTeacherPrefs(String token) async {
  return await getParse(
    "/api/getPreferences",
    headers: {"Authorization": token},
  );
}

// Future<List<Teacher>?> getTeacherList() async {
//   return await getParse(
//     "/api/teacherList",
//   );
// }

Future<void> notifyTeacher(int teacherId, String tabletSession) async {
  await postParse(
    "/api/notify",
    params: {
      "teacher_id": teacherId.toString(),
      "tablet_session": tabletSession
    }
  );
}

Stream<Map<String, dynamic>> listenToTeacherEvents(String token) {
  return streamEvents(
    "/api/eventsTeacher",
    param: {"token": token},
  ).map((sse) => json.decode(sse.data) as Map<String, dynamic>);
}

Stream<Map<String, dynamic>> listenToTabletEvents() {
  return streamEvents(
    "/api/eventsTablet",
  ).map((sse) => json.decode(sse.data) as Map<String, dynamic>);
}

// Classes
Future<List<SchoolClass>> getClassesList() async {
  List<dynamic>? data = await getParse("/api/classesList");

  if (data == null) {
    return [];
  }

  return data.map((item) {
    return SchoolClass(
      item["id"] as int,
      item["name"] as String,
      item["grade"]
          as int, // Note: Server uses 'grade', client uses 'gradeLevel'
    );
  }).toList();
}
