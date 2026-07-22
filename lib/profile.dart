import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'profile_detail_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final File? profileImage;
  final VoidCallback onImageChange;

  const ProfileScreen({super.key, this.profileImage, required this.onImageChange});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('user_name') ?? "Student";
    });
  }

  void _showFullScreenImage(BuildContext context) {
    if (widget.profileImage == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.9),
              ),
            ),
            Hero(
              tag: 'profile_pic',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  widget.profileImage!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Stack(
          children: [
            GestureDetector(
              onTap: () => _showFullScreenImage(context),
              child: Hero(
                tag: 'profile_pic',
                child: CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF0A4DDE),
                    backgroundImage: widget.profileImage != null ? FileImage(widget.profileImage!) : null,
                    child: widget.profileImage == null ? const Icon(Icons.person, size: 70, color: Colors.white) : null),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: widget.onImageChange,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]
                  ),
                  child: const Icon(Icons.camera_alt, size: 20, color: Color(0xFF0A4DDE)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(_name,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B))),
        const SizedBox(height: 40),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _profileItem(context, Icons.person_outline, "Edit Profile", isEdit: true),
              _profileItem(context, Icons.favorite_outline, "My Favorites"),
              _profileItem(context, Icons.history, "Recent History"),
              _profileItem(context, Icons.notifications_none_rounded, "Push Notifications"),
              _profileItem(context, Icons.security, "Security & Privacy"),
              _profileItem(context, Icons.help_outline, "Help & Support"),
              _profileItem(context, Icons.info_outline, "About CampusNav"),
              const Divider(height: 40),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileItem(BuildContext context, IconData icon, String title, {bool isEdit = false}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0A4DDE)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () async {
        if (isEdit) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(
                profileImage: widget.profileImage,
                onImageChange: widget.onImageChange,
              ),
            ),
          );
          if (result == true) {
            _loadProfileData();
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileDetailScreen(title: title),
            ),
          );
        }
      },
    );
  }
}
