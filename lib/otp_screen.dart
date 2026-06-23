import 'package:flutter/material.dart';
import 'reset_password_screen.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.all(24),

          child: Column(
            children: [

              const SizedBox(height: 40),

              Container(
                height: 170,
                width: 170,

                decoration:
                const BoxDecoration(
                  color:
                  Color(0xFFEAF2FF),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.security,
                  size: 90,
                  color:
                  Color(0xFF0A4DDE),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Verify OTP",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Enter the 6-digit OTP sent to your email",
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 35),

              Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .spaceEvenly,

                children: List.generate(
                  6,
                      (index) => SizedBox(
                    width: 45,
                    child: TextField(
                      textAlign:
                      TextAlign.center,
                      keyboardType:
                      TextInputType.number,
                      maxLength: 1,

                      decoration:
                      const InputDecoration(
                        counterText: "",
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Resend OTP in 00:30",
                style: TextStyle(
                  color: Colors.grey,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const ResetPasswordScreen(),
                      ),
                    );
                  },

                  child: const Text(
                    "Verify OTP",
                    style: TextStyle(
                      color:
                      Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}