import 'package:hive/hive.dart';




part 'task.g.dart';  // Generated file

@HiveType(typeId: 0)  // typeId must be unique
class Task {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final DateTime dateTime;

  @HiveField(2)
  final int id;

  Task({
    required this.title,
    required this.dateTime,
    required this.id,
  });
}