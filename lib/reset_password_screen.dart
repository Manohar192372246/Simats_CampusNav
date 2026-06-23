import 'package:flutter/material.dart';

class ResetPasswordScreen
    extends StatefulWidget {
  const ResetPasswordScreen(
      {super.key});

  @override
  State<ResetPasswordScreen>
  createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<
        ResetPasswordScreen> {

  bool obscure1 = true;
  bool obscure2 = true;

  final newPasswordController =
  TextEditingController();

  final confirmPasswordController =
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
                  Icons.password,
                  size: 100,
                  color:
                  Color(0xFF0A4DDE),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Reset Password",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Create a new password for your account",
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller:
                newPasswordController,

                obscureText:
                obscure1,

                decoration:
                InputDecoration(
                  hintText:
                  "New Password",

                  prefixIcon:
                  const Icon(
                      Icons.lock),

                  suffixIcon:
                  IconButton(
                    icon: Icon(
                      obscure1
                          ? Icons
                          .visibility_off
                          : Icons
                          .visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscure1 =
                        !obscure1;
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

              const SizedBox(height: 20),

              TextField(
                controller:
                confirmPasswordController,

                obscureText:
                obscure2,

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
                      obscure2
                          ? Icons
                          .visibility_off
                          : Icons
                          .visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscure2 =
                        !obscure2;
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
                    ScaffoldMessenger.of(
                        context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Password Reset Successfully",
                        ),
                      ),
                    );

                    Navigator.popUntil(
                      context,
                          (route) =>
                      route.isFirst,
                    );
                  },

                  child: const Text(
                    "Reset Password",
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