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
  bool _isFirstLocationReceived = false;
  bool _isNavigatingRealTime = false;
  
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

    await _location.changeSettings(
      accuracy: LocationAccuracy.navigation,
      interval: 1000, 
      distanceFilter: 2
    );

    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        LatLng newPos = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        
        setState(() {
          _currentLocation = newPos;
          _circles = {
            Circle(
              circleId: const CircleId("current_loc"),
              center: _currentLocation!,
              radius: 8,
              fillColor: const Color(0xFF4285F4).withOpacity(0.3),
              strokeColor: Colors.white,
              strokeWidth: 2,
            )
          };

          if (!_isFirstLocationReceived) {
            _isFirstLocationReceived = true;
            mapController.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 17));
          }

          if (_isNavigating) {
            mapController.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentLocation!,
                zoom: 19,
                tilt: 60,
                bearing: currentLocation.heading ?? 0,
              )
            ));
          }
        });
      }
    });
  }

  void _checkNavigationProgress(LatLng currentPos) {
    // Basic logic to move to next instruction if we are within 10 meters of current step 
    // This can be enhanced further with polyline point checking
    if (_navigationSteps.length > _currentStepIndex + 1) {
       // Just a simple simulated step forward for demo, 
       // in real world we compare distance to next polyline coordinate
    }
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
    
    LatLng destination = LatLng(building['lat'], building['lng']);
    
    setState(() {
      _selectedIndex = 1;
      _selectedBuilding = building;
      _navMode = mode;
      _polylines.clear(); // Clear previous route
      _markers.clear();
      _markers.add(Marker(
        markerId: MarkerId(building['name']),
        position: destination,
        infoWindow: InfoWindow(title: building['name']),
      ));
    });

    // Try to get the latest position immediately
    try {
      var locData = await _location.getLocation();
      if (locData.latitude != null && locData.longitude != null) {
        _currentLocation = LatLng(locData.latitude!, locData.longitude!);
      }
    } catch (e) {
      debugPrint("Error getting initial location: $e");
    }

    if (_currentLocation != null) {
      _fetchRoute(_currentLocation!, destination, mode);
      
      // Zoom map to show both user and destination
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          _currentLocation!.latitude < destination.latitude ? _currentLocation!.latitude : destination.latitude,
          _currentLocation!.longitude < destination.longitude ? _currentLocation!.longitude : destination.longitude,
        ),
        northeast: LatLng(
          _currentLocation!.latitude > destination.latitude ? _currentLocation!.latitude : destination.latitude,
          _currentLocation!.longitude > destination.longitude ? _currentLocation!.longitude : destination.longitude,
        ),
      );
      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    } else {
      mapController.animateCamera(CameraUpdate.newLatLngZoom(destination, 16));
    }
  }

  void _fetchRoute(LatLng origin, LatLng destination, String mode) async {
    String googleMode = mode == "walk" ? "walking" : (mode == "bike" ? "bicycling" : "driving");
    final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=$googleMode&key=$googleApiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
          PolylinePoints polylinePoints = PolylinePoints();
          List<PointLatLng> result = polylinePoints.decodePolyline(encodedPolyline);
          List<LatLng> coords = result.map((p) => LatLng(p.latitude, p.longitude)).toList();

          List<String> steps = [];
          final legs = data['routes'][0]['legs'];
          if (legs != null && legs.isNotEmpty) {
            for (var step in legs[0]['steps']) {
              String instruction = step['html_instructions'] ?? "";
              instruction = instruction.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
              steps.add(instruction.trim());
            }
          }

          setState(() {
            _navigationSteps = steps;
            _currentStepIndex = 0;
            _polylines.clear();
            _polylines.add(Polyline(
              polylineId: const PolylineId("route_main"),
              points: coords,
              color: const Color(0xFF1A73E8),
              width: 6,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ));
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Google Route Error: $e");
    }
    
    // Fallback to OSRM if Google Fails
    _fetchOSRMRoute(destination, mode);
  }

  void _fetchOSRMRoute(LatLng destination, String mode) async {
    if (_currentLocation == null) return;
    
    String osrmMode = mode == "walk" ? "foot" : (mode == "bike" ? "bicycle" : "car");
    final url = 'https://router.project-osrm.org/route/v1/$osrmMode/${_currentLocation!.longitude},${_currentLocation!.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=polyline';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
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
              width: 6,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ));
          });
        }
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
    final filteredSuggestions = searchQuery.isEmpty ? [] : buildings.where((b) {
      return b['name'].toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(target: LatLng(13.0290, 80.0180), zoom: 16.0),
          onMapCreated: (c) => mapController = c,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          trafficEnabled: _showTraffic,
          markers: _markers,
          polylines: _polylines,
          circles: _circles,
          mapType: _currentMapType,
        ),

        // TOP SEARCH BAR & SUGGESTIONS
        if (!_isNavigating)
          Positioned(
            top: 50, left: 15, right: 15,
            child: Column(
              children: [
                Container(
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
                    if (searchQuery.isNotEmpty)
                      IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { searchQuery = ""; _searchController.clear(); })),
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
                if (filteredSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                    constraints: BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: filteredSuggestions.length,
                      itemBuilder: (context, index) {
                        final b = filteredSuggestions[index];
                        return ListTile(
                          leading: Icon(b['icon'], color: Color(0xFF1A73E8)),
                          title: Text(b['name']),
                          onTap: () {
                            setState(() {
                              searchQuery = "";
                              _searchController.clear();
                            });
                            _navigateToBuilding(b);
                          },
                        );
                      },
                    ),
                  )
              ],
            ),
          )
        else
          // TOP NAVIGATION BAR (Existing)
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
    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.transparent, 
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25), 
        decoration: const BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))
        ), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Map type", style: TextStyle(fontSize: 18, color: Colors.black87)),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.start, 
              children: [
                _mapTypeOption("Default", MapType.normal, "assets/images/map_default.png"),
                const SizedBox(width: 20),
                _mapTypeOption("Satellite", MapType.satellite, "assets/images/map_satellite.png"),
                const SizedBox(width: 20),
                _mapTypeOption("Terrain", MapType.terrain, "assets/images/map_terrain.png"),
              ],
            ),
            const SizedBox(height: 25),
            const Text("Map details", style: TextStyle(fontSize: 18, color: Colors.black87)),
            const SizedBox(height: 15),
            Row(
              children: [
                _mapDetailOption("Traffic", Icons.traffic_outlined),
              ],
            ),
            const SizedBox(height: 20),
          ]
        )
      )
    );
  }

  Widget _mapTypeOption(String label, MapType type, String assetPath) {
    bool isSelected = _currentMapType == type;
    IconData fallbackIcon = type == MapType.satellite ? Icons.satellite_alt : (type == MapType.terrain ? Icons.terrain : Icons.map);
    
    return GestureDetector(
      onTap: () { 
        setState(() => _currentMapType = type); 
      }, 
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF1A73E8) : Colors.grey.shade300, 
                width: isSelected ? 3 : 1
              ),
              image: DecorationImage(
                image: AssetImage(assetPath),
                fit: BoxFit.cover,
                onError: (e, s) => {}, 
              ),
              color: Colors.grey.shade100,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Show icon if image fails or just as part of design
                if (isSelected) Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF1A73E8).withOpacity(0.1),
                  ),
                ),
                Icon(fallbackIcon, color: isSelected ? const Color(0xFF1A73E8) : Colors.black26, size: 24),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFF1A73E8) : Colors.black54, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
            )
          ),
        ],
      )
    );
  }

  bool _showTraffic = false;
  Widget _mapDetailOption(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() => _showTraffic = !_showTraffic);
      },
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: _showTraffic ? const Color(0xFF1A73E8).withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showTraffic ? const Color(0xFF1A73E8) : Colors.transparent,
                width: 3
              ),
            ),
            child: Icon(icon, color: _showTraffic ? const Color(0xFF1A73E8) : Colors.black54, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: TextStyle(
              fontSize: 12,
              color: _showTraffic ? const Color(0xFF1A73E8) : Colors.black54,
              fontWeight: _showTraffic ? FontWeight.bold : FontWeight.normal
            )
          ),
        ],
      ),
    );
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
