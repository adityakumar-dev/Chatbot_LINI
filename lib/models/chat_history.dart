

class historyModel{
  final int conversation_id;
  final String title;
  final DateTime created_at;
  historyModel({
    required this.conversation_id,
    required this.title,
    required this.created_at,
  });
  factory historyModel.fromJson(Map<String, dynamic> json) {
    return historyModel(
      conversation_id: json['conversation_id'],
      title: json['title'],
      created_at: DateTime.parse(json['created_at']),
    );
  }
}