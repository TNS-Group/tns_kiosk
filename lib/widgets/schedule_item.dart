import 'package:flutter/material.dart';
import 'package:tns_kiosk/constants.dart';
import 'package:tns_kiosk/weekday.dart';

class ScheduleItem extends StatelessWidget {
  final String subject;
  final WeekDay weekday;
  final String className;
  final TimeOfDay start;
  final TimeOfDay end;
  final bool isBreak;

  const ScheduleItem( { super.key, required this.start, required this.end, this.className = "Class", this.subject = "N/A", this.weekday = WeekDay.monday, this.isBreak = false } );

  @override Widget build(BuildContext context) {
    return  
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment(0.5, 1.0),
            colors: [
              Theme.of(context).colorScheme.surfaceContainer, isBreak ? Colors.grey : Colors.blue
            ]
          )
        ),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            spacing: 4,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject.toUpperCase(), textScaler: const TextScaler.linear(0.8),),
              Text(className, textScaler: const TextScaler.linear(phi),),
              Text("${weekday.label.toUpperCase().substring(0, 3)}  ${formatTimeOfDay(start)} - ${formatTimeOfDay(end)}"),
            ],
          )
        )
      );
  }
}

String formatTimeOfDay(TimeOfDay tod) {
  final hour = tod.hourOfPeriod;
  final minute = tod.minute.toString().padLeft(2, '0');
  final period = tod.period == DayPeriod.am ? "AM" : "PM";
  return "$hour:$minute$period";
}

bool hasTimePassed(TimeOfDay target) {
  final now = TimeOfDay.now();

  if (now.hour > target.hour) return true;
  if (now.hour == target.hour && now.minute >= target.minute) return true;

  return false;
}
