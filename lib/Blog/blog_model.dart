import 'package:cloud_firestore/cloud_firestore.dart';

class Blog {
  String id;
  String title;
  String content;
  String category;
  String imageUrl;
  String authorId;
  String authorName;
  DateTime timestamp;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.imageUrl,
    required this.authorId,
    required this.authorName,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'imageUrl': imageUrl,
      'authorId': authorId,
      'authorName': authorName,
      'timestamp':
          Timestamp.fromDate(timestamp), // Converting DateTime to Timestamp
    };
  }

  factory Blog.fromMap(Map<String, dynamic> map, String documentId) {
    return Blog(
      id: documentId,
      title: map['title'],
      content: map['content'],
      category: map['category'],
      imageUrl: map['imageUrl'],
      authorId: map['authorId'],
      authorName: map['authorName'],
      timestamp: (map['timestamp'] as Timestamp)
          .toDate(), // Converting Timestamp to DateTime
    );
  }
}
