import 'package:hive/hive.dart';

class Task extends HiveObject {
  String name;
  String description;
  bool completed;
  final DateTime createdOn;

  Task({
    required this.name,
    this.description = '',
    DateTime? createdOn,
    this.completed = false,
  }) : createdOn = createdOn ?? DateTime.now();

  void toggleStatus() {
    completed = !completed;
    save();
  }
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    return Task(
      name: reader.readString(),
      description: reader.readString(),
      createdOn: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      completed: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeString(obj.name)
      ..writeString(obj.description)
      ..writeInt(obj.createdOn.millisecondsSinceEpoch)
      ..writeBool(obj.completed);
  }
}
