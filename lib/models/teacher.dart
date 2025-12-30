import 'package:tns_kiosk/availability.dart';

class Teacher {
  int id;
  String name;
  String? prefix;
  String? suffix;
  String? subject;

  Availability availability;

  String? token;
  String? email;

  Teacher(this.id, this.name, { this.availability=Availability.absent, this.prefix, this.suffix, this.subject, this.token, this.email});
}
