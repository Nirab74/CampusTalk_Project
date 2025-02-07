import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuestionDetailScreen extends StatefulWidget {
  final String questionId;
  QuestionDetailScreen({required this.questionId});

  @override
  _QuestionDetailScreenState createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final TextEditingController _answerController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  void _postAnswer() async {
    if (user == null || _answerController.text.trim().isEmpty) return;

    // Fetch user profile image from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    String profileImage = userDoc.exists ? userDoc["profileImage"] ?? "" : "";

    await FirebaseFirestore.instance
        .collection("questions")
        .doc(widget.questionId)
        .collection("answers")
        .add({
      "userId": user!.uid,
      "userName": user!.displayName ?? "Anonymous",
      "profileImage": profileImage,
      "answer": _answerController.text.trim(),
      "timestamp": FieldValue.serverTimestamp(),
      "likes": 0,
      "dislikes": 0,
      "likedBy": [],
      "dislikedBy": [],
    });

    _answerController.clear();
  }

  void _updateLikeDislike(String answerId, bool isLike) async {
    if (user == null) return;
    final answerRef = FirebaseFirestore.instance
        .collection("questions")
        .doc(widget.questionId)
        .collection("answers")
        .doc(answerId);

    DocumentSnapshot answerDoc = await answerRef.get();
    if (!answerDoc.exists) return;

    Map<String, dynamic> data = answerDoc.data() as Map<String, dynamic>;

    List likedBy = data['likedBy'] ?? [];
    List dislikedBy = data['dislikedBy'] ?? [];

    if (isLike) {
      if (likedBy.contains(user!.uid)) {
        await answerRef.update({
          "likes": FieldValue.increment(-1),
          "likedBy": FieldValue.arrayRemove([user!.uid]),
        });
      } else {
        await answerRef.update({
          "likes": FieldValue.increment(1),
          "likedBy": FieldValue.arrayUnion([user!.uid]),
          "dislikes": dislikedBy.contains(user!.uid)
              ? FieldValue.increment(-1)
              : FieldValue.increment(0),
          "dislikedBy": FieldValue.arrayRemove([user!.uid]),
        });
      }
    } else {
      if (dislikedBy.contains(user!.uid)) {
        await answerRef.update({
          "dislikes": FieldValue.increment(-1),
          "dislikedBy": FieldValue.arrayRemove([user!.uid]),
        });
      } else {
        await answerRef.update({
          "dislikes": FieldValue.increment(1),
          "dislikedBy": FieldValue.arrayUnion([user!.uid]),
          "likes": likedBy.contains(user!.uid)
              ? FieldValue.increment(-1)
              : FieldValue.increment(0),
          "likedBy": FieldValue.arrayRemove([user!.uid]),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text("Question Details"), backgroundColor: Colors.blue),
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("questions")
                  .doc(widget.questionId)
                  .snapshots(),
              builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final question = snapshot.data!;
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(question["title"],
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text("Asked by: ${question["userName"]}",
                              style: TextStyle(color: Colors.grey[700])),
                          SizedBox(height: 10),
                          Text(question["description"],
                              style: TextStyle(fontSize: 16)),
                          SizedBox(height: 10),
                          Divider(),
                          Text("Answers",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: StreamBuilder(
                              stream: FirebaseFirestore.instance
                                  .collection("questions")
                                  .doc(widget.questionId)
                                  .collection("answers")
                                  .orderBy("timestamp", descending: true)
                                  .snapshots(),
                              builder: (context,
                                  AsyncSnapshot<QuerySnapshot> answerSnapshot) {
                                if (!answerSnapshot.hasData) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }
                                return ListView(
                                  children: answerSnapshot.data!.docs
                                      .map((answerDoc) {
                                    final data = answerDoc.data()
                                        as Map<String, dynamic>;
                                    String answerId = answerDoc.id;

                                    return Card(
                                      margin: EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 2,
                                      color: Colors.white,
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundImage: data[
                                                                  "profileImage"] !=
                                                              null &&
                                                          data["profileImage"]
                                                              .isNotEmpty
                                                      ? NetworkImage(
                                                          data["profileImage"])
                                                      : AssetImage(
                                                              "assets/default_profile.png")
                                                          as ImageProvider,
                                                  radius: 20,
                                                ),
                                                SizedBox(width: 10),
                                                Text(data["userName"],
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                            ),
                                            SizedBox(height: 5),
                                            ExpandableText(data["answer"]),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.thumb_up,
                                                      color: data['likedBy']
                                                              .contains(
                                                                  user!.uid)
                                                          ? Colors.green
                                                          : Colors.grey),
                                                  onPressed: () =>
                                                      _updateLikeDislike(
                                                          answerId, true),
                                                ),
                                                Text("${data["likes"]}"),
                                                IconButton(
                                                  icon: Icon(Icons.thumb_down,
                                                      color: data['dislikedBy']
                                                              .contains(
                                                                  user!.uid)
                                                          ? Colors.red
                                                          : Colors.grey),
                                                  onPressed: () =>
                                                      _updateLikeDislike(
                                                          answerId, false),
                                                ),
                                                Text("${data["dislikes"]}"),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _answerController,
                        decoration: InputDecoration(
                          labelText: "Your Answer",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _postAnswer,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                      child: Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Added ExpandableText Widget
class ExpandableText extends StatefulWidget {
  final String text;
  ExpandableText(this.text);

  @override
  _ExpandableTextState createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Text(widget.text);
  }
}
