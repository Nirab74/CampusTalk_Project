import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  String id;
  String title;
  String description;
  String date;
  String time;
  bool reminder;
  bool isPublic;
  String userId;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.reminder,
    required this.isPublic,
    required this.userId,
  });

  /// Factory constructor to create an `EventModel` from Firestore data.
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      reminder: data['reminder'] ?? false,
      isPublic: data['isPublic'] ?? false,
      userId: data['userId'] ?? '',
    );
  }

  /// Convert `EventModel` to a Firestore-compatible JSON format.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'reminder': reminder,
      'isPublic': isPublic,
      'userId': userId,
    };
  }

  /// Retrieve all **Public Events** from Firestore.
  static Stream<List<EventModel>> getPublicEvents() {
    return FirebaseFirestore.instance
        .collection('public_events')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  /// Retrieve all **Private Events** for the logged-in user.
  static Stream<List<EventModel>> getPrivateEvents(String userId) {
    return FirebaseFirestore.instance
        .collection('private_events')
        .doc(userId)
        .collection('userEvents')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  /// Save the event to Firestore, checking whether it's **public or private**.
  Future<void> saveToFirestore() async {
    if (isPublic) {
      await FirebaseFirestore.instance
          .collection('public_events')
          .doc(id)
          .set(toFirestore());
    } else {
      await FirebaseFirestore.instance
          .collection('private_events')
          .doc(userId)
          .collection('userEvents')
          .doc(id)
          .set(toFirestore());
    }
  }

  /// Delete an event from Firestore.
  Future<void> deleteFromFirestore() async {
    if (isPublic) {
      await FirebaseFirestore.instance
          .collection('public_events')
          .doc(id)
          .delete();
    } else {
      await FirebaseFirestore.instance
          .collection('private_events')
          .doc(userId)
          .collection('userEvents')
          .doc(id)
          .delete();
    }
  }
}
