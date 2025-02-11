import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_blog_screen.dart';
import 'add_blog_screen.dart'; // Import the AddBlogScreen
import 'blog_detail_screen.dart'; // Import BlogDetailScreen
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage

class BlogListScreen extends StatelessWidget {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  void _deleteBlog(String blogId) async {
    await FirebaseFirestore.instance.collection("blogs").doc(blogId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Blogs"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("blogs")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var blogs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: blogs.length,
            itemBuilder: (context, index) {
              var blog = blogs[index];
              bool isAuthor = blog["authorId"] == currentUser?.uid;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlogDetailScreen(blogId: blog.id),
                    ),
                  );
                },
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: blog["imageUrl"],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                    title: Text(
                      blog["title"],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(blog["category"]),
                    trailing: isAuthor
                        ? PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == "edit") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditBlogScreen(blogId: blog.id),
                                  ),
                                );
                              } else if (value == "delete") {
                                _deleteBlog(blog.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                  value: "edit", child: Text("Edit")),
                              const PopupMenuItem(
                                  value: "delete", child: Text("Delete")),
                            ],
                          )
                        : null, // No trailing button for non-authors
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddBlogScreen()),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
