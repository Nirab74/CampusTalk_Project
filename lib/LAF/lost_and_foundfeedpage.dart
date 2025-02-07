import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'post_item_page.dart'; // Import the PostItemPage.dart file
import 'item_detail_page.dart'; // Import the ItemDetailPage.dart

class LostAndFoundFeedPage extends StatefulWidget {
  @override
  _LostAndFoundFeedPageState createState() => _LostAndFoundFeedPageState();
}

class _LostAndFoundFeedPageState extends State<LostAndFoundFeedPage> {
  String _statusFilter = 'All'; // Default filter is 'All'
  String _categoryFilter = 'All'; // Default category filter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lost and Found Items'),
        actions: [
          // Filter Dropdowns for status and category
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          // Button to navigate to PostItemPage to add new lost or found item
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navigate to the PostItemPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PostItemPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lost_and_found')
            .where('status',
                isEqualTo: _statusFilter == 'All' ? null : _statusFilter)
            .where('category',
                isEqualTo: _categoryFilter == 'All' ? null : _categoryFilter)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No items found.'));
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
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Show filter dialog for status and category selection
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter Items'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: _statusFilter,
                onChanged: (String? newValue) {
                  setState(() {
                    _statusFilter = newValue!;
                  });
                  Navigator.pop(context);
                },
                items: ['All', 'Lost', 'Found']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              DropdownButton<String>(
                value: _categoryFilter,
                onChanged: (String? newValue) {
                  setState(() {
                    _categoryFilter = newValue!;
                  });
                  Navigator.pop(context);
                },
                items: ['All', 'Electronics', 'Clothing', 'Accessories']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
