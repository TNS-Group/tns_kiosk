
import 'package:flutter/material.dart';
import 'package:tns_kiosk/models/teacher.dart';
import 'package:tns_kiosk/network/api.dart';
import 'package:tns_kiosk/widgets/teacher_button.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<StatefulWidget> createState() => RootPageState();
}

class RootPageState extends State<RootPage> {
  late TextEditingController searchTBoxController;
  bool Function(Teacher)? filter;

  late Stream<Map<String, dynamic>> _tabletStream;
  bool _firstStreamDataReceived = true;
  String? _tabletToken;

  List<Teacher> teacherList = [];

  @override
  void initState() {
    super.initState();
    searchTBoxController = TextEditingController();

    _tabletStream = listenToTabletEvents();
    _tabletStream.listen((data) {
      if (_firstStreamDataReceived) {
        setState(() { 
          _tabletToken = data["token"];
          _firstStreamDataReceived = false;
        });
      } else {
        // TODO: Add a notification/dialogue
      }
    });

    getTeacherList().then((l){
      teacherList = l;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = filter == null ? teacherList : teacherList.where(filter!);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32), // Safe Zone
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search Teacher",
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
                      for (final t in filteredList)
                      TeacherButton(
                        t,
                        onTap: () {
                          print(t.name);
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
