class SseEvent {
  final String? event;
  final String data;
  final String? id;

  SseEvent({this.event, required this.data, this.id});

  @override
  String toString() => 'Event: $event, Data: $data';
}
