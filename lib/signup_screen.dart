import 'dart:convert'; // Add this for JSON
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() =>
      _SignupScreenState();
}

class _SignupScreenState
    extends State<SignupScreen> {

  final nameController =
  TextEditingController();

  final emailController =
  TextEditingController();

  final phoneController =
  TextEditingController();

  final passwordController =
  TextEditingController();

  final confirmPasswordController =
  TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool acceptTerms = false;

  void _handleSignup() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String phone = phoneController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    if (!acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept Terms & Conditions")),
      );
      return;
    }

    // Save user details locally in a list
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing users list
    List<String> usersList = prefs.getStringList('all_users') ?? [];
    
    // Check if email already exists
    bool alreadyExists = usersList.any((u) {
      Map<String, dynamic> user = jsonDecode(u);
      return user['email'] == email;
    });

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email already registered. Please Login.")),
      );
      return;
    }

    // Add new user to list
    Map<String, String> newUser = {
      'name': name,
      'email': email,
      'password': password,
    };
    usersList.add(jsonEncode(newUser));
    
    // Save updated list back to memory
    await prefs.setStringList('all_users', usersList);
    
    // Also set as last registered user for auto-fill
    await prefs.setString('user_email', email);
    await prefs.setString('user_password', password);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context); // Close loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Success"),
          content: const Text("Account created successfully! You can now login."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close success dialog
                Navigator.pop(context); // Back to Login screen
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(24),

          child: Column(
            children: [

              const SizedBox(height: 20),

              Container(
                height: 180,
                width: 180,

                decoration:
                const BoxDecoration(
                  color:
                  Color(0xFFEAF2FF),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.person_add,
                  size: 100,
                  color:
                  Color(0xFF0A4DDE),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Join CampusNav today",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller:
                nameController,

                decoration:
                InputDecoration(
                  hintText:
                  "Full Name",

                  prefixIcon:
                  const Icon(
                      Icons.person),

                  filled: true,
                  fillColor:
                  Colors.grey.shade100,

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                        15),
                    borderSide:
                    BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                emailController,

                decoration:
                InputDecoration(
                  hintText:
                  "Email",

                  prefixIcon:
                  const Icon(
                      Icons.email),

                  filled: true,
                  fillColor:
                  Colors.grey.shade100,

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                        15),
                    borderSide:
                    BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                phoneController,

                keyboardType:
                TextInputType.phone,

                decoration:
                InputDecoration(
                  hintText:
                  "Phone Number",

                  prefixIcon:
                  const Icon(
                      Icons.phone),

                  filled: true,
                  fillColor:
                  Colors.grey.shade100,

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                        15),
                    borderSide:
                    BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                passwordController,

                obscureText:
                obscurePassword,

                decoration:
                InputDecoration(
                  hintText:
                  "Password",

                  prefixIcon:
                  const Icon(
                      Icons.lock),

                  suffixIcon:
                  IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons
                          .visibility_off
                          : Icons
                          .visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword =
                        !obscurePassword;
                      });
                    },
                  ),

                  filled: true,
                  fillColor:
                  Colors.grey.shade100,

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                        15),
                    borderSide:
                    BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                confirmPasswordController,

                obscureText:
                obscureConfirmPassword,

                decoration:
                InputDecoration(
                  hintText:
                  "Confirm Password",

                  prefixIcon:
                  const Icon(
                      Icons.lock),

                  suffixIcon:
                  IconButton(
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons
                          .visibility_off
                          : Icons
                          .visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureConfirmPassword =
                        !obscureConfirmPassword;
                      });
                    },
                  ),

                  filled: true,
                  fillColor:
                  Colors.grey.shade100,

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                        15),
                    borderSide:
                    BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Checkbox(
                    value: acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        acceptTerms =
                            value ?? false;
                      });
                    },
                  ),

                  const Expanded(
                    child: Text(
                      "I agree to the Terms & Conditions",
                    ),
                  )
                ],
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  style:
                  ElevatedButton
                      .styleFrom(
                    backgroundColor:
                    const Color(
                        0xFF0A4DDE),

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius
                          .circular(
                          15),
                    ),
                  ),

                  onPressed: _handleSignup,

                  child: const Text(
                    "Create Account",
                    style: TextStyle(
                      color:
                      Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.pop(
                      context);
                },
                child: const Text(
                  "Already have an account? Login",
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}