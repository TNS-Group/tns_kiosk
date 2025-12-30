import 'package:flutter/material.dart';
import 'package:tns_kiosk/weekday.dart';

class Schedule {
  int id, classId, teacherId;
  String subject;
  WeekDay weekday;
  TimeOfDay timeIn;
  TimeOfDay timeOut;

  Schedule(
    this.id,
    this.classId,
    this.teacherId,
    this.subject,
    this.weekday,
    this.timeIn,
    this.timeOut,
  );

  @override
  String toString() {
    return 'Schedule(id: $id, classId: $id, subject: $subject, weekday: $weekday)';
  }
}
