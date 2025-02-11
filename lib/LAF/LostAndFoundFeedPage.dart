import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'ItemDetailPage.dart';
import 'PostItemPage.dart';

class LostAndFoundFeedPage extends StatefulWidget {
  @override
  _LostAndFoundFeedPageState createState() => _LostAndFoundFeedPageState();
}

class _LostAndFoundFeedPageState extends State<LostAndFoundFeedPage> {
  String _statusFilter = 'All'; // Default filter for status
  String _categoryFilter = 'All'; // Default filter for category

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lost & Found'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog, // Using AlertDialog for filtering
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('lost_and_found').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No items found.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            );
          }

          var items = snapshot.data!.docs.where((item) {
            if (_statusFilter != 'All' && item['status'] != _statusFilter) {
              return false;
            }
            if (_categoryFilter != 'All' &&
                item['category'] != _categoryFilter) {
              return false;
            }
            return true;
          }).toList();

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item['image_url'] ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 60,
                        height: 60,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.broken_image, size: 60),
                    ),
                  ),
                  title: Text(
                    item['title'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    item['category'],
                    style: TextStyle(color: Colors.teal, fontSize: 14),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          item['status'] == 'Lost' ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['status'],
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onTap: () {
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostItemPage()),
          );
        },
        backgroundColor: Colors.teal,
        child: Icon(Icons.add, size: 30),
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status Filter
                Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                Column(
                  children: ['All', 'Lost', 'Found'].map((status) {
                    return RadioListTile<String>(
                      title: Text(status),
                      value: status,
                      groupValue: _statusFilter,
                      onChanged: (String? newValue) {
                        setState(() {
                          _statusFilter = newValue!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
                Divider(),

                // Category Filter
                Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                Column(
                  children: ['All', 'Electronics', 'Clothing', 'Accessories']
                      .map((category) {
                    return RadioListTile<String>(
                      title: Text(category),
                      value: category,
                      groupValue: _categoryFilter,
                      onChanged: (String? newValue) {
                        setState(() {
                          _categoryFilter = newValue!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
