import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AskQuestionScreen.dart';
import 'QuestionDetailScreen.dart';

class QuestionListScreen extends StatefulWidget {
  @override
  _QuestionListScreenState createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String selectedCategory = "All";
  String searchQuery = "";

  void toggleUpvote(String questionId, List<String> upvotedBy) async {
    if (user == null) return;

    final userId = user!.uid;
    final questionRef =
        FirebaseFirestore.instance.collection("questions").doc(questionId);

    if (upvotedBy.contains(userId)) {
      await questionRef.update({
        "upvotes": FieldValue.increment(-1),
        "upvotedBy": FieldValue.arrayRemove([userId]),
      });
    } else {
      await questionRef.update({
        "upvotes": FieldValue.increment(1),
        "upvotedBy": FieldValue.arrayUnion([userId]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Questions"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              onChanged: (value) => setState(() => selectedCategory = value!),
              items: [
                "All",
                "Education",
                "Research",
                "Travel",
                "University Transport",
                "University Clubs"
              ]
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("questions")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var questions = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final doc = questions[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final String questionId = doc.id;
                    final String title = data["title"] ?? "No Title";
                    final String description =
                        data["description"] ?? "No Description";
                    final String userId = data["userId"] ?? "";
                    final int upvotes = data["upvotes"] ?? 0;
                    final List<String> upvotedBy =
                        List<String>.from(data["upvotedBy"] ?? []);

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection("users")
                          .doc(userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return SizedBox.shrink();
                        }

                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>?;
                        final String userName =
                            userData?["username"] ?? "Anonymous";
                        final String profileImage =
                            userData?["profileImage"] ?? "";

                        return Card(
                          margin:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    profileImage.isNotEmpty
                                        ? CircleAvatar(
                                            backgroundImage:
                                                NetworkImage(profileImage),
                                            radius: 20)
                                        : CircleAvatar(
                                            child: Icon(Icons.person),
                                            radius: 20),
                                    SizedBox(width: 10),
                                    Text(userName,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(title,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text(description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            upvotedBy.contains(user!.uid)
                                                ? Icons.thumb_up_alt
                                                : Icons.thumb_up_alt_outlined,
                                            color: upvotedBy.contains(user?.uid)
                                                ? Colors.blue
                                                : Colors.black,
                                          ),
                                          onPressed: () => toggleUpvote(
                                              questionId, upvotedBy),
                                        ),
                                        Text("$upvotes Upvotes"),
                                      ],
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                QuestionDetailScreen(
                                              questionId: questionId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text("Give Answer"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => AskQuestionScreen()));
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
