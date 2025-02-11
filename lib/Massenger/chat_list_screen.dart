import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campustalk/Massenger/chat_screen.dart';
import 'find_users_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = auth.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Chats")),
        body: const Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              onChanged: (query) {
                setState(() {
                  searchQuery = query.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search for a chat...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('chats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No chats available"));
                }

                var chats = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return data['user1'] == currentUserId ||
                      data['user2'] == currentUserId;
                }).toList();

                if (chats.isEmpty) {
                  return const Center(child: Text("No chats available"));
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    var chat = chats[index].data() as Map<String, dynamic>;
                    String otherUserId = chat['user1'] == currentUserId
                        ? chat['user2']
                        : chat['user1'];
                    String lastMessage =
                        chat['lastMessage'] ?? "No messages yet";

                    return FutureBuilder<DocumentSnapshot>(
                      future:
                          firestore.collection('users').doc(otherUserId).get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox();
                        }
                        if (!userSnapshot.hasData ||
                            !userSnapshot.data!.exists) {
                          return const SizedBox();
                        }

                        var userData =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        String username =
                            userData['username'] ?? "Unknown User";
                        String profileImage = userData['profileImage'] ?? "";

                        if (searchQuery.isNotEmpty &&
                            !username.toLowerCase().contains(searchQuery)) {
                          return const SizedBox();
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 30,
                              backgroundImage: profileImage.isNotEmpty
                                  ? NetworkImage(profileImage)
                                  : null,
                              child: profileImage.isEmpty
                                  ? const Icon(Icons.person,
                                      color: Colors.white)
                                  : null,
                            ),
                            title: Text(username,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(lastMessage,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    receiverId: otherUserId,
                                    receiverName: username,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FindUsersScreen()),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
