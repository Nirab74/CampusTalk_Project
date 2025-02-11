import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage

class BlogDetailScreen extends StatefulWidget {
  final String blogId;
  BlogDetailScreen({required this.blogId});

  @override
  _BlogDetailScreenState createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  TextEditingController commentController = TextEditingController();
  User? currentUser = FirebaseAuth.instance.currentUser;
  bool isLiked = false;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchLikeStatus();
  }

  Future<void> _fetchLikeStatus() async {
    DocumentSnapshot blogDoc = await FirebaseFirestore.instance
        .collection("blogs")
        .doc(widget.blogId)
        .get();

    if (blogDoc.exists) {
      var blogData = blogDoc.data() as Map<String, dynamic>?;
      List<dynamic> likes = blogData?["likes"] ?? [];

      setState(() {
        isLiked = likes.contains(currentUser?.uid);
        likeCount = likes.length;
      });
    }
  }

  void _toggleLike() async {
    DocumentReference blogRef =
        FirebaseFirestore.instance.collection("blogs").doc(widget.blogId);
    DocumentSnapshot blogDoc = await blogRef.get();
    var blogData = blogDoc.data() as Map<String, dynamic>?;
    List<dynamic> likes = blogData?["likes"] ?? [];

    if (isLiked) {
      await blogRef.update({
        "likes": FieldValue.arrayRemove([currentUser?.uid])
      });
      setState(() {
        isLiked = false;
        likeCount--;
      });
    } else {
      await blogRef.update({
        "likes": FieldValue.arrayUnion([currentUser?.uid])
      });
      setState(() {
        isLiked = true;
        likeCount++;
      });
    }
  }

  Future<void> _addComment() async {
    if (commentController.text.trim().isEmpty) return;

    String profileUrl =
        currentUser?.photoURL ?? "https://example.com/default-profile.png";
    String username = currentUser?.displayName?.isNotEmpty == true
        ? currentUser!.displayName!
        : "Anonymous";

    await FirebaseFirestore.instance
        .collection("blogs")
        .doc(widget.blogId)
        .collection("comments")
        .add({
      "userId": currentUser!.uid,
      "username": username,
      "userProfile": profileUrl,
      "text": commentController.text.trim(),
      "timestamp": FieldValue.serverTimestamp(),
    });

    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Blog Details"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("blogs")
                  .doc(widget.blogId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());
                var blog = snapshot.data!;
                var blogData = blog.data() as Map<String, dynamic>?;
                if (blogData == null)
                  return Center(child: Text("Blog not found"));

                return SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CachedNetworkImage(
                        imageUrl: blogData["imageUrl"] ??
                            "https://example.com/default-image.jpg",
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                      SizedBox(height: 10),
                      Text(blogData["title"] ?? "No Title",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text(blogData["content"] ?? "No content available",
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                            ),
                            onPressed: _toggleLike,
                          ),
                          Text("$likeCount Likes"),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text("Comments",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      _buildComments(),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildComments() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("blogs")
          .doc(widget.blogId)
          .collection("comments")
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());
        var comments = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            var comment = comments[index];
            var commentData = comment.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 3,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                      commentData["userProfile"] ??
                          "https://example.com/default-profile.png"),
                ),
                title: Text(commentData["username"] ?? "Anonymous",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(commentData["text"] ?? ""),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: "Write a comment...",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, color: Colors.blue),
            onPressed: _addComment,
          ),
        ],
      ),
    );
  }
}
