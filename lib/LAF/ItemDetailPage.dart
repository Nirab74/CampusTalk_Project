import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ItemDetailPage extends StatelessWidget {
  final String itemId;

  ItemDetailPage({required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Item Details', style: TextStyle(fontSize: 22)),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('lost_and_found')
            .doc(itemId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
                child: Text('Item not found',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
          }

          var item = snapshot.data!;

          String title = item.get('title') ?? 'Untitled Item';
          String description =
              item.get('description') ?? 'No description provided.';
          String location = item.get('location') ?? 'Location not provided';
          String contact = item.get('contact') ?? 'No contact provided';
          String status = item.get('status') ?? 'Unknown';
          String category = item.get('category') ?? 'General';
          String imageUrl = item.get('image_url') ?? '';

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.image, size: 50, color: Colors.grey),
                          )
                        : Container(
                            height: 250,
                            color: Colors.grey[300],
                            child: Center(
                              child: Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DetailRow(
                              icon: Icons.category,
                              label: 'Category',
                              value: category),
                          DetailRow(
                              icon: Icons.info, label: 'Status', value: status),
                          DetailRow(
                              icon: Icons.location_on,
                              label: 'Location',
                              value: location),
                          DetailRow(
                              icon: Icons.phone,
                              label: 'Contact',
                              value: contact),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
