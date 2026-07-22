import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileDetailScreen extends StatefulWidget {
  final String title;

  const ProfileDetailScreen({super.key, required this.title});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  List<String> _history = [];
  bool _appNotif = true;
  bool _locUpdates = true;
  bool _eventAlerts = true;
  bool _biometric = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    if (widget.title == "Recent History") {
      _loadHistory();
    }
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appNotif = prefs.getBool('notif_app') ?? true;
      _locUpdates = prefs.getBool('notif_loc') ?? true;
      _eventAlerts = prefs.getBool('notif_event') ?? true;
      _biometric = prefs.getBool('sec_biometric') ?? false;
    });
  }

  void _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String uid = prefs.getString('user_uid') ?? "";
    String historyKey = uid.isEmpty ? 'search_history' : 'search_history_$uid';
    setState(() {
      _history = prefs.getStringList(historyKey) ?? [];
    });
  }

  void _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String uid = prefs.getString('user_uid') ?? "";
    String historyKey = uid.isEmpty ? 'search_history' : 'search_history_$uid';
    await prefs.remove(historyKey);
    setState(() {
      _history = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0A4DDE),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: widget.title == "Recent History" ? [
          IconButton(icon: const Icon(Icons.delete_sweep_outlined), onPressed: _clearHistory)
        ] : null,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (widget.title) {
      case "Recent History":
        return _historyView();
      case "Push Notifications":
        return _notificationsView();
      case "Security & Privacy":
        return _securityView();
      case "My Favorites":
        return _favoritesView();
      case "Help & Support":
        return _helpView();
      case "About CampusNav":
        return _aboutView();
      default:
        return Center(child: Text("${widget.title} content coming soon!"));
    }
  }

  Widget _historyView() {
    if (_history.isEmpty) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text("No search history yet", style: TextStyle(color: Colors.grey)),
        ],
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: const Icon(Icons.history, color: Color(0xFF0A4DDE)),
            title: Text(_history[index], style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.north_west, size: 16, color: Colors.grey),
            onTap: () {
              // You could trigger a search here by popping with result
              Navigator.pop(context, _history[index]);
            },
          ),
        );
      },
    );
  }

  Widget _notificationsView() {
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _switchItem("App Notifications", "Receive alerts about campus updates", _appNotif, (v) {
          setState(() => _appNotif = v);
          _saveSetting('notif_app', v);
        }),
        _switchItem("Location Updates", "Show navigation alerts and live position", _locUpdates, (v) {
          setState(() => _locUpdates = v);
          _saveSetting('notif_loc', v);
        }),
        _switchItem("Event Alerts", "Get notified about campus events and fests", _eventAlerts, (v) {
          setState(() => _eventAlerts = v);
          _saveSetting('notif_event', v);
        }),
      ],
    );
  }

  Widget _switchItem(String title, String sub, bool val, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        value: val,
        onChanged: onChanged,
        activeColor: const Color(0xFF0A4DDE),
      ),
    );
  }

  Widget _securityView() {
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _menuItem(Icons.lock_outline, "Change Password", "Update your account password", () {
          // Add change password logic
        }),
        _menuItem(Icons.fingerprint, "Biometric Login", "Use fingerprint or face ID to login", null, 
          trailing: Switch(value: _biometric, onChanged: (v) {
            setState(() => _biometric = v);
            _saveSetting('sec_biometric', v);
          }, activeColor: const Color(0xFF0A4DDE))),
        _menuItem(Icons.privacy_tip_outlined, "Privacy Policy", "Read our data protection terms", () {}),
        _menuItem(Icons.delete_forever_outlined, "Delete Account", "Permanently remove your data", () {}, color: Colors.red),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, String sub, VoidCallback? onTap, {Widget? trailing, Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: color ?? const Color(0xFF0A4DDE)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        subtitle: Text(sub),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }

  Widget _favoritesView() {
    final List<Map<String, dynamic>> favorites = [
      {"name": "Saveetha Hospital", "type": "Medical Center", "icon": Icons.local_hospital, "color": Colors.red},
      {"name": "Bala Murugan Temple", "type": "Religious Site", "icon": Icons.temple_hindu, "color": Colors.orange},
      {"name": "Canteens", "type": "Food Court", "icon": Icons.restaurant, "color": Colors.green},
      {"name": "CSE BLOCK", "type": "Academic Block", "icon": Icons.computer, "color": Colors.blue},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final fav = favorites[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: fav['color'].withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(fav['icon'], color: fav['color']),
            ),
            title: Text(fav['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(fav['type']),
            trailing: const Icon(Icons.favorite, color: Colors.red, size: 20),
            onTap: () {
              // Navigation logic could be added here
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Widget _helpView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.support_agent, size: 80, color: Color(0xFF0A4DDE)),
          SizedBox(height: 20),
          Text("Need Help?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text("Contact: support@simats.edu", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _aboutView() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        children: [
          Icon(Icons.navigation, size: 80, color: Color(0xFF0A4DDE)),
          SizedBox(height: 20),
          Text("CampusNav v1.0.0", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("Made for SIMATS University Students", textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
