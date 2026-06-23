import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FD),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF0A4DDE),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          _notificationCard(
            context,
            "Campus Event Today",
            "Annual Tech Fest starts at 10:00 AM in Nalli Arangam. Don't miss out on the innovation showcase!",
            "Now",
            Icons.campaign,
            Colors.blue,
          ),
          _notificationCard(
            context,
            "Library Timing Change",
            "The central library will be open until 10:00 PM this week for the upcoming exams.",
            "2h ago",
            Icons.info,
            Colors.orange,
          ),
          _notificationCard(
            context,
            "New Result Uploaded",
            "Semester results for CSE 3rd Year have been uploaded to the portal.",
            "5h ago",
            Icons.school,
            Colors.green,
          ),
          _notificationCard(
            context,
            "Holiday Notice",
            "Campus will remain closed on Friday for the local festival.",
            "Yesterday",
            Icons.event,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(BuildContext context, String title, String sub, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(sub, style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
