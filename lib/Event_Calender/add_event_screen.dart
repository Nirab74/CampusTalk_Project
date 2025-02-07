import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEventScreen extends StatefulWidget {
  final String? eventId;

  AddEventScreen({this.eventId});

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _reminder = false;
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _loadEventData();
    }
  }

  Future<void> _loadEventData() async {
    var docSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .get();

    if (docSnapshot.exists) {
      var eventData = docSnapshot.data() as Map<String, dynamic>;
      setState(() {
        _titleController.text = eventData['title'];
        _descController.text = eventData['description'];
        _selectedDate = DateFormat('yyyy-MM-dd').parse(eventData['date']);

        // Fix for time parsing
        _selectedTime = _parseTime(eventData['time']);

        _reminder = eventData['reminder'];
        _isPublic = eventData['isPublic'];
      });
    }
  }

  // Parsing time
  TimeOfDay _parseTime(String timeString) {
    try {
      final parsedTime = DateFormat.jm().parse(timeString);
      return TimeOfDay.fromDateTime(parsedTime);
    } catch (e) {
      return TimeOfDay.now(); // Default to the current time if parsing fails
    }
  }

  Future<void> _saveEvent() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('User not logged in!')));
        return;
      }
      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Please enter a title.')));
        return;
      }

      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      String formattedTime =
          _selectedTime.format(context); // Save in 12-hour format
      String eventId = widget.eventId ??
          FirebaseFirestore.instance.collection('events').doc().id;

      Map<String, dynamic> eventData = {
        'id': eventId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'date': formattedDate,
        'time': formattedTime, // Store the time in 12-hour format
        'reminder': _reminder,
        'isPublic': _isPublic,
        'userId': user.uid,
      };

      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .set(eventData, SetOptions(merge: true));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Event Saved!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventId == null ? 'Add Event' : 'Edit Event'),
        backgroundColor: const Color.fromARGB(255, 143, 143, 146),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(_titleController, 'Title'),
            SizedBox(height: 10),
            _buildTextField(_descController, 'Description', maxLines: 3),
            SizedBox(height: 10),
            _buildDateTimePicker(
                'Date', DateFormat.yMMMd().format(_selectedDate), _pickDate),
            _buildDateTimePicker(
                'Time', _selectedTime.format(context), _pickTime),
            _buildSwitchTile('Set Reminder', _reminder,
                (val) => setState(() => _reminder = val)),
            _buildSwitchTile('Make Event Public', _isPublic,
                (val) => setState(() => _isPublic = val)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveEvent,
              child: Text("Save Event"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildDateTimePicker(String label, String value, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: Colors.grey[200],
      title: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: TextStyle(fontSize: 16)),
      trailing: Icon(Icons.calendar_today, color: Colors.blueAccent),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blueAccent,
    );
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) setState(() => _selectedDate = pickedDate);
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null) setState(() => _selectedTime = pickedTime);
  }
}
