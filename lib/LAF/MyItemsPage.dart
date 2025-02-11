import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ItemDetailPage.dart';
import 'PostItemPage.dart';

class MyItemsPage extends StatelessWidget {
  final String userId;

  MyItemsPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Lost and Found Items'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostItemPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lost_and_found')
            .where('user_id', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No items posted.'));
          }

          var items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16.0),
                  leading: item['image_url'] != null
                      ? Image.network(item['image_url'],
                          width: 50, height: 50, fit: BoxFit.cover)
                      : Icon(Icons.image, size: 50),
                  title: Text(item['title']),
                  subtitle: Text(item['description']),
                  trailing: Text(item['status']),
                  onTap: () {
                    // Navigate to the ItemDetailPage with the item's ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailPage(itemId: item.id),
                      ),
                    );
                  },
                  onLongPress: () {
                    // Show options to delete or edit the post
                    _showItemOptions(context, item);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Function to show options to delete or edit the item
  void _showItemOptions(BuildContext context, DocumentSnapshot item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Manage Item'),
          content: Text('Do you want to edit or delete this post?'),
          actions: [
            TextButton(
              onPressed: () {
                // Navigate to PostItemPage with existing data to edit
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PostItemPage(), // Add logic for editing
                  ),
                );
              },
              child: Text('Edit'),
            ),
            TextButton(
              onPressed: () {
                // Delete the item from Firestore
                FirebaseFirestore.instance
                    .collection('lost_and_found')
                    .doc(item.id)
                    .delete();
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
