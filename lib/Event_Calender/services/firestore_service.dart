import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference eventCollection =
      FirebaseFirestore.instance.collection('events');

  Future<void> addEvent(Map<String, dynamic> eventData) async {
    await eventCollection.add(eventData);
  }

  Future<void> updateEvent(
      String eventId, Map<String, dynamic> updatedData) async {
    await eventCollection.doc(eventId).update(updatedData);
  }

  Future<void> deleteEvent(String eventId) async {
    await eventCollection.doc(eventId).delete();
  }

  Stream<QuerySnapshot> getEventsStream() {
    return eventCollection.snapshots();
  }
}
