import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class EditBlogScreen extends StatefulWidget {
  final String blogId;

  EditBlogScreen({required this.blogId});

  @override
  _EditBlogScreenState createState() => _EditBlogScreenState();
}

class _EditBlogScreenState extends State<EditBlogScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();
  String? selectedCategory;
  File? _newImage;
  String? _currentImageUrl;
  bool isLoading = false;

  List<String> categories = ["Technology", "Education", "Lifestyle", "Health"];

  @override
  void initState() {
    super.initState();
    _loadBlogDetails();
  }

  Future<void> _loadBlogDetails() async {
    var doc = await FirebaseFirestore.instance
        .collection("blogs")
        .doc(widget.blogId)
        .get();
    if (doc.exists) {
      setState(() {
        titleController.text = doc["title"];
        contentController.text = doc["content"];
        selectedCategory = doc["category"];
        _currentImageUrl = doc["imageUrl"];
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("https://api.imgbb.com/1/upload?key=YOUR_IMGBB_API_KEY"),
    );
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var jsonData = json.decode(responseData);
    return jsonData['data']['url'];
  }

  Future<void> _updateBlog() async {
    if (!_formKey.currentState!.validate() || selectedCategory == null) {
      return;
    }

    setState(() => isLoading = true);

    String? imageUrl = _currentImageUrl;
    if (_newImage != null) {
      imageUrl = await _uploadImage(_newImage!);
    }

    await FirebaseFirestore.instance
        .collection("blogs")
        .doc(widget.blogId)
        .update({
      "title": titleController.text,
      "content": contentController.text,
      "category": selectedCategory,
      "imageUrl": imageUrl,
    });

    setState(() => isLoading = false);
    Navigator.pop(context);
  }

  Future<void> _pickNewImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _newImage = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Blog")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: "Blog Title"),
                      validator: (value) =>
                          value!.isEmpty ? "Title required" : null,
                    ),
                    TextFormField(
                      controller: contentController,
                      decoration: InputDecoration(labelText: "Content"),
                      maxLines: 5,
                      validator: (value) =>
                          value!.isEmpty ? "Content required" : null,
                    ),
                    DropdownButtonFormField(
                      value: selectedCategory,
                      hint: Text("Select Category"),
                      items: categories
                          .map((cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedCategory = value as String?),
                    ),
                    SizedBox(height: 10),
                    _newImage != null
                        ? Image.file(_newImage!, height: 100)
                        : _currentImageUrl != null
                            ? Image.network(_currentImageUrl!, height: 100)
                            : Text("No image selected"),
                    TextButton.icon(
                      icon: Icon(Icons.image),
                      label: Text("Change Image"),
                      onPressed: _pickNewImage,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _updateBlog,
                      child: Text("Update Blog"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
