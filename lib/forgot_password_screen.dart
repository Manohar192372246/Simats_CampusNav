import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {

  final emailController =
  TextEditingController();

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

              const SizedBox(height: 30),

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
                  Icons.lock_reset,
                  size: 100,
                  color:
                  Color(0xFF0A4DDE),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Forgot Password?",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Enter your email address and we'll send you an OTP.",
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller:
                emailController,

                decoration:
                InputDecoration(
                  hintText:
                  "Enter Email",

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

              const SizedBox(height: 30),

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

                  onPressed: () {
                    String email = emailController.text.trim();
                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter your email")),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OtpVerificationScreen(email: email),
                      ),
                    );
                  },

                  child: const Text(
                    "Send OTP",
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
                  "Back to Login",
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}