import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'home.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _selectedDepartment;
  bool _isLoading = false;
  String _errorMessage = '';

  final List<String> _departments = [
    "CSE",
    "EEE",
    "Civil Engineering",
    "Architecture",
    "Law",
    "English",
    "Bangla"
  ];

  // Improved Password Validation Regex
  final RegExp _passwordRegex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');

  // Signup Function
  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Email Validation
    if (!_emailController.text.endsWith('@lus.ac.bd')) {
      _showError("Only @lus.ac.bd emails are allowed.");
      return;
    }

    // Password Validation
    if (!_passwordRegex.hasMatch(_passwordController.text)) {
      _showError(
          "Password must be at least 8 characters, include an uppercase letter, lowercase letter, number, and special character.");
      return;
    }

    // Confirm Password Validation
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      _showError("Passwords do not match.");
      return;
    }

    // Department Selection Validation
    if (_selectedDepartment == null) {
      _showError("Please select a department.");
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'department': _selectedDepartment,
          'profileImage': '',
        });

        // Clear Fields After Successful Signup
        _usernameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Sign-up failed. Please try again.");
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Function to Show Error Messages
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildSignupCard(),
              const SizedBox(height: 20),
              _buildLoginNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(50),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: const [
          Text(
            "CampusTalk",
            style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 5),
          Text(
            "Learn Beyond the Classroom Walls!",
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)
        ],
      ),
      child: Column(
        children: [
          _buildTextField("Username", Icons.person, _usernameController),
          _buildTextField("Email", Icons.email, _emailController,
              inputType: TextInputType.emailAddress),
          _buildTextField("Password", Icons.lock, _passwordController,
              isPassword: true),
          _buildTextField(
              "Confirm Password", Icons.lock, _confirmPasswordController,
              isPassword: true),
          const SizedBox(height: 10),
          _buildDepartmentDropdown(),
          const SizedBox(height: 10),
          if (_errorMessage.isNotEmpty)
            Text(_errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 14)),
          const SizedBox(height: 20),
          _buildSignupButton(),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String hint, IconData icon, TextEditingController controller,
      {bool isPassword = false, TextInputType? inputType}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType ?? TextInputType.text,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none),
      ),
      hint: const Text("Select Department"),
      value: _selectedDepartment,
      onChanged: (value) => setState(() => _selectedDepartment = value),
      items: _departments
          .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
          .toList(),
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signup,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50))),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Sign Up",
                style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  Widget _buildLoginNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account? ", style: TextStyle(fontSize: 16)),
        TextButton(
          onPressed: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginPage())),
          child: const Text("Login",
              style: TextStyle(
                  color: Colors.lightBlue, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
