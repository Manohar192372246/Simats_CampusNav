// ignore_for_file: deprecated_member_use, use_build_context_synchronously, prefer_final_fields, unused_field, no_leading_underscores_for_local_identifiers, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'about_screen.dart';
import 'building_detail_screen.dart';
import 'login_screen.dart';
import 'profile.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String searchQuery = "";
  String _userName = "Manohar";
  String _userEmail = "manohar@simats.edu";
  final TextEditingController _searchController = TextEditingController();
  late GoogleMapController mapController;
  Location _location = Location();
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  bool _isTracking = false;
  bool _isNavigating = false;
  String _navMode = "walk"; // 'walk' or 'drive'
  Map<String, dynamic>? _selectedBuilding;
  MapType _currentMapType = MapType.normal;
  File? _profileImage;
  
  // Voice search variables
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = "";

  // Navigation steps
  List<String> _navigationSteps = [];
  int _currentStepIndex = 0;
  
  // Replace with your API Key
  final String googleApiKey = "AIzaSyDvnJx-QAjsjamV-s0hKdskaGWvEfZdtB4";

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _getUserLocation();
    _loadProfileData();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: (result) {
      setState(() {
        _lastWords = result.recognizedWords;
        _searchController.text = _lastWords;
        searchQuery = _lastWords;
      });
    });
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    String? imagePath = prefs.getString('profile_image_path');
    setState(() {
      if (imagePath != null) {
        _profileImage = File(imagePath);
      }
      _userName = prefs.getString('user_name') ?? "Manohar";
      _userEmail = prefs.getString('user_email') ?? "manohar@simats.edu";
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      _cropImage(pickedFile.path);
    }
  }

  Future<void> _cropImage(String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust Photo',
          toolbarColor: const Color(0xFF0A4DDE),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
        IOSUiSettings(
          title: 'Adjust Photo',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
      ],
    );

    if (croppedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', croppedFile.path);
      setState(() {
        _profileImage = File(croppedFile.path);
      });
    }
  }

  void _removeImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_image_path');
    setState(() {
      _profileImage = null;
    });
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Text("Profile Photo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Color(0xFF0A4DDE)),
            title: const Text("Choose from Gallery"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Color(0xFF0A4DDE)),
            title: const Text("Take a Photo"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          if (_profileImage != null)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Remove Photo", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _removeImage();
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showDirectory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const Text("Department Directory", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(leading: Icon(Icons.computer), title: Text("Computer Science & Engineering")),
                  ListTile(leading: Icon(Icons.memory), title: Text("Electronics & Communication")),
                  ListTile(leading: Icon(Icons.medical_services), title: Text("Medical College")),
                  ListTile(leading: Icon(Icons.gavel), title: Text("Law College")),
                  ListTile(leading: Icon(Icons.business), title: Text("School of Management")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyContacts() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Emergency Contacts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.local_hospital, color: Colors.red),
              title: const Text("Campus Ambulance"),
              subtitle: const Text("+91 12345 67890"),
              onTap: () => launchUrl(Uri.parse("tel:+911234567890")),
            ),
            ListTile(
              leading: const Icon(Icons.security, color: Colors.blue),
              title: const Text("Campus Security"),
              subtitle: const Text("+91 09876 54321"),
              onTap: () => launchUrl(Uri.parse("tel:+910987654321")),
            ),
          ],
        ),
      ),
    );
  }

  void _getUserLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _currentLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          
          _circles = {
            Circle(
              circleId: const CircleId("current_loc"),
              center: _currentLocation!,
              radius: 12,
              fillColor: const Color(0xFF4285F4).withOpacity(0.2),
              strokeColor: const Color(0xFF4285F4),
              strokeWidth: 2,
            )
          };

          if (_isNavigating && _currentLocation != null) {
             mapController.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentLocation!, zoom: 19, tilt: 60, bearing: currentLocation.heading ?? 0)
            ));
          } else if (_isTracking) {
            mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
          }
        });
      }
    });
  }

  void _saveSearchHistory(String text) async {
    if (text.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('search_history') ?? [];
    // Remove if already exists to move to top
    history.remove(text);
    history.insert(0, text);
    // Keep only last 20
    if (history.length > 20) history = history.sublist(0, 20);
    await prefs.setStringList('search_history', history);
  }

  void _navigateToBuilding(Map<String, dynamic> building, {String mode = "walk"}) async {
    _saveSearchHistory(building['name']);
    setState(() {
      _selectedIndex = 1;
      _selectedBuilding = building;
      _navMode = mode;
    });

    LatLng destination = LatLng(building['lat'], building['lng']);
    
    _markers.clear();
    _markers.add(Marker(
      markerId: MarkerId(building['name']),
      position: destination,
      infoWindow: InfoWindow(title: building['name']),
    ));

    if (_currentLocation != null) {
      // Switching to Google Directions API for much better road-snapping and accuracy
      String googleMode = mode == "walk" ? "walking" : (mode == "bike" ? "bicycling" : "driving");
      final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentLocation!.latitude},${_currentLocation!.longitude}&destination=${destination.latitude},${destination.longitude}&mode=$googleMode&key=$googleApiKey';
      
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
            PolylinePoints polylinePoints = PolylinePoints();
            List<PointLatLng> result = polylinePoints.decodePolyline(encodedPolyline);
            
            List<LatLng> coords = result.map((p) => LatLng(p.latitude, p.longitude)).toList();

            // Extracting navigation instructions
            List<String> steps = [];
            final legs = data['routes'][0]['legs'];
            if (legs != null && legs.isNotEmpty) {
              for (var step in legs[0]['steps']) {
                String instruction = step['html_instructions'] ?? "";
                // Remove HTML tags using Regex
                instruction = instruction.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
                steps.add(instruction.trim());
              }
            }

            setState(() {
              _navigationSteps = steps;
              _currentStepIndex = 0;
              _polylines.clear();
              // Outer Border (Casing) - Makes it look thick and professional
              _polylines.add(Polyline(
                polylineId: const PolylineId("route_border"),
                points: coords,
                color: const Color(0xFF1565C0),
                width: mode == "walk" ? 12 : (mode == "bike" ? 22 : 25),
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                zIndex: 1,
              ));
              // Inner Line - Uses dots for walking to match Google Maps style
              _polylines.add(Polyline(
                polylineId: const PolylineId("route_main"),
                points: coords,
                color: const Color(0xFF1A73E8),
                width: mode == "walk" ? 8 : (mode == "bike" ? 14 : 16),
                patterns: mode == "walk" ? [PatternItem.dot, PatternItem.gap(15)] : [],
                jointType: JointType.round,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                zIndex: 2,
              ));
            });
          } else {
            // If Google API fails (e.g., key/billing), fallback to OSRM logic
            _fetchOSRMRoute(destination, mode);
          }
        }
      } catch (e) {
        debugPrint("Route Error: $e");
      }
      mapController.animateCamera(CameraUpdate.newLatLngZoom(destination, 16));
    }
  }

  // Fallback method using OSRM if Google API is unavailable
  void _fetchOSRMRoute(LatLng destination, String mode) async {
    String osrmMode = mode == "walk" ? "foot" : (mode == "bike" ? "bicycle" : "car");
    final url = 'https://router.project-osrm.org/route/v1/$osrmMode/${_currentLocation!.longitude},${_currentLocation!.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=polyline';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String encodedPolyline = data['routes'][0]['geometry'];
        PolylinePoints polylinePoints = PolylinePoints();
        List<PointLatLng> result = polylinePoints.decodePolyline(encodedPolyline);
        List<LatLng> coords = result.map((p) => LatLng(p.latitude, p.longitude)).toList();

        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: const PolylineId("route_main"),
            points: coords,
            color: const Color(0xFF1A73E8),
            width: mode == "walk" ? 10 : 18,
            patterns: mode == "walk" ? [PatternItem.dot, PatternItem.gap(12)] : [],
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ));
        });
      }
    } catch (e) {
      debugPrint("OSRM Fallback Error: $e");
    }
  }

  final List<Map<String, dynamic>> buildings = [
    {"name": "Bala Murugan Temple", "icon": Icons.temple_hindu, "category": "General", "lat": 13.02310, "lng": 80.01632},
    {"name": "Saveetha Hospital", "icon": Icons.local_hospital, "category": "Medical", "lat": 13.02438, "lng": 80.01575},
    {"name": "Saveetha Medical College", "icon": Icons.school, "category": "Academic", "lat": 13.02456, "lng": 80.01753},
    {"name": "Car Parking Area", "icon": Icons.local_parking, "category": "Facility", "lat": 13.02306, "lng": 80.01574},
    {"name": "AHS Building", "icon": Icons.health_and_safety, "category": "Academic", "lat": 13.02540, "lng": 80.01725},
    {
      "name": "Round Building",
      "icon": Icons.loop,
      "category": "Academic",
      "lat": 13.02624, "lng": 80.01709,
      "blocks": [
        {"name": "SAIL", "icon": Icons.psychology, "lat": 13.02624, "lng": 80.01709},
        {"name": "CSE BLOCK", "icon": Icons.computer, "lat": 13.02606, "lng": 80.01689},
        {"name": "ADMIN BLOCK", "icon": Icons.admin_panel_settings, "lat": 13.02599, "lng": 80.01646},
        {"name": "ECE BLOCK", "icon": Icons.memory, "lat": 13.02616, "lng": 80.01603},
        {"name": "EEE BLOCK", "icon": Icons.electric_bolt, "lat": 13.02655, "lng": 80.01587},
      ]
    },
    {"name": "Canteens", "icon": Icons.restaurant, "category": "Facility", "lat": 13.02560, "lng": 80.01538},
    {"name": "Rectangular Building", "icon": Icons.apartment, "category": "Academic", "lat": 13.02665, "lng": 80.01521},
    {"name": "SCON building", "icon": Icons.medical_services, "category": "Medical", "lat": 13.02602, "lng": 80.01417},
    {"name": "Nalli Arangam", "icon": Icons.event, "category": "General", "lat": 13.02555, "lng": 80.01428},
    {"name": "SCAD Buildings", "icon": Icons.architecture, "category": "Academic", "lat": 13.02808, "lng": 80.01538},
    {"name": "SEC Building", "icon": Icons.domain, "category": "Academic", "lat": 13.02868, "lng": 80.01954},
    {"name": "Krishna Boys Hostel", "icon": Icons.hotel, "category": "Hostel", "lat": 13.03042, "lng": 80.01789},
    {"name": "Vaigai Girls Hostel", "icon": Icons.hotel, "category": "Hostel", "lat": 13.03039, "lng": 80.01672},
    {"name": "SSPE Building", "icon": Icons.sports_gymnastics, "category": "Academic", "lat": 13.03036, "lng": 80.01753},
    {"name": "Ground", "icon": Icons.sports_soccer, "category": "General", "lat": 13.03069, "lng": 80.01433},
  ];

  Widget _buildHomeBody() {
    final filteredBuildings = buildings.where((b) {
      bool matchesSearch = b['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          (b['blocks'] != null && (b['blocks'] as List).any((block) => block['name'].toLowerCase().contains(searchQuery.toLowerCase())));
      return matchesSearch;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 40, left: 15, right: 15, bottom: 25),
          decoration: const BoxDecoration(
            color: Color(0xFF0A4DDE),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.menu, color: Colors.white, size: 28), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 35),
                      onPressed: _showNotifications
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hello, $_userName 👋", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    Text("Welcome to SIMATS", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                    Text("Navigate Your Campus Easily", style: TextStyle(color: Colors.white70, fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF0A4DDE)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => searchQuery = value),
                        decoration: const InputDecoration(
                          hintText: "Search buildings, departments...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 25, vertical: 5),
          child: Row(children: [Text("Explore Campus", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: filteredBuildings.length,
            itemBuilder: (context, index) {
              final building = filteredBuildings[index];
              bool hasBlocks = building['blocks'] != null;
              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))]),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(width: 55, height: 55, decoration: BoxDecoration(color: const Color(0xFF0A4DDE).withOpacity(0.08), borderRadius: BorderRadius.circular(18)), child: Icon(building['icon'], color: const Color(0xFF0A4DDE), size: 28)),
                  title: Text(building['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () async {
                    if (hasBlocks) {
                      final selectedBlock = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => BuildingDetailScreen(buildingName: building['name'], blocks: List<Map<String, dynamic>>.from(building['blocks']))));
                      if (selectedBlock != null) _navigateToBuilding(selectedBlock);
                    } else {
                      _navigateToBuilding(building);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMapBody() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(target: LatLng(13.0290, 80.0180), zoom: 16.0),
          onMapCreated: (c) => mapController = c,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: _markers,
          polylines: _polylines,
          circles: _circles,
          mapType: _currentMapType,
        ),

        // TOP NAVIGATION BAR (Simulated Google Maps)
        if (_isNavigating)
          Positioned(
            top: 50, left: 15, right: 15,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: const Color(0xFF0F9D58), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
              child: Row(
                children: [
                  Icon(
                    _navigationSteps.isNotEmpty && _navigationSteps[_currentStepIndex].toLowerCase().contains("left") ? Icons.turn_left :
                    _navigationSteps.isNotEmpty && _navigationSteps[_currentStepIndex].toLowerCase().contains("right") ? Icons.turn_right :
                    Icons.navigation, 
                    color: Colors.white, size: 30
                  ),
                  const SizedBox(width: 15),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _navigationSteps.isNotEmpty ? _navigationSteps[_currentStepIndex] : "Heading to destination", 
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                      if (_navigationSteps.length > _currentStepIndex + 1)
                        Text(
                          "Next: ${_navigationSteps[_currentStepIndex + 1]}", 
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  )),
                  if (_navigationSteps.length > 1)
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white), 
                      onPressed: () {
                        setState(() {
                          if (_currentStepIndex < _navigationSteps.length - 1) _currentStepIndex++;
                        });
                      }
                    ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() { _isNavigating = false; _navigationSteps = []; }))
                ],
              ),
            ),
          )
        else
          Positioned(
            top: 50, left: 15, right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              height: 55,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: Row(children: [
                Stack(alignment: Alignment.center, children: [
                  ShaderMask(shaderCallback: (b) => const SweepGradient(colors: [Color(0xFF4285F4), Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853), Color(0xFF4285F4)]).createShader(b), child: const Icon(Icons.location_on, color: Colors.white, size: 32)),
                  Positioned(top: 6, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
                ]),
                const SizedBox(width: 10),
                Expanded(child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: const InputDecoration(hintText: "Search here", border: InputBorder.none)
                )),
                GestureDetector(
                  onTapDown: (_) => _startListening(),
                  onTapCancel: () => _stopListening(),
                  onTapUp: (_) => _stopListening(),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      _speechToText.isListening ? Icons.mic : Icons.mic_none_rounded, 
                      color: _speechToText.isListening ? Colors.red : const Color(0xFF0A4DDE)
                    ),
                  ),
                ),
              ]),
            ),
          ),

        // MODE SELECTOR & START BUTTON (Bottom)
        if (_selectedBuilding != null && !_isNavigating)
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedBuilding!['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _modeBtn(Icons.directions_walk, "Walk", "walk"),
                      _modeBtn(Icons.directions_bike, "Bike", "bike"),
                      _modeBtn(Icons.directions_car, "Drive", "drive"),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4285F4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                    onPressed: () => setState(() => _isNavigating = true),
                    child: const Text("START", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ))
                ],
              ),
            ),
          ),

        // MAP CONTROLS
        Positioned(top: 115, right: 20, child: _mapControlButton(Icons.layers_outlined, () => _showMapTypeSelector())),
        Positioned(bottom: _selectedBuilding != null ? 180 : 25, right: 20, child: Column(children: [
          _mapControlButton(Icons.explore, () {
            // Compass/Direction logic - reset bearing
            if (_currentLocation != null) {
              mapController.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(target: _currentLocation!, zoom: 17, bearing: 0, tilt: 0)
              ));
            }
          }),
          const SizedBox(height: 12),
          _mapControlButton(Icons.add, () => mapController.animateCamera(CameraUpdate.zoomIn())),
          const SizedBox(height: 12),
          _mapControlButton(Icons.remove, () => mapController.animateCamera(CameraUpdate.zoomOut())),
          const SizedBox(height: 12),
          Container(height: 56, width: 56, decoration: BoxDecoration(color: const Color(0xFF0A4DDE), shape: BoxShape.circle), child: IconButton(onPressed: () { if (_currentLocation != null) mapController.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 17)); }, icon: const Icon(Icons.my_location, color: Colors.white))),
        ])),
      ],
    );
  }

  Widget _modeBtn(IconData icon, String label, String mode) {
    bool isSel = _navMode == mode;
    return GestureDetector(
      onTap: () => _navigateToBuilding(_selectedBuilding!, mode: mode),
      child: Column(children: [
        Icon(icon, color: isSel ? const Color(0xFF4285F4) : Colors.grey),
        Text(label, style: TextStyle(color: isSel ? const Color(0xFF4285F4) : Colors.grey, fontWeight: isSel ? FontWeight.bold : FontWeight.normal))
      ]),
    );
  }

  Widget _mapControlButton(IconData icon, VoidCallback onTap) {
    return Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]), child: IconButton(icon: Icon(icon, color: const Color(0xFF0A4DDE)), onPressed: onTap));
  }

  void _showMapTypeSelector() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Map Type", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _mapTypeOption("Default", MapType.normal, Icons.map_outlined),
        _mapTypeOption("Satellite", MapType.satellite, Icons.satellite_alt_outlined),
        _mapTypeOption("Terrain", MapType.terrain, Icons.terrain_outlined),
      ]),
      const SizedBox(height: 20),
    ])));
  }

  Widget _mapTypeOption(String label, MapType type, IconData icon) {
    bool isSelected = _currentMapType == type;
    return GestureDetector(onTap: () { setState(() => _currentMapType = type); Navigator.pop(context); }, child: Column(children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isSelected ? const Color(0xFF0A4DDE).withOpacity(0.1) : Colors.grey.shade100, borderRadius: BorderRadius.circular(15), border: Border.all(color: isSelected ? const Color(0xFF0A4DDE) : Colors.transparent, width: 2)), child: Icon(icon, color: isSelected ? const Color(0xFF0A4DDE) : Colors.grey, size: 30)),
      const SizedBox(height: 8),
      Text(label, style: TextStyle(color: isSelected ? const Color(0xFF0A4DDE) : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
    ]));
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showNotifications() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }

  void _showFullScreenImage() {
    if (_profileImage == null) return;

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
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                _profileImage!,
                fit: BoxFit.contain,
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
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() { _selectedIndex = 0; _isTracking = false; _isNavigating = false; _selectedBuilding = null; });
      },
      child: Scaffold(
        key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4FD),
      drawer: Drawer(
        child: Column(children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0A4DDE)),
            currentAccountPicture: Stack(children: [
              GestureDetector(
                onTap: _showFullScreenImage,
                child: CircleAvatar(radius: 45, backgroundColor: Colors.white, backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null, child: _profileImage == null ? const Icon(Icons.person, size: 45, color: Color(0xFF0A4DDE)) : null),
              ),
              Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: _showImageOptions, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.add_a_photo, size: 20, color: Color(0xFF0A4DDE))))),
            ]),
            accountName: Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text(_userEmail),
          ),
          _drawerItem(Icons.home_outlined, "Home", 0),
          _drawerItem(Icons.explore_outlined, "Campus Map", 1),
          _drawerItem(Icons.list_alt_outlined, "Department Directory", -1, onTap: _showDirectory),
          _drawerItem(Icons.phone_in_talk_outlined, "Emergency Contacts", -1, onTap: _showEmergencyContacts),
          const Divider(),
          _drawerItem(Icons.settings_outlined, "Settings", 2),
          _drawerItem(Icons.share_outlined, "Share App", -1, onTap: () { Share.share('Download SIMATS Campus Navigator App to easily explore our campus!'); }),
          _drawerItem(Icons.info_outline, "About SIMATS", -1, onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())); }),
          const Spacer(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), onTap: () async { final prefs = await SharedPreferences.getInstance(); await prefs.setBool('is_logged_in', false); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginScreen()), (route) => false); }),
          const SizedBox(height: 20),
        ]),
      ),
      body: IndexedStack(
        index: _selectedIndex >= 3 ? 2 : _selectedIndex, 
        children: [ 
          _buildHomeBody(), 
          _buildMapBody(), 
          ProfileScreen(profileImage: _profileImage, onImageChange: _showImageOptions) 
        ]
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex >= 3 ? 2 : _selectedIndex, 
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 0) _loadProfileData();
        },
        selectedItemColor: const Color(0xFF0A4DDE), 
        unselectedItemColor: Colors.grey, 
        showUnselectedLabels: true, 
        type: BottomNavigationBarType.fixed, 
        items: const [ 
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"), 
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"), 
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile") 
        ]
      ),
    ));
  }

  Widget _drawerItem(IconData icon, String title, int index, {VoidCallback? onTap}) {
    return ListTile(leading: Icon(icon, color: const Color(0xFF0A4DDE)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)), onTap: () { Navigator.pop(context); if (onTap != null) { onTap(); } else if (index != -1) { setState(() => _selectedIndex = index); } });
  }
}
