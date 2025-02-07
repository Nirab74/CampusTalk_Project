import 'package:campustalk/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class AddBlogScreen extends StatefulWidget {
  @override
  _AddBlogScreenState createState() => _AddBlogScreenState();
}

class _AddBlogScreenState extends State<AddBlogScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();
  String? selectedCategory;
  File? _image;
  bool isLoading = false;

  List<String> categories = ["Technology", "Education", "Lifestyle", "Health"];

  Future<String?> uploadImageToImgBB(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://api.imgbb.com/1/upload?key=$IMGBB_API_KEY"),
      );
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (jsonData['success']) {
        return jsonData['data']['url'];
      } else {
        throw Exception("Failed to upload image");
      }
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  Future<void> submitBlog() async {
    if (!_formKey.currentState!.validate() ||
        selectedCategory == null ||
        _image == null) {
      return;
    }

    setState(() => isLoading = true);

    String? imageUrl = await uploadImageToImgBB(_image!);

    if (imageUrl == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image")),
      );
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection("blogs").add({
        "title": titleController.text,
        "content": contentController.text,
        "category": selectedCategory,
        "imageUrl": imageUrl,
        "authorId": user!.uid,
        "authorName": user.displayName ?? "Anonymous",
        "timestamp": FieldValue.serverTimestamp(),
      });

      setState(() => isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Blog posted successfully")),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error posting blog: $e")),
      );
    }
  }

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Blog Post"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title Input Field
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: "Blog Title",
                          labelStyle: TextStyle(color: Colors.blueAccent),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Title required" : null,
                      ),
                      SizedBox(height: 16.0),

                      // Content Input Field
                      TextFormField(
                        controller: contentController,
                        decoration: InputDecoration(
                          labelText: "Content",
                          labelStyle: TextStyle(color: Colors.blueAccent),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                        maxLines: 5,
                        validator: (value) =>
                            value!.isEmpty ? "Content required" : null,
                      ),
                      SizedBox(height: 16.0),

                      // Category Dropdown
                      DropdownButtonFormField(
                        value: selectedCategory,
                        hint: Text("Select Category"),
                        style: TextStyle(color: Colors.blueAccent),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                        items: categories
                            .map((cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedCategory = value as String?),
                      ),
                      SizedBox(height: 16.0),

                      // Image Picker Section
                      _image == null
                          ? Text(
                              "No image selected",
                              style: TextStyle(color: Colors.grey),
                            )
                          : Image.file(_image!, height: 100),
                      TextButton.icon(
                        icon: Icon(Icons.image),
                        label: Text("Pick Image"),
                        onPressed: pickImage,
                        style: TextButton.styleFrom(
                          iconColor: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(height: 16.0),

                      // Submit Button
                      ElevatedButton(
                        onPressed: submitBlog,
                        style: ElevatedButton.styleFrom(
                          iconColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: Text(
                          "Post Blog",
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
