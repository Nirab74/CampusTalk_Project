import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ItemDetailPage extends StatelessWidget {
  final String itemId;

  ItemDetailPage({required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Item Details'),
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
            return Center(child: Text('Item not found'));
          }

          var item = snapshot.data!;
          double latitude = item['latitude'] ?? 0.0;
          double longitude = item['longitude'] ?? 0.0;

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the image
                item['image_url'] != null
                    ? Image.network(item['image_url'],
                        height: 200, fit: BoxFit.cover)
                    : Container(height: 200, color: Colors.grey),
                SizedBox(height: 16),
                // Display title, status, category, and location
                Text(item['title'],
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Status: ${item['status']}'),
                Text('Category: ${item['category']}'),
                Text('Location: ${item['location']}'),
                SizedBox(height: 16),
                // Google Map displaying the item's location
                Container(
                  height: 250,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(latitude, longitude),
                      zoom: 14,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId(itemId),
                        position: LatLng(latitude, longitude),
                        infoWindow: InfoWindow(
                          title: item['location'],
                          snippet: item['title'],
                        ),
                      ),
                    },
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Implement contacting the poster or updating status
                  },
                  child: Text('Contact Poster'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
