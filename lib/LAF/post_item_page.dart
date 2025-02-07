import 'dart:convert';
import 'dart:io';
import 'package:campustalk/config.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart'; // Add this package for geolocation lookup

class PostItemPage extends StatefulWidget {
  const PostItemPage({super.key});

  @override
  _PostItemPageState createState() => _PostItemPageState();
}

class _PostItemPageState extends State<PostItemPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  String _status = 'Lost'; // Default status
  String _category = 'Electronics'; // Default category
  File? _image;

  double? latitude;
  double? longitude;

  final ImagePicker _picker = ImagePicker();

  // ImgBB API Key (replace with your own)
  final String imgBBApiKey = IMGBB_API_KEY;

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Function to upload image to ImgBB
  Future<String?> _uploadImageToImgBB(File image) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['key'] = imgBBApiKey
        ..files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseJson = json.decode(responseBody);

      if (responseJson['success']) {
        return responseJson['data']['url'];
      } else {
        return null;
      }
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // Function to get coordinates from address (location)
  Future<void> _getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          latitude = locations.first.latitude;
          longitude = locations.first.longitude;
        });
      }
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  // Function to post the lost or found item to Firestore
  Future<void> _postItem() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _contactController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    try {
      String? imageUrl = '';
      if (_image != null) {
        // Upload image to ImgBB
        imageUrl = await _uploadImageToImgBB(_image!);
        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image.')),
          );
          return;
        }
      }

      await FirebaseFirestore.instance.collection('lost_and_found').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'status': _status,
        'category': _category,
        'location': _locationController.text,
        'contact': _contactController.text, // Store the contact number
        'latitude': latitude, // Store the latitude
        'longitude': longitude, // Store the longitude
        'image_url': imageUrl, // Store the ImgBB image URL
        'created_at': Timestamp.now(),
      });

      Navigator.pop(context); // Go back after posting
    } catch (e) {
      print("Error posting item: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Lost or Found Item', style: TextStyle(fontSize: 22)),
        backgroundColor: Color(0xFF009688), // Teal color for fresh look
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Post an Item',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800, // Modern bold color for the title
              ),
            ),
            SizedBox(height: 20),
            _buildTextField('Item Title', _titleController),
            SizedBox(height: 16),
            _buildTextField('Description', _descriptionController, maxLines: 3),
            SizedBox(height: 16),
            _buildTextField('Location', _locationController),
            SizedBox(height: 16),
            _buildTextField('Contact Number', _contactController,
                maxLines: 1), // Added contact field
            SizedBox(height: 16),
            _buildDropdownField('Status', ['Lost', 'Found'], _status,
                (newValue) {
              setState(() {
                _status = newValue!;
              });
            }),
            SizedBox(height: 16),
            _buildDropdownField(
                'Category',
                ['Electronics', 'Clothing', 'Accessories'],
                _category, (newValue) {
              setState(() {
                _category = newValue!;
              });
            }),
            SizedBox(height: 16),
            _buildImagePicker(),
            SizedBox(height: 20),
            _buildPostButton(),
          ],
        ),
      ),
    );
  }

  // Helper method to create a styled TextField
  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.teal.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (text) {
          // Get coordinates when location field is changed
          _getCoordinatesFromAddress(text);
        },
      ),
    );
  }

  // Helper method to create a dropdown field
  Widget _buildDropdownField(String label, List<String> items, String value,
      Function(String?) onChanged) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.teal.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade400),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  // Helper method for image picker
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.teal.shade100,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.shade300,
              offset: Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: Colors.teal.shade600),
            SizedBox(width: 8),
            Text(
              _image == null ? 'Pick an image' : 'Change image',
              style: TextStyle(color: Colors.teal.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create post button
  Widget _buildPostButton() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green, Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _postItem,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Colors.transparent, // Transparent background for gradient effect
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Post Item',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
