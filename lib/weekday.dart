enum WeekDay {
  monday(0),
  tuesday(1),
  wednesday(2),
  thursday(3),
  friday(4);

  final int code;
  const WeekDay(this.code);

  static WeekDay fromCode(int code) {
    return WeekDay.values.firstWhere(
      (status) => status.code == code,
      orElse: () => WeekDay.monday, // default if not found
    );
  }
}

extension WeekDayExtension on WeekDay {
  String get label {
    switch (this) {
      case WeekDay.monday:
        return 'Monday';
      case WeekDay.tuesday:
        return 'Tuesday';
      case WeekDay.wednesday:
        return 'Wednesday';
      case WeekDay.thursday:
        return 'Thursday';
      case WeekDay.friday:
        return 'Friday';
    }
  }
}
