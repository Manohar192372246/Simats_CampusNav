// ignore_for_file: deprecated_member_use, use_build_context_synchronously, prefer_final_fields, unused_field, no_leading_underscores_for_local_identifiers, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Ensure this is downloaded
import 'package:location/location.dart' as loc;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart';
import 'profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String searchQuery = "";
  String _userName = "";
  String _userEmail = "";
  String _userUid = "";
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  loc.Location _location = loc.Location();
  LatLng? _currentLocation;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  bool _isNavigating = false;
  String _navMode = "walk"; 
  Map<String, dynamic>? _selectedBuilding;
  File? _profileImage;
  
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = "";

  List<String> _navigationSteps = [];
  int _currentStepIndex = 0;
  bool _isFirstLocationReceived = false;
  
  final String googleApiKey = "AIzaSyDvnJx-QAjsjamV-s0hKdskaGWvEfZdtB4";

  final List<Map<String, dynamic>> buildings = [
    {"name": "Bala Murugan Temple", "icon": Icons.temple_hindu, "category": "General", "lat": 13.02310, "lng": 80.01632},
    {"name": "Saveetha Hospital", "icon": Icons.local_hospital, "category": "Medical", "lat": 13.02438, "lng": 80.01575},
    {"name": "Saveetha Medical College", "icon": Icons.school, "category": "Academic", "lat": 13.02456, "lng": 80.01753},
    {"name": "Car Parking Area", "icon": Icons.local_parking, "category": "Facility", "lat": 13.02306, "lng": 80.01574},
    {"name": "AHS Building", "icon": Icons.health_and_safety, "category": "Academic", "lat": 13.02540, "lng": 80.01725},
    {"name": "Canteens", "icon": Icons.restaurant, "category": "Facility", "lat": 13.02560, "lng": 80.01538},
    {"name": "Rectangular Building", "icon": Icons.apartment, "category": "Academic", "lat": 13.02665, "lng": 80.01521},
    {"name": "SCON building", "icon": Icons.medical_services, "category": "Medical", "lat": 13.02602, "lng": 80.01417},
    {"name": "Nalli Arangam", "icon": Icons.event, "category": "General", "lat": 13.02555, "lng": 80.01428},
    {"name": "SEC Building", "icon": Icons.domain, "category": "Academic", "lat": 13.02868, "lng": 80.01954},
    {"name": "Krishna Boys Hostel", "icon": Icons.hotel, "category": "Hostel", "lat": 13.03042, "lng": 80.01789},
    {"name": "Vaigai Girls Hostel", "icon": Icons.hotel, "category": "Hostel", "lat": 13.03039, "lng": 80.01672},
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _getUserLocation();
    _loadProfileData();
    _loadMarkers();
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
      _userName = prefs.getString('user_name') ?? "User";
      _userEmail = prefs.getString('user_email') ?? "";
      _userUid = prefs.getString('user_uid') ?? "";
    });
  }

  void _loadMarkers() {
    setState(() {
      _markers = buildings.map((b) => Marker(
        point: LatLng(b['lat'] as double, b['lng'] as double),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _navigateToBuilding(b),
          child: const Icon(Icons.location_on, color: Colors.red, size: 35),
        ),
      )).toList();
    });
  }

  void _getUserLocation() async {
    bool _serviceEnabled;
    loc.PermissionStatus _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) return;
    }

    _location.onLocationChanged.listen((loc.LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        LatLng newPos = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        
        if (mounted) {
          setState(() {
            _currentLocation = newPos;
            if (!_isFirstLocationReceived) {
              _isFirstLocationReceived = true;
              _mapController.move(_currentLocation!, 17);
            }
          });
        }
      }
    });

    // Initial location fetch to ensure it shows on Web
    try {
      final loc.LocationData _initialLoc = await _location.getLocation();
      if (_initialLoc.latitude != null && _initialLoc.longitude != null) {
        setState(() {
          _currentLocation = LatLng(_initialLoc.latitude!, _initialLoc.longitude!);
          _mapController.move(_currentLocation!, 17);
        });
      }
    } catch (e) {
      debugPrint("Initial location error: $e");
    }
  }

  void _navigateToBuilding(Map<String, dynamic> building, {String mode = "walk"}) async {
    LatLng destination = LatLng(building['lat'] as double, building['lng'] as double);
    
    setState(() {
      _selectedIndex = 1;
      _selectedBuilding = building;
      _navMode = mode;
      _isNavigating = true; // Navigation mode start
    });

    if (_currentLocation != null) {
      _fetchRoute(_currentLocation!, destination, mode);
      _mapController.move(destination, 17);
    } else {
      _mapController.move(destination, 17);
    }
  }

  void _fetchRoute(LatLng origin, LatLng destination, String mode) async {
    String googleMode = mode == "walk" ? "walking" : (mode == "bike" ? "bicycling" : "driving");
    // Web lo CORS issue valla Google API block avvachhu. 
    // Testing kosam direct lines or accurate routing logic.
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
            _polylines = [
              Polyline(
                points: coords,
                color: const Color(0xFF1A73E8),
                strokeWidth: 6, // Thick blue line like Google Maps
              )
            ];
          });
          
          // Fit the route in view
          if (coords.isNotEmpty) {
             _mapController.move(origin, 17);
          }
        }
      }
    } catch (e) {
      debugPrint("Route Error: $e");
    }
  }

  Widget _buildHomeBody() {
    final filteredBuildings = buildings.where((b) {
      return b['name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
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
                  Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu, color: Colors.white, size: 28), onPressed: () => Scaffold.of(context).openDrawer())),
                  IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white, size: 30), onPressed: () {}),
                ],
              ),
              const SizedBox(height: 10),
              Text("Hello, $_userName 👋", style: const TextStyle(color: Colors.white, fontSize: 18)),
              const Text("Welcome to SIMATS", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: const InputDecoration(hintText: "Search buildings...", border: InputBorder.none, icon: Icon(Icons.search)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredBuildings.length,
            itemBuilder: (context, index) {
              final b = filteredBuildings[index];
              return ListTile(
                leading: Icon(b['icon'] as IconData, color: const Color(0xFF0A4DDE)),
                title: Text(b['name'].toString()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _navigateToBuilding(b),
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
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(13.0290, 80.0180),
            initialZoom: 16.0,
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture && _isNavigating) {
                // Keep navigating but stop auto-following if user moves map
              }
            }
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.simats.campusnav',
            ),
            MarkerLayer(markers: [
              if (_currentLocation != null)
                Marker(
                  point: _currentLocation!,
                  width: 45,
                  height: 45,
                  child: const Icon(Icons.navigation, color: Colors.blue, size: 35), // Navigation arrow
                ),
              ..._markers
            ]),
            PolylineLayer(polylines: _polylines),
          ],
        ),
        
        // Navigation Instructions Header (Like Google Maps)
        if (_isNavigating && _navigationSteps.isNotEmpty)
          Positioned(
            top: 40, left: 15, right: 15,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF1E8E3E), // Google Maps Green
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions, color: Colors.white, size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      _navigationSteps[_currentStepIndex],
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() {
                      _isNavigating = false;
                      _polylines = [];
                      _navigationSteps = [];
                    }),
                  )
                ],
              ),
            ),
          ),

        if (!_isNavigating)
          Positioned(
            top: 50, left: 15, right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              height: 55,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: Row(children: [
                const Icon(Icons.search, color: Color(0xFF0A4DDE)),
                const SizedBox(width: 10),
                Expanded(child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: const InputDecoration(hintText: "Search here", border: InputBorder.none)
                )),
                IconButton(icon: Icon(_speechToText.isListening ? Icons.mic : Icons.mic_none), onPressed: _speechToText.isListening ? _stopListening : _startListening),
              ]),
            ),
          ),

        // Bottom Details Card
        if (_selectedBuilding != null)
          Positioned(
            bottom: 90, left: 15, right: 15,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF0A4DDE).withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(_selectedBuilding!['icon'] as IconData, color: const Color(0xFF0A4DDE)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedBuilding!['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(_selectedBuilding!['category'], style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A4DDE), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () {
                          if (!_isNavigating) {
                            _navigateToBuilding(_selectedBuilding!);
                          } else {
                            // Go to next step
                            setState(() {
                              if (_currentStepIndex < _navigationSteps.length - 1) {
                                _currentStepIndex++;
                              }
                            });
                          }
                        },
                        child: Text(_isNavigating ? "Next" : "Directions", style: const TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),

        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () {
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, 17);
              } else {
                _getUserLocation();
              }
            },
            child: const Icon(Icons.my_location, color: Color(0xFF0A4DDE)),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0A4DDE)),
            accountName: Text(_userName),
            accountEmail: Text(_userEmail),
          ),
          ListTile(leading: const Icon(Icons.home), title: const Text("Home"), onTap: () => setState(() => _selectedIndex = 0)),
          ListTile(leading: const Icon(Icons.explore), title: const Text("Map"), onTap: () => setState(() => _selectedIndex = 1)),
        ]),
      ),
      body: IndexedStack(
        index: _selectedIndex >= 3 ? 2 : _selectedIndex, 
        children: [ 
          _buildHomeBody(), 
          _buildMapBody(), 
          ProfileScreen(profileImage: _profileImage, onImageChange: () {}) 
        ]
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex >= 3 ? 2 : _selectedIndex, 
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [ 
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"), 
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"), 
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile") 
        ]
      ),
    );
  }
}
