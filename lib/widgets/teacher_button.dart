import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:tns_kiosk/models/teacher.dart';
import 'package:tns_kiosk/availability.dart';
import 'package:tns_kiosk/globals.dart' as globals;
import 'package:tns_kiosk/constants.dart' as constants;

class TeacherButton extends StatefulWidget{
  final Teacher initialTeacher;
  final Function()? onTap;

  const TeacherButton(this.initialTeacher, { this.onTap, super.key });

  @override
  State<StatefulWidget> createState() => TeacherButtonState();
}

class TeacherButtonState extends State<TeacherButton> with AutomaticKeepAliveClientMixin{
  late Teacher teacher;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    teacher = widget.initialTeacher;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(128),
            blurRadius: 8
          )
        ]
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: AspectRatio(
                aspectRatio: 2/3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Theme.of(context).colorScheme.surface
                    ),
                    Positioned.fill(
                      child: Opacity(
                        opacity: teacher.availability == Availability.available ? 1 : constants.opacityUnavailable,
                        child: Image(
                          image: NetworkImage('${globals.baseURL}/api/profilePicture/${teacher.id}'),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.broken_image, size: 64, color: Theme.of(context).colorScheme.onSurface);
                          },
                        )
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      alignment: Alignment.bottomLeft,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            Theme.of(context).colorScheme.surfaceContainer,
                            Theme.of(context).colorScheme.surfaceContainer.withAlpha(200),
                            Theme.of(context).colorScheme.surfaceContainer.withAlpha(0),
                          ]
                        )
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(teacher.availability.label,
                            style: TextStyle(
                              color: teacher.availability == Availability.available ? 
                              Colors.green :
                              Colors.red,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(64),
                                  blurRadius: 4
                                )
                              ]
                            )
                          ),
                          Text(
                            teacher.name, 
                            textScaler: TextScaler.linear(constants.phi), 
                            style: TextStyle(
                              color: teacher.availability == Availability.available ? 
                              Theme.of(context).colorScheme.onSurface :
                              Theme.of(context).colorScheme.onSurface.withAlpha(128),
                              shadows: [
                                Shadow(
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(64),
                                  blurRadius: 4
                                )
                              ]
                            ),
                          ),
                        ],
                      )
                    ),
                  ],
                ),
              )
            )
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                child: Ink(
                  color: Colors.transparent,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
