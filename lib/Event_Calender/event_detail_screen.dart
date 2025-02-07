import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_event_screen.dart'; // Import your AddEventScreen

class EventDetailScreen extends StatelessWidget {
  final String eventId;

  EventDetailScreen({required this.eventId});

  Future<DocumentSnapshot> _getEventDetails() async {
    return FirebaseFirestore.instance.collection('events').doc(eventId).get();
  }

  Future<void> _deleteEvent(BuildContext context) async {
    await FirebaseFirestore.instance.collection('events').doc(eventId).delete();
    Navigator.pop(context); // Go back to the previous screen after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.grey[50], // Light background for a professional feel
      appBar: AppBar(
        backgroundColor: Colors.white, // White background for the app bar
        elevation: 2, // Light shadow for depth
        title: Text(
          'Event Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800], // Dark grey color for text
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _getEventDetails(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var eventData = snapshot.data?.data() as Map<String, dynamic>?;

          // Handle null data
          if (eventData == null) {
            return Center(child: Text('Event data is not available.'));
          }

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  eventData['title'] ?? 'No Title',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[800], // Consistent text color
                  ),
                ),
                SizedBox(height: 12),

                // Description
                Text(
                  eventData['description'] ?? 'No description available.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey[600], // Softer grey for description
                  ),
                ),
                SizedBox(height: 20),

                // Date
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.blueGrey[600]),
                    SizedBox(width: 8),
                    Text(
                      "Date: ${eventData['date'] ?? 'N/A'}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Time
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blueGrey[600]),
                    SizedBox(width: 8),
                    Text(
                      "Time: ${eventData['time'] ?? 'N/A'}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),

                // Action Buttons (Edit, Delete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Edit Button
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to AddEventScreen for editing
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddEventScreen(eventId: eventId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.blueGrey[800], // Soft blue-grey button
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Edit",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white, // White text color
                        ),
                      ),
                    ),
                    // Delete Button
                    ElevatedButton(
                      onPressed: () => _deleteEvent(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.red[400], // Light red for delete
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Delete",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white, // White text color
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
