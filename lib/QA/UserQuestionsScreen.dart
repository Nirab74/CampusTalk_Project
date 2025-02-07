import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserQuestionsScreen extends StatelessWidget {
  const UserQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text("My Questions")),
        body: Center(child: Text("Please log in to view your questions.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("My Questions")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("questions")
            .where("userId", isEqualTo: user.uid) // ✅ No more null error
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("You haven't asked any questions yet."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String title = data["title"] ?? "No Title";
              final String description =
                  data["description"] ?? "No Description";
              final String category = data["category"] ?? "No Category";
              final int upvotes = data["upvotes"] ?? 0;
              final String profileImage = data["profileImage"] ?? "";
              final String userName = data["userName"] ?? "Anonymous";

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info
                      Row(
                        children: [
                          profileImage.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(profileImage),
                                  radius: 20)
                              : CircleAvatar(
                                  child: Icon(Icons.person), radius: 20),
                          SizedBox(width: 10),
                          Text(userName,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 8),

                      // Question Title
                      Text(title,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),

                      // Description
                      Text(description,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 8),

                      // Category & Upvotes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(category),
                          ),
                          Row(
                            children: [
                              Icon(Icons.thumb_up, color: Colors.blue),
                              SizedBox(width: 5),
                              Text("$upvotes Upvotes"),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 10),

                      // Delete Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _confirmDelete(context, doc.reference),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, DocumentReference docRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Question"),
        content: Text("Are you sure you want to delete this question?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await docRef.delete();
              Navigator.pop(context);
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
