import 'package:hive/hive.dart';

part 'chat_session_model.g.dart';

@HiveType(typeId: 22)
class ChatSessionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String summary; // Short preview text

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  final DateTime createdAt;

  ChatSessionModel({
    required this.id,
    this.title = 'New Chat',
    this.summary = '',
    required this.updatedAt,
    required this.createdAt,
  });
}
