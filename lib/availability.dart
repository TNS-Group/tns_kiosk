enum Availability {
  available(0),
  doNotDisturb(1),
  inClass(2),
  absent(3);

  final int code;
  const Availability(this.code);
}
Availability availabilityFromCode(int code) {
  return Availability.values.firstWhere(
    (status) => status.code == code,
    orElse: () => Availability.absent, // default if not found
  );
}

extension AvailabilityExtension on Availability {
  String get label {
    switch (this) {
      case Availability.available:
        return 'Available';
      case Availability.doNotDisturb:
        return 'Do Not Disturb';
      case Availability.inClass:
        return 'In Class';
      case Availability.absent:
        return 'Not Available';
    }
  }

  String get reason {
    switch (this) {
      case Availability.available:
        return 'is Available';
      case Availability.doNotDisturb:
        return 'Cannot be Disturbed';
      case Availability.inClass:
        return 'is in Class';
      case Availability.absent:
        return 'is Not Available';
    }
  }
}
