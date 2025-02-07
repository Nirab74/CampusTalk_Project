import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key});

  @override
  _AskQuestionScreenState createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = "Education";
  bool _isPosting = false; // Prevents multiple submissions

  void _postQuestion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Title and Description cannot be empty!")),
      );
      return;
    }

    setState(() => _isPosting = true); // Disable button during submission

    await FirebaseFirestore.instance.collection("questions").add({
      "userId": user.uid,
      "userName": user.displayName ?? "Anonymous",
      "profileImage": user.photoURL ?? "", // Store user profile image
      "title": _titleController.text.trim(),
      "description": _descController.text.trim(),
      "timestamp": FieldValue.serverTimestamp(),
      "category": _selectedCategory,
      "upvotes": 0,
      "upvotedBy": [], // Initialize empty upvote list
    });

    setState(() => _isPosting = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ask a Question")),
      backgroundColor: Colors.blue.shade50, // Background color
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Title",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: "Enter your question title...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text("Description",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Provide more details...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text("Select Category",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value!),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                    ),
                    items: [
                      "Education",
                      "Research",
                      "Travel",
                      "University Transport",
                      "University Clubs"
                    ]
                        .map((cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                  ),
                  SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isPosting ? null : _postQuestion,
                      child: _isPosting
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text("Post Question"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
