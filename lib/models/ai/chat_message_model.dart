import 'package:hive/hive.dart';

part 'chat_message_model.g.dart';

@HiveType(typeId: 21) // Unique ID
class ChatMessageModel extends HiveObject {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final String senderId; // 'user' or 'ai'

  @HiveField(2)
  final DateTime createdAt;
  
  @HiveField(3)
  final bool isError;

  @HiveField(4)
  final String sessionId;

  ChatMessageModel({
    required this.text,
    required this.senderId,
    required this.createdAt,
    required this.sessionId,
    this.isError = false,
  });
}
