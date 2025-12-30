import 'package:flutter/material.dart';
import 'package:tns_kiosk/availability.dart';

class InformationBar extends StatelessWidget {
  final String name;
  final String subject;
  final String? prefix;
  final String? postfix;

  final Availability availability;

  const InformationBar({
    super.key,
    this.name = "Juan Dela Cruz",
    this.subject = "N/A",
    this.prefix,
    this.postfix,
    this.availability = Availability.absent,
  });

  @override
  Widget build(BuildContext context) {
    final Widget nameWidget = RichText(
      text: TextSpan(
        text: prefix ?? '',
        style: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 24,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        children: [
          TextSpan(
            text: name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: Theme.of(
                context,
              ).appBarTheme.titleTextStyle?.fontFamily,
            ),
          ),
          if (postfix != null && postfix!.isNotEmpty)
            TextSpan(text: ", $postfix"),
        ],
      ),
    );

    final Widget subjectWidget = RichText(
      text: TextSpan(
        text: "$subject Teacher",
        style: TextStyle(
          fontFamily: Theme.of(context).appBarTheme.titleTextStyle?.fontFamily,
          fontWeight: FontWeight.normal,
          fontSize: 12,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );

    final Widget availabilityWidget = RichText(
      text: TextSpan(
        text: "Seen as ",
        style: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        children: [
          TextSpan(
            text: availability.label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          nameWidget,
          if (subject.isNotEmpty && subject != 'null') subjectWidget,
          availabilityWidget,
        ],
      ),
    );
  }
}
