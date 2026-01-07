
import 'package:flutter/material.dart';
import 'package:tns_kiosk/availability.dart';
import 'package:tns_kiosk/models/teacher.dart';
import 'package:tns_kiosk/widgets/teacher_button.dart';

import 'package:tns_kiosk/network/api.dart' as api;
import 'package:tns_kiosk/constants.dart' as constants;
import 'package:tns_kiosk/globals.dart' as globals;

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<StatefulWidget> createState() => RootPageState();
}

class RootPageState extends State<RootPage> {
  late TextEditingController searchTBoxController;
  bool Function(Teacher)? filter;
  Map<int, int> _cacheBuster = {};

  late Stream<Map<String, dynamic>> _tabletStream;
  bool _firstStreamDataReceived = true;
  String? _tabletToken;

  Map<int, Teacher> teacherMap = {};
  late BuildContext _currentContext;

  @override
  void initState() {
    super.initState();
    searchTBoxController = TextEditingController();

    _tabletStream = api.listenToTabletEvents();
    _tabletStream.listen((data) {
      if (_firstStreamDataReceived) {
        setState(() { 
          _tabletToken = data["token"];
          _firstStreamDataReceived = false;
        });
      } else {
        if (data["event"] as String == "response") {
          messageReceive(data["teacher_id"], data["message"]);
        } else if (data["event"] as String == "reload") {
          reloadTeacher(data["teacher_id"] as int);
          // messageReceive(data["teacher_id"], data["message"]);
        }
      }
    });

    api.getTeacherList().then((l){
      for (final t in l) {
        teacherMap[t.id] = t;
        _cacheBuster[t.id] = 0;
      }
    });
  }

  void reloadTeacher(int id) {
    api.getTeacher(id).then((t){
      if (t == null) return;
      setState(() {
        teacherMap[id] = t;
        _cacheBuster[id] = _cacheBuster[id]! + 1;
      });
    });
  }

  void notificationSent(Teacher teacher) {
    showDialog(context: _currentContext, builder: (ctx) {
      final route = ModalRoute.of(ctx);
      Future.delayed(Duration(seconds: 5)).then((_){
        if (ctx.mounted && route != null && route.isActive) {
          Navigator.of(ctx).removeRoute(route);
        }
      });
      return AlertDialog(
        content: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: 512,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Text(
                  "Notifiction Sent",
                  textScaler: TextScaler.linear(2),
                  // style: TextStyle(
                  //   fontWeight: FontWeight.bold
                  // ),
                ),
                Text("A notification has been sent to ${teacher.name}. Please wait for at least a couple of seconds for the teacher to respond or open the door."),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: (){
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text("Okay"),
            ),
          )
        ],
      );
    });
  }
  void messageReceive(int teacherId, String message) {
    final noComment = message.isEmpty;
    showDialog(context: _currentContext, builder: (ctx) {
      return AlertDialog(
        content: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: 256,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Text(
                  "Response",
                  textScaler: TextScaler.linear(2),
                  // style: TextStyle(
                  //   fontWeight: FontWeight.bold
                  // ),
                ),
                Text("You received a message from ${teacherMap[teacherId]!.name}"),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    noComment ? "* No Comment *" : "\"$message\"",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.tertiary
                    ),
                  )
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: (){
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text("Okay"),
            ),
          )
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _currentContext = context;

    final filteredList = filter == null ? teacherMap.values : teacherMap.values.where(filter!);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32), // Safe Zone
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration( hintText: "Search Teacher",
                  icon: const Icon(Icons.search)
                ),
                controller: searchTBoxController,
                onChanged: (String s) async {
                  if (s.isEmpty) {
                    setState(() { filter = null; });
                  } else {
                    setState(() { filter = (Teacher t) => t.name.contains(s); });
                  }
                },
              ),
            ),
            Expanded(
              child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                final widthCount = (constraints.maxWidth / 256).round();
                return AnimatedSwitcher(
                  duration: Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: animation.drive(Tween(begin: Offset(0, 0.1), end: Offset.zero)),
                        child: child,
                      ),
                    );
                  },
                  child: filteredList.isEmpty ? 
                  Center(
                    child: Text(
                      "There's no results with that query :(", 
                      textScaler: TextScaler.linear(2),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(128)
                      ),
                    ),
                  ) :
                  GridView.count(
                    addAutomaticKeepAlives: true,
                    padding: EdgeInsets.all(16),
                    crossAxisCount: widthCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.618033989,
                    key: ValueKey(filteredList.length),
                    children: [
                      for (final teacher in filteredList)
                      TeacherButton(
                        key: ValueKey("${teacherMap[teacher.id].hashCode} ${_cacheBuster[teacher.id]}"),
                        teacher,
                        onTap: () {
                          showModalBottomSheet(
                            clipBehavior: Clip.antiAlias,
                            // showDragHandle: true,
                            context: context, 
                            builder: (context) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                spacing: 64,
                                children: [
                                  Stack(
                                    fit: StackFit.passthrough,
                                    clipBehavior: Clip.none,

                                    children: [
                                      Container(
                                        color: Colors.blue,
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: 186,
                                        ),
                                      ),
                                      Positioned(
                                        left: 32,
                                        bottom: -64,
                                        child: CircleAvatar(
                                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                                          radius: 94,
                                          child: CircleAvatar(
                                            radius: 86,
                                            backgroundImage: NetworkImage('${globals.baseURL}/api/profilePicture/${teacher.id}?cbuster=${_cacheBuster[teacher.id]}'),
                                            // onBackgroundImageError: (error, stackTrace) {
                                            //     return Icon(Icons.broken_image, size: 64, color: Theme.of(context).colorScheme.onSurface);
                                            //   },

                                            // child: Image(
                                            //   image: NetworkImage('${globals.baseURL}/api/profilePicture/${teacher.id}'),
                                            //   fit: BoxFit.cover,
                                            //   errorBuilder: (context, error, stackTrace) {
                                            //     return Icon(Icons.broken_image, size: 64, color: Theme.of(context).colorScheme.onSurface);
                                            //   },
                                            // )
                                            // child: FlutterLogo(size: 86,),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 42),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            // spacing: 4,
                                            children: [
                                              Text(
                                                "${teacher.prefix} ${teacher.name}, ${teacher.suffix}", 
                                                textScaler: TextScaler.linear(2),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w400
                                                ),
                                              ),
                                              Text(
                                                teacher.subject == null ? "Teacher" : "${teacher.subject} Teacher", 
                                                textScaler: TextScaler.linear(2 / 1.61),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w400
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(teacher.availability.label,
                                          style: TextStyle(
                                            color: teacher.availability == Availability.available ? 
                                            Colors.green :
                                            Colors.red,
                                            fontWeight: FontWeight.bold,
                                          )
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 42.0),
                                      child: Row(
                                        spacing: 16,
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: (){
                                              Navigator.pop(context);
                                            }, 
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: const Text("Cancel"),
                                            )
                                          ),
                                          FilledButton(
                                            onPressed: teacher.availability != Availability.available ? null : (){
                                              Navigator.pop(context);
                                              notificationSent(teacherMap[teacher.id]!);
                                              api.notifyTeacher(teacher.id, _tabletToken!).ignore();
                                            }, 
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: teacher.availability != Availability.available ? Text("Cannot Noitfy") : Text("Notify"),
                                            )
                                          )
                                        ],
                                      ),
                                    )
                                  )
                                ],
                              );
                            }
                          );
                        },
                      ),
                    ],
                  )
                );
              })
            )
          ],
        ),
      )
    );
  }
}
