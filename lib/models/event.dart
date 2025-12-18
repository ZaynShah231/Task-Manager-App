import 'package:hive/hive.dart';

class Event extends HiveObject {
  String title;
  String venue;
  DateTime scheduledAt;

  Event({
    required this.title,
    required this.venue,
    required this.scheduledAt,
  });

  void reschedule(DateTime newDate) {
    scheduledAt = newDate;
    save();
  }
}

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 1;

  @override
  Event read(BinaryReader reader) {
    return Event(
      title: reader.readString(),
      venue: reader.readString(),
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(
        reader.readInt(),
      ),
    );
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeString(obj.title)
      ..writeString(obj.venue)
      ..writeInt(obj.scheduledAt.millisecondsSinceEpoch);
  }
}
