// lib/controller/driver/driver_active_ride_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:tariqi/const/class/request_state.dart';
import 'package:tariqi/services/driver_service.dart';
import 'package:tariqi/const/api_endpoints.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:tariqi/controller/auth_controllers/auth_controller.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:tariqi/models/chat_message.dart';
import 'package:tariqi/services/driver_service.dart';
import 'package:tariqi/controller/auth_controllers/auth_controller.dart';

// Global variable to hold route data
RxList<dynamic> routes = <dynamic>[].obs;

class DriverActiveRideController extends GetxController {
  // Initialize with a safeguard mechanism
  late final DriverService _driverService;
  final Rx<RequestState> requestState = RequestState.loading.obs;
  final RxList<Map<String, dynamic>> passengers = <Map<String, dynamic>>[].obs;
  final RxBool hasPendingRequest = false.obs;
  final RxMap<String, dynamic> pendingRequest = <String, dynamic>{}.obs;
  
  // Location permission status
  final RxBool locationPermissionGranted = false.obs;

  // Sound player
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Ride info
  late String destination = "";
  late int etaMinutes = 0;
  late double distanceKm = 0.0;
  late LatLng currentLocation = LatLng(0.0, 0.0);
  late LatLng destinationLocation = LatLng(0.0, 0.0);
  String? rideId;

  // Map controllers
  late MapController mapController;
  final List<Marker> markers = [];
  final List<Polyline> routePolyline = [];

  // Periodic timers for updates
  Timer? _locationUpdateTimer;
  Timer? _rideStatusTimer;
  Timer? _pendingRequestsTimer;

  // OpenRouteService API key
  final String openRouteServiceApiKey = "5b3ce3597851110001cf6248bb9ac1f42e9a4c27a6e95c89f7c3985f";

  @override
  void onInit() {
    super.onInit();
    
    // Initialize with default values first to prevent null errors 
    currentLocation = LatLng(24.7136, 46.6753); // Default to Riyadh
    destinationLocation = LatLng(24.7236, 46.6953);
    
    // Initialize map controller
    mapController = MapController();
    
    // Add default markers
    markers.clear();
    markers.addAll([
      Marker(
        point: currentLocation,
        width: 100,
        height: 100,
        child: Image.asset('assets/images/car.png', width: 100, height: 100),
      ),
      Marker(
        point: destinationLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_pin, color: Colors.blue, size: 40),
      ),
    ]);
    
    // Add default route
    routePolyline.clear();
    routePolyline.add(Polyline(
      points: [currentLocation, destinationLocation],
      color: Colors.blue,
      strokeWidth: 4,
    ));
    
    // Set loading state
    requestState.value = RequestState.loading;
    
    // Try to find DriverService or create it if not found
    try {
      _driverService = Get.find<DriverService>();
      dev.log("✅ Found existing DriverService instance");
    } catch (e) {
      dev.log("⚠️ DriverService not found, creating new instance");
      _driverService = Get.put(DriverService());
    }
    
    // Check location permissions first
    _checkLocationPermission();
    
    // Get the current ride ID from the DriverService
    rideId = _driverService.currentRideId;
    dev.log("🚗 Active Ride Controller - Current ride ID: $rideId");
    
    // Initial data loading will be triggered after location permission check
  }

  // Add this method to check location permission
  Future<void> _checkLocationPermission() async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        dev.log("📍 Location services are disabled");
        locationPermissionGranted.value = false;
        
        // Even without location, we should still try to load ride data
        loadRideData();
        return;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        dev.log("📍 Location permission is denied, requesting permission...");
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        dev.log("📍 Location permission is denied");
        locationPermissionGranted.value = false;
        
        // Even without location, we should still try to load ride data
        loadRideData();
        return;
      }
      
      // Permission granted, start location services
      locationPermissionGranted.value = true;
      dev.log("📍 Location permission granted, starting services");
      
      // Set up periodic updates once permission is granted
      _startPeriodicUpdates();
      
      // Load ride data
      loadRideData();
      
    } catch (e) {
      dev.log("❌ Error checking location permission: $e");
      locationPermissionGranted.value = false;
      
      // Even on error, still try to load ride data
      loadRideData();
    }
  }
  
  // Method to request location permission
  Future<void> requestLocationPermission() async {
    try {
      // First check if location services are enabled on the device
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        _showLocationServiceDisabledError();
        return;
      }
      
      LocationPermission permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        dev.log("📍 Location permission request was denied");
        locationPermissionGranted.value = false;
        _showLocationPermissionError();
        return;
      }
      
      // Permission granted, start location services
      locationPermissionGranted.value = true;
      dev.log("📍 Location permission was granted");
      
      // Start periodic updates
      _startPeriodicUpdates();
      
      // Reload ride data
      loadRideData();
      
      // Remove any error messages
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
      
    } catch (e) {
      dev.log("❌ Error requesting location permission: $e");
      
      // Special handling for Windows
      if (e.toString().contains("Location settings are not satisfied") || 
          e.toString().contains("location permission")) {
        _showWindowsLocationInstructions();
      } else {
        _showLocationPermissionError();
      }
    }
  }
  
  // Show Windows-specific location instructions
  void _showWindowsLocationInstructions() {
    Get.dialog(
      AlertDialog(
        title: Text('Windows Location Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To enable location on Windows:'),
            SizedBox(height: 8),
            Text('1. Open Windows Settings'),
            Text('2. Go to Privacy & Security'),
            Text('3. Select Location'),
            Text('4. Turn on "Location service"'),
            Text('5. Under App permissions, enable location access for apps'),
            SizedBox(height: 16),
            Text('After enabling location, restart the application.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              useFallbackLocation();
            },
            child: Text('Use Default Location'),
          ),
        ],
      ),
    );
  }
  
  // Show location services disabled error
  void _showLocationServiceDisabledError() {
    Get.dialog(
      AlertDialog(
        title: Text('Location Services Disabled'),
        content: Text('Location services are disabled on your device. Please enable location services in your system settings.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              useFallbackLocation();
            },
            child: Text('Use Default Location'),
          ),
        ],
      ),
    );
  }
  
  // Use fallback location when permissions are not available
  void useFallbackLocation() {
    dev.log("📍 Using fallback location data for Windows");
    
    // Set a default location (can be configured for your specific app needs)
    currentLocation = LatLng(24.7136, 46.6753); // Default to Riyadh
    
    // Use fallback location but still start the ride
    locationPermissionGranted.value = true;
    
    // Create a simulated route and start ride
    _createFallbackRoute();
    
    // Start periodic updates, but they'll use fallback data
    _startPeriodicUpdates();
    
    // Update UI
    update();
  }
  
  // Show location permission error message
  void _showLocationPermissionError() {
    Get.snackbar(
      'Error',
      'Failed to get location: Exception: Location permissions are denied. Please enable in settings.',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () => requestLocationPermission(),
        child: Text('Enable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    // Cancel all timers when controller is closed
    _locationUpdateTimer?.cancel();
    _rideStatusTimer?.cancel();
    _pendingRequestsTimer?.cancel();
    super.onClose();
  }

  void _startPeriodicUpdates() {
    // Cancel any existing timers first
    _locationUpdateTimer?.cancel();
    _rideStatusTimer?.cancel();
    _pendingRequestsTimer?.cancel();
    
    // Update driver location every 10 seconds
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 10), 
      (_) => updateDriverLocation()
    );
    
    // Fetch ride status every 15 seconds
    _rideStatusTimer = Timer.periodic(
      const Duration(seconds: 15), 
      (_) => refreshRideStatus()
    );
    
    // Check for pending requests every 20 seconds
    _pendingRequestsTimer = Timer.periodic(
      const Duration(seconds: 20), 
      (_) => fetchPendingRequests()
    );
  }

  Future<void> loadRideData() async {
    if (rideId == null || rideId!.isEmpty) {
      dev.log("❌ Cannot load ride data: No ride ID available");
      
      // Check if we can get an active ride ID from the service
      final driverService = Get.find<DriverService>();
      final hasActiveRide = await driverService.hasActiveRide();
      
      if (hasActiveRide && driverService.currentRideId != null) {
        rideId = driverService.currentRideId;
        dev.log("✅ Found active ride ID from service: $rideId");
      } else {
        requestState.value = RequestState.failed;
        Get.snackbar(
          "No Ride Found", 
          "Could not find an active ride to display",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 3)
        );
        return;
      }
    }
    
    try {
      requestState.value = RequestState.loading;
      dev.log("🔄 Loading ride data for ride ID: $rideId");
      
      // First try to get ride data via the DriverService
      final rideData = await _driverService.getRideData(rideId!);
      
      if (rideData != null) {
        dev.log("✅ Successfully loaded ride data");
        
        // Process route data
        if (rideData.containsKey('route') && rideData['route'] is List) {
          routes.clear();
          routes.addAll(rideData['route']);
          dev.log("✅ Successfully extracted route data");
          initializeRideFromRoute();
        } else {
          dev.log("⚠️ No route data in response, using fallback");
          await _createFallbackRoute();
        }
        
        // Load passengers
        if (rideData.containsKey('passengers') && rideData['passengers'] is List) {
          passengers.clear();
          for (var passenger in rideData['passengers']) {
            passengers.add({
              'id': passenger['_id'] ?? '',
              'name': passenger['name'] ?? 'Passenger',
              'rating': passenger['rating'] ?? 5.0,
              'profilePic': passenger['profilePic'] ?? 'https://via.placeholder.com/150',
            });
          }
          dev.log("✅ Successfully loaded ${passengers.length} passengers");
        }
        
        requestState.value = RequestState.online;
        return;
      }
      
      // If DriverService approach failed, try a direct API call
      dev.log("⚠️ Failed to get ride data from service, trying direct API call");
      
      final token = Get.find<AuthController>().token.value;
      if (token.isEmpty) {
        throw Exception("No auth token available");
      }
      
      // Use the correct endpoint based on the API design
      final endpoint = "${ApiEndpoints.baseUrl}/user/get/ride/data/$rideId";
      dev.log("🔍 Trying API endpoint: $endpoint");
      
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      dev.log("📊 API response: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract ride data
        final Map<String, dynamic> directRideData;
        if (data.containsKey('ride')) {
          directRideData = data['ride'];
          dev.log("✅ Found ride data in 'ride' field");
        } else {
          directRideData = data;
          dev.log("✅ Using full response as ride data");
        }
        
        // Process route data
        if (directRideData.containsKey('route') && directRideData['route'] is List) {
          routes.clear();
          routes.addAll(directRideData['route']);
          dev.log("✅ Successfully extracted route data");
          initializeRideFromRoute();
        } else {
          dev.log("⚠️ No route data in response, using fallback");
          await _createFallbackRoute();
        }
        
        // Load passengers
        if (directRideData.containsKey('passengers') && directRideData['passengers'] is List) {
          passengers.clear();
          for (var passenger in directRideData['passengers']) {
            passengers.add({
              'id': passenger['_id'] ?? '',
              'name': passenger['name'] ?? 'Passenger',
              'rating': passenger['rating'] ?? 5.0,
              'profilePic': passenger['profilePic'] ?? 'https://via.placeholder.com/150',
            });
          }
          dev.log("✅ Successfully loaded ${passengers.length} passengers");
        }
        
        requestState.value = RequestState.online;
        return;
      }
      
      // If we got here, all attempts failed
      dev.log("❌ Failed to load ride data");
      requestState.value = RequestState.failed;
      
      // Show error with retry button
      Get.snackbar(
        "Connection Error", 
        "Could not load the ride data. Please try again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 10),
        mainButton: TextButton(
          onPressed: () {
            loadRideData(); // Retry loading ride data
          },
          child: Text("Retry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )
      );
      
      // Try to recover with fallback data
      await _createFallbackRoute();
      
    } catch (e) {
      dev.log("❌ Error loading ride data: $e");
      requestState.value = RequestState.failed;
      
      // Show error with retry button
      Get.snackbar(
        "Connection Error", 
        "Could not connect to the server. Tap retry to try again.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: Duration(seconds: 10),
        mainButton: TextButton(
          onPressed: () {
            loadRideData(); // Retry loading ride data
          },
          child: Text("Retry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )
      );
      
      // Try to recover with fallback data
      await _createFallbackRoute();
    }
  }

  Future<void> _createFallbackRoute() async {
    dev.log("🔄 Creating fallback route data");
    
    try {
      // Try to get current location
      Position position;
      try {
        position = await Geolocator.getCurrentPosition();
        currentLocation = LatLng(position.latitude, position.longitude);
        dev.log("✅ Using current location for fallback: $currentLocation");
      } catch (e) {
        dev.log("⚠️ Could not get current location, using defaults for Riyadh");
        // Default to Riyadh, Saudi Arabia
        currentLocation = LatLng(24.7136, 46.6753);
      }
      
      // Create a destination point slightly northeast of current location
      destinationLocation = LatLng(
        currentLocation.latitude + 0.01, 
        currentLocation.longitude + 0.01
      );
      
      // Validate coordinates are within allowed bounds
      if (currentLocation.latitude < -90 || currentLocation.latitude > 90 || 
          currentLocation.longitude < -180 || currentLocation.longitude > 180) {
        dev.log("⚠️ Invalid current location coordinates, using defaults");
        currentLocation = LatLng(24.7136, 46.6753);
      }
      
      if (destinationLocation.latitude < -90 || destinationLocation.latitude > 90 || 
          destinationLocation.longitude < -180 || destinationLocation.longitude > 180) {
        dev.log("⚠️ Invalid destination coordinates, using defaults");
        destinationLocation = LatLng(24.7236, 46.6953);
      }
    } catch (e) {
      dev.log("⚠️ Error in fallback route creation: $e, using defaults");
      currentLocation = LatLng(24.7136, 46.6753);
      destinationLocation = LatLng(24.7236, 46.6953);
    }
    
    // Set up route data
    routes.clear();
    routes.addAll([
      {"lat": currentLocation.latitude, "lng": currentLocation.longitude},
      {"lat": destinationLocation.latitude, "lng": destinationLocation.longitude}
    ]);
    
    // Set default ride information
    distanceKm = 2.5;  // Approximately 2.5 km
    etaMinutes = 10;   // 10 minutes ETA
    destination = "Default Destination";
    
    // Create markers
    markers.clear();
    markers.addAll([
      Marker(
        point: currentLocation,
        width: 40,
        height: 40,
        child: Image.asset('assets/images/car.png', width: 40, height: 40),
      ),
      Marker(
        point: destinationLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_pin, color: Colors.blue, size: 40),
      ),
    ]);
    
    // Create route polyline
    routePolyline.clear();
    routePolyline.add(Polyline(
      points: [currentLocation, destinationLocation],
      color: Colors.blue,
      strokeWidth: 4,
    ));
    
    dev.log("✅ Created fallback route data successfully");
    
    // Update UI
    update();
    
    // Initialize from this route
    initializeRideFromRoute();
  }

  void initializeRideFromRoute() {
    try {
      dev.log("🔄 Initializing ride from routes: $routes");
      
      // Skip if already initialized
      if (requestState.value == RequestState.online && 
          markers.isNotEmpty && routePolyline.isNotEmpty) {
        dev.log("✅ Ride already initialized, skipping redundant initialization");
        return;
      }
      
      // Parse stored global routes with validation
      final validPoints = <LatLng>[];
      
      for (var pt in routes) {
        try {
          final m = pt is Map<String, dynamic> ? pt : Map<String, dynamic>.from(pt as Map);
          final double lat = m['lat'] as double;
          final double lng = m['lng'] as double;
          
          // Validate coordinates are within allowed bounds
          if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
            validPoints.add(LatLng(lat, lng));
          } else {
            dev.log("⚠️ Skipping invalid route point: lat=$lat, lng=$lng");
          }
        } catch (e) {
          dev.log("⚠️ Error processing route point: $e");
        }
      }

      if (validPoints.length < 2) {
        dev.log("⚠️ Not enough valid points in route data, using defaults");
        currentLocation = LatLng(24.7136, 46.6753);
        destinationLocation = LatLng(24.7236, 46.6953);
      } else {
        // Assign start & destination
        currentLocation = validPoints.first;
        destinationLocation = validPoints.last;
      }

    // Add map markers
    markers.clear();
    markers.addAll([
      Marker(
        point: currentLocation,
        width: 40,
        height: 40,
        child: Image.asset('assets/images/car.png', width: 40, height: 40),
      ),
      Marker(
        point: destinationLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_pin, color: Colors.blue, size: 40),
      ),
    ]);

      // Get destination name and route info immediately
      _getRouteInfoFromOpenRouteService();

      update(); // Update UI
    } catch (e) {
      dev.log("❌ Error initializing ride: $e");
      _handleInitializationError();
    }
  }
  
  // Get route information from OpenRouteService API
  Future<void> _getRouteInfoFromOpenRouteService() async {
    try {
      // Set default values first
    distanceKm = _computeDistanceKm(currentLocation, destinationLocation);
      etaMinutes = (distanceKm / 30.0 * 60).round(); // Assuming 30 km/h avg speed
      destination = '${destinationLocation.latitude.toStringAsFixed(4)}, ${destinationLocation.longitude.toStringAsFixed(4)}';
      
      // First get destination address from geocoding
      await _getDestinationName();
      
      // Then get more accurate route info
      final response = await http.post(
        Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car'),
        headers: {
          'Authorization': openRouteServiceApiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({
          "coordinates": [
            [currentLocation.longitude, currentLocation.latitude],
            [destinationLocation.longitude, destinationLocation.latitude]
          ],
          "instructions": true,
          "format": "json"
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data.containsKey('routes') && data['routes'] is List && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          
          // Extract distance and duration
          if (route.containsKey('summary')) {
            final summary = route['summary'];
            if (summary.containsKey('distance')) {
              // Distance is in meters, convert to km
              distanceKm = (summary['distance'] / 1000).toDouble();
            }
            
            if (summary.containsKey('duration')) {
              // Duration is in seconds, convert to minutes
              etaMinutes = (summary['duration'] / 60).round();
            }
          }
          
          // Create polyline from route geometry
          if (route.containsKey('geometry')) {
            _createRoutePolylineFromGeometry(route['geometry']);
          }
          
          update(); // Update UI with new info
        }
      } else {
        dev.log("⚠️ OpenRouteService API error: ${response.statusCode} - ${response.body}");
        // Fallback to simple polyline
        _createRoutePolyline();
      }
    } catch (e) {
      dev.log("❌ Error getting route info: $e");
      // Fallback to simple route calculation
      _createRoutePolyline();
    }
  }
  
  // Get destination name using reverse geocoding
  Future<void> _getDestinationName() async {
    try {
      dev.log("🔍 Getting destination name for: ${destinationLocation.latitude}, ${destinationLocation.longitude}");
      
      // Try multiple geocoding services
      bool success = false;
      
      // First attempt: OpenCage geocoding service
      try {
        final response = await http.get(
          Uri.parse(
            'https://api.opencagedata.com/geocode/v1/json?q=${destinationLocation.latitude}+${destinationLocation.longitude}&key=8c0bbd95e01c4d74809e1c5756d446a5&pretty=1'
          ),
          headers: {
            'Accept': 'application/json',
          },
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          dev.log("🔍 OpenCage geocoding response: ${response.statusCode}");
          
          if (data.containsKey('results') && data['results'] is List && data['results'].isNotEmpty) {
            final result = data['results'][0];
            
            // Check if we have a formatted address
            if (result.containsKey('formatted')) {
              destination = result['formatted'];
              dev.log("✅ Found destination name: $destination");
              success = true;
            } 
            // Otherwise try to build address from components
            else if (result.containsKey('components')) {
              final components = result['components'];
              final List<String> addressParts = [];
              
              if (components.containsKey('road')) {
                addressParts.add(components['road']);
              }
              if (components.containsKey('suburb')) {
                addressParts.add(components['suburb']);
              }
              if (components.containsKey('city')) {
                addressParts.add(components['city']);
              }
              if (components.containsKey('state')) {
                addressParts.add(components['state']);
              }
              
              if (addressParts.isNotEmpty) {
                destination = addressParts.join(', ');
                dev.log("✅ Built destination name from components: $destination");
                success = true;
              }
            }
          }
        } else {
          dev.log("⚠️ OpenCage geocoding error: ${response.statusCode}");
        }
      } catch (e) {
        dev.log("⚠️ OpenCage error: $e");
      }
      
      // Second attempt: Try direct Google Maps geocoding
      if (!success) {
        try {
          dev.log("🔍 Trying Google Maps geocoding fallback");
          final googleResponse = await http.get(
            Uri.parse(
              'https://maps.googleapis.com/maps/api/geocode/json?latlng=${destinationLocation.latitude},${destinationLocation.longitude}&key=AIzaSyAUYP3_LeBFfXRj_8eYRlA_-5DNGdfYKQk'
            )
          );
          
          if (googleResponse.statusCode == 200) {
            final googleData = jsonDecode(googleResponse.body);
            if (googleData['status'] == 'OK' && googleData['results'] is List && googleData['results'].isNotEmpty) {
              destination = googleData['results'][0]['formatted_address'];
              dev.log("✅ Found Google Maps destination name: $destination");
              success = true;
            }
          } else {
            dev.log("⚠️ Google Maps geocoding error: ${googleResponse.statusCode}");
          }
        } catch (e) {
          dev.log("⚠️ Google Maps error: $e");
        }
      }
      
      // If both services failed, use a custom destination name
      if (!success) {
        // Generate a more descriptive name based on coordinates
        final lat = destinationLocation.latitude.toStringAsFixed(4);
        final lng = destinationLocation.longitude.toStringAsFixed(4);
        destination = "Custom Destination ($lat, $lng)";
        dev.log("⚠️ Geocoding failed, using custom destination name");
      }
      
      update(); // Update UI with new destination name
    } catch (e) {
      dev.log("❌ Error getting destination name: $e");
      // Fallback to a nicer display than raw coordinates
      destination = "Custom Destination";
      update();
    }
  }
  
  // Create route polyline from OpenRouteService geometry
  void _createRoutePolylineFromGeometry(String encodedGeometry) {
    try {
    routePolyline.clear();
      
      // Decode the geometry string (polyline format)
      final List<LatLng> decodedPoints = _decodePolyline(encodedGeometry);
      
      if (decodedPoints.isNotEmpty) {
    routePolyline.add(Polyline(
          points: decodedPoints,
      color: Colors.blue,
      strokeWidth: 4,
    ));

    update();
      } else {
        // Fallback to simple line if decoding fails
        _createRoutePolyline();
      }
    } catch (e) {
      dev.log("❌ Error creating polyline from geometry: $e");
      _createRoutePolyline();
    }
  }
  
  // Decode polyline from encoded string (polyline algorithm)
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    
    try {
      while (index < len) {
        int b, shift = 0, result = 0;
        do {
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += dlat;
        
        shift = 0;
        result = 0;
        do {
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += dlng;
        
        // Convert to double and validate bounds before adding
        double latitude = lat / 1E5;
        double longitude = lng / 1E5;
        
        // Ensure coordinates are within valid ranges
        if (latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180) {
          points.add(LatLng(latitude, longitude));
        } else {
          // Log the invalid point for debugging
          dev.log("⚠️ Skipping invalid coordinates: lat=$latitude, lng=$longitude");
        }
      }
    } catch (e) {
      dev.log("❌ Error decoding polyline: $e");
    }
    
    return points;
  }

  Future<void> _createRoutePolyline() async {
    try {
      routePolyline.clear();
      
      // Try to get a proper route from OpenRouteService
      final routeResponse = await http.post(
        Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car/geojson'),
        headers: {
          'Authorization': openRouteServiceApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "coordinates": [
            [currentLocation.longitude, currentLocation.latitude],
            [destinationLocation.longitude, destinationLocation.latitude]
          ]
        }),
      );

      if (routeResponse.statusCode == 200) {
        final routeData = jsonDecode(routeResponse.body);
        if (routeData.containsKey('features') && 
            routeData['features'] is List && 
            routeData['features'].isNotEmpty) {
            
          final coords = routeData['features'][0]['geometry']['coordinates'] as List;
          final validCoords = <LatLng>[];
          
          // Process and validate each coordinate
          for (var c in coords) {
            try {
              final double lng = c[0] as double;
              final double lat = c[1] as double;
              
              // Ensure coordinates are within valid ranges
              if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
                validCoords.add(LatLng(lat, lng));
              } else {
                dev.log("⚠️ Skipping invalid coordinates in route: lat=$lat, lng=$lng");
              }
            } catch (e) {
              dev.log("⚠️ Error processing coordinate: $e");
            }
          }
          
          if (validCoords.isNotEmpty) {
            routePolyline.add(Polyline(
              points: validCoords,
              color: Colors.blue,
              strokeWidth: 4,
            ));
            return;
          } else {
            dev.log("⚠️ No valid route points found, using fallback");
          }
        }
      }
      
      // Fallback to straight line if route service fails
      dev.log("⚠️ Could not get route from service, using straight line");
      routePolyline.add(Polyline(
        points: [currentLocation, destinationLocation],
        color: Colors.blue,
        strokeWidth: 4,
      ));
    } catch (e) {
      dev.log("❌ Error creating route polyline: $e");
      
      // Use simple straight line as ultimate fallback
      routePolyline.add(Polyline(
        points: [currentLocation, destinationLocation],
        color: Colors.red, // Red to indicate error
        strokeWidth: 4,
      ));
    }
  }

  void _handleInitializationError() {
    // Set fallback values
    currentLocation = LatLng(24.7136, 46.6753);
    destinationLocation = LatLng(24.7236, 46.6953);
    distanceKm = 5.0;
    etaMinutes = 10;
    destination = "Error loading destination";
    
    // Add basic markers
    markers.clear();
    markers.addAll([
      Marker(
        point: currentLocation,
        width: 40,
        height: 40,
        child: Image.asset('assets/images/car.png', width: 40, height: 40),
      ),
      Marker(
        point: destinationLocation,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_pin, color: Colors.blue, size: 40),
      ),
    ]);

    // Add simple route
    routePolyline.clear();
    routePolyline.add(Polyline(
      points: [currentLocation, destinationLocation],
      color: Colors.red, // Red to indicate error
      strokeWidth: 4,
    ));

        update();
  }

  Future<void> updateDriverLocation() async {
    if (rideId == null || rideId!.isEmpty) return;
    
    // Skip update if location permission is not granted
    if (!locationPermissionGranted.value) {
      dev.log("⚠️ Skipping location update: No permission");
      return;
    }
    
    try {
      // Get current location
      Position position;
      try {
        position = await Geolocator.getCurrentPosition();
        
        // Validate the coordinates
        if (position.latitude < -90 || position.latitude > 90 || 
            position.longitude < -180 || position.longitude > 180) {
          dev.log("⚠️ Invalid coordinates from Geolocator: lat=${position.latitude}, lng=${position.longitude}");
          // Use simulated position instead
          throw Exception("Invalid coordinates from Geolocator");
        }
        
      } catch (locationError) {
        dev.log("⚠️ Error getting position: $locationError, using simulated position");
        // If Windows location fails, use simulated position with small random movement
        double latOffset = (math.Random().nextDouble() - 0.5) * 0.0005;
        double lngOffset = (math.Random().nextDouble() - 0.5) * 0.0005;
        
        // Ensure the current location is valid before applying offset
        double baseLat = currentLocation.latitude;
        double baseLng = currentLocation.longitude;
        
        if (baseLat < -90 || baseLat > 90) {
          baseLat = 24.7136; // Default latitude if current is invalid
        }
        
        if (baseLng < -180 || baseLng > 180) {
          baseLng = 46.6753; // Default longitude if current is invalid
        }
        
        position = Position(
          latitude: baseLat + latOffset, 
          longitude: baseLng + lngOffset,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
      
      final newLocation = LatLng(position.latitude, position.longitude);
      
      // Update marker position
      if (markers.isNotEmpty) {
        markers[0] = Marker(
          point: newLocation,
          width: 40,
          height: 40,
          child: Image.asset('assets/images/car.png', width: 40, height: 40),
        );
      }
      
      // Update current location
      currentLocation = newLocation;
      
      // Update route info when location has changed significantly
      if (_computeDistanceKm(currentLocation, markers[0].point) > 0.1) {
        _getRouteInfoFromOpenRouteService();
      } else {
        // Simple update for minor movements
        distanceKm = _computeDistanceKm(currentLocation, destinationLocation);
        const avgSpeedKmh = 30.0;
        etaMinutes = (distanceKm / avgSpeedKmh * 60).round();
      }
      
      // Send updated location to server
      final token = Get.find<AuthController>().token.value;
      await http.post(
        Uri.parse("${ApiEndpoints.baseUrl}/driver/update/location"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "rideId": rideId,
          "location": {
            "lat": position.latitude,
            "lng": position.longitude
          }
        }),
      );
      
      update();
    } catch (e) {
      dev.log("❌ Error updating driver location: $e");
      
      // Check if this is a permission error
      if (e.toString().contains("permission")) {
        locationPermissionGranted.value = false;
        _showLocationPermissionError();
      }
    }
  }

  Future<void> refreshRideStatus() async {
    if (rideId == null || rideId!.isEmpty) return;
    
    try {
      final token = Get.find<AuthController>().token.value;
      final response = await http.get(
        Uri.parse("${ApiEndpoints.baseUrl}/driver/ride/$rideId/status"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode != 200) return;
      
      final statusData = jsonDecode(response.body);
      
      // Check if ride is completed or cancelled
      if (statusData['status'] == 'completed') {
        // Stop all timers
        _locationUpdateTimer?.cancel();
        _rideStatusTimer?.cancel();
        _pendingRequestsTimer?.cancel();
        
        // Navigate back with success message
        Get.back();
        Get.snackbar(
          'Ride Completed', 
          'You have reached the destination',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else if (statusData['status'] == 'cancelled') {
        // Stop all timers
        _locationUpdateTimer?.cancel();
        _rideStatusTimer?.cancel();
        _pendingRequestsTimer?.cancel();
        
        // Navigate back with cancellation message
        Get.back();
        Get.snackbar(
          'Ride Cancelled', 
          'This ride has been cancelled',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
      
      // Update passengers list if available
      if (statusData['passengers'] != null && statusData['passengers'] is List) {
        passengers.clear();
        for (var passenger in statusData['passengers']) {
          passengers.add({
            'id': passenger['_id'] ?? '',
            'name': passenger['name'] ?? 'Passenger',
            'rating': passenger['rating'] ?? 5.0,
            'profilePic': passenger['profilePic'] ?? 'https://via.placeholder.com/150',
          });
        }
      }
      
      update();
    } catch (e) {
      dev.log("❌ Error refreshing ride status: $e");
    }
  }

  Future<void> fetchPendingRequests() async {
    if (rideId == null || rideId!.isEmpty) {
      dev.log("❌ Cannot fetch pending requests: No ride ID available");
      return;
    }
    
    try {
      // Skip if we already have a pending request
      if (hasPendingRequest.value) {
        dev.log("ℹ️ Skipping pending requests fetch: Already have a pending request");
        return;
      }
      
      dev.log("🔄 Fetching pending requests for ride ID: $rideId");
      
      // Fetch pending requests from API
      final requests = await _driverService.getPendingRequests(rideId!);
      
      if (requests.isEmpty) {
        dev.log("ℹ️ No pending requests found");
        return;
      }
      
      dev.log("✅ Found ${requests.length} pending requests");
      
      // Get the newest request
      final request = requests.first;
      dev.log("📝 Processing request: ${request['_id']}");
      
      // Calculate distance between driver and pickup location
      double pickupDistanceKm = 0.0;
      int pickupTimeMinutes = 3; // Default value
      
      try {
        if (request['pickupLocation'] != null && 
            request['pickupLocation']['lat'] != null && 
            request['pickupLocation']['lng'] != null) {
          
          final pickupLat = request['pickupLocation']['lat'] as double;
          final pickupLng = request['pickupLocation']['lng'] as double;
          final pickupLocation = LatLng(pickupLat, pickupLng);
          
          // Calculate distance to pickup
          pickupDistanceKm = _computeDistanceKm(currentLocation, pickupLocation);
          dev.log("📍 Pickup distance: ${pickupDistanceKm.toStringAsFixed(2)} km");
          
          // Estimate pickup time (assuming 30 km/h average speed)
          const avgSpeedKmh = 30.0;
          pickupTimeMinutes = (pickupDistanceKm / avgSpeedKmh * 60).round();
          if (pickupTimeMinutes < 1) pickupTimeMinutes = 1;
          dev.log("⏱️ Estimated pickup time: $pickupTimeMinutes minutes");
        }
      } catch (e) {
        dev.log("⚠️ Error calculating pickup distance: $e");
      }
      
      // Estimate potential earnings (based on distance to destination)
      String estimatedEarnings = "SAR 15-20"; // Default fallback
      
      try {
        // Simple calculation based on distance
        final double baseRate = 10.0; // Base fare in SAR
        final double perKmRate = 2.0; // SAR per km
        
        // Use the total ride distance for earnings estimate
        final double estimatedFare = baseRate + (distanceKm * perKmRate);
        final double minFare = (estimatedFare * 0.9).round().toDouble(); // 10% lower bound
        final double maxFare = (estimatedFare * 1.1).round().toDouble(); // 10% upper bound
        
        estimatedEarnings = "SAR ${minFare.toInt()}-${maxFare.toInt()}";
        dev.log("💰 Estimated earnings: $estimatedEarnings");
      } catch (e) {
        dev.log("⚠️ Error calculating estimated earnings: $e");
      }
      
      // Set the pending request with enhanced data
      pendingRequest.value = {
        'id': request['_id'] ?? '',
        'name': request['user']?['name'] ?? 'New Passenger',
        'rating': request['user']?['rating'] ?? 5.0,
        'profilePic': request['user']?['profilePic'] ?? 'https://via.placeholder.com/150',
        'pickup': request['pickupLocation']?['address'] ?? 'Unknown location',
        'pickupDistanceKm': pickupDistanceKm,
        'pickupTimeMinutes': pickupTimeMinutes,
        'estimatedEarnings': estimatedEarnings,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      dev.log("✅ Set pending request data: ${pendingRequest.value}");
      
      // Play notification sound
      await _playRequestNotification();
      
      // Set the pending request flag to show the notification
      hasPendingRequest.value = true;
      
      // Auto-decline after 30 seconds if not handled
      Future.delayed(const Duration(seconds: 30), () {
        if (hasPendingRequest.value && 
            pendingRequest.value.isNotEmpty &&
            pendingRequest.value['id'] == request['_id']) {
          dev.log("⏰ Auto-declining request after timeout");
          declineRequest();
        }
      });
    } catch (e) {
      dev.log("❌ Error fetching pending requests: $e");
    }
  }

  Future<void> _playRequestNotification() async {
    try {
      // You would need to add a sound file to your assets folder
      // And declare it in your pubspec.yaml
      await _audioPlayer.play(AssetSource('sounds/ride_request.mp3'));
    } catch (e) {
      dev.log("❌ Error playing notification sound: $e");
    }
  }

  Future<void> acceptRequest() async {
    if (pendingRequest['id'] == null || pendingRequest['id'].isEmpty) {
      Get.snackbar('Error', 'Invalid request ID');
      return;
    }
    try {
      requestState.value = RequestState.loading;
      final approved = await _driverService.approveJoinRequest(pendingRequest['id'], true);
      if (approved) {
        // Add to passengers list with status
        passengers.add({
          ...pendingRequest,
          'status': 'approved',
          'pickedUp': false,
          'droppedOff': false,
        });
        hasPendingRequest.value = false;
        pendingRequest.clear();
        requestState.value = RequestState.online;
        Get.snackbar(
          'Request Accepted',
          'Passenger has been added to your ride',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        requestState.value = RequestState.failed;
        Get.snackbar(
          'Error',
          'Failed to approve request',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      requestState.value = RequestState.failed;
      Get.snackbar(
        'Error',
        'Failed to accept request: [31m${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> declineRequest() async {
    if (pendingRequest['id'] == null || pendingRequest['id'].isEmpty) {
      hasPendingRequest.value = false;
      pendingRequest.clear();
      return;
    }
    try {
      requestState.value = RequestState.loading;
      final declined = await _driverService.approveJoinRequest(pendingRequest['id'], false);
      hasPendingRequest.value = false;
      pendingRequest.clear();
      requestState.value = RequestState.online;
      if (declined) {
        Get.snackbar(
          'Request Declined',
          'You have declined the join request',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to decline request',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      requestState.value = RequestState.failed;
      Get.snackbar(
        'Error',
        'Failed to decline request: [31m${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> pickupPassenger(String requestId) async {
    try {
      requestState.value = RequestState.loading;
      final pickedUp = await _driverService.pickupPassenger(requestId);
      if (pickedUp) {
        // Update passenger status
        final idx = passengers.indexWhere((p) => p['id'] == requestId);
        if (idx != -1) passengers[idx]['pickedUp'] = true;
        requestState.value = RequestState.online;
        update();
        Get.snackbar(
          'Passenger Picked Up',
          'You have picked up the passenger',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      } else {
        requestState.value = RequestState.failed;
        Get.snackbar(
          'Error',
          'Failed to pick up passenger',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      requestState.value = RequestState.failed;
      Get.snackbar(
        'Error',
        'Failed to pick up passenger: [31m${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> dropoffPassenger(String requestId) async {
    try {
      requestState.value = RequestState.loading;
      final dropped = await _driverService.dropoffPassenger(requestId);
      if (dropped) {
        // Update passenger status
        final idx = passengers.indexWhere((p) => p['id'] == requestId);
        if (idx != -1) passengers[idx]['droppedOff'] = true;
        requestState.value = RequestState.online;
        update();
        Get.snackbar(
          'Passenger Dropped Off',
          'You have dropped off the passenger',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      } else {
        requestState.value = RequestState.failed;
        Get.snackbar(
          'Error',
          'Failed to drop off passenger',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      requestState.value = RequestState.failed;
      Get.snackbar(
        'Error',
        'Failed to drop off passenger: [31m${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> endRide() async {
    if (rideId == null || rideId!.isEmpty) {
      Get.snackbar(
        "No Active Ride", 
        "There is no active ride to end",
        backgroundColor: Colors.orange,
        colorText: Colors.white
      );
      return;
    }
    
    // Show confirmation dialog
    final bool confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text("End Ride?"),
        content: Text("Are you sure you want to end this ride? This will drop off all passengers."),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text("End Ride"),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) {
      return;
    }
    
    try {
      requestState.value = RequestState.loading;
      
      // Show loading indicator
      Get.dialog(
        Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        barrierDismissible: false,
      );
      
      // Call the API to end the ride
      final success = await _driverService.endRide(rideId!);
      
      // Remove loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      if (success) {
        // Stop all timers
        _locationUpdateTimer?.cancel();
        _rideStatusTimer?.cancel();
        _pendingRequestsTimer?.cancel();
        
        requestState.value = RequestState.success;
        
        // Show success message
        Get.snackbar(
          "Ride Ended", 
          "Your ride has been successfully ended",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
        
        // Clear local ride data
        _driverService.currentRideId = null;
        
        // Navigate back to home screen after a short delay
        Future.delayed(Duration(milliseconds: 500), () {
          Get.offNamed('/driver-home'); // Use offNamed to replace current screen
        });
      } else {
        requestState.value = RequestState.failed;
        Get.snackbar(
          "Error", 
          "Failed to end ride. Please try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Remove loading dialog if still showing
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      requestState.value = RequestState.failed;
      Get.snackbar(
        "Error", 
        "Failed to end ride: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> endClientRide(String clientId) async {
    if (rideId == null || rideId!.isEmpty) {
      Get.snackbar('Error', 'No active ride');
      return;
    }
    
    try {
      requestState.value = RequestState.loading;
      
      await _driverService.endClientRide(rideId!, clientId);
      
      // Remove passenger from list
      passengers.removeWhere((passenger) => passenger['id'] == clientId);
      
      requestState.value = RequestState.online;
      
      Get.snackbar(
        'Passenger Dropped Off', 
        'Passenger has been dropped off successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      requestState.value = RequestState.failed;
      Get.snackbar(
        'Error', 
        'Failed to drop off passenger: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  double _computeDistanceKm(LatLng a, LatLng b) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);
    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);
    final h = sinDLat * sinDLat +
        math.cos(_toRad(a.latitude)) *
            math.cos(_toRad(b.latitude)) *
            sinDLng * sinDLng;
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return R * c;
  }

  double _toRad(double deg) => deg * math.pi / 180;
}

class ChatController extends GetxController {
  RxList<ChatMessage> messages = <ChatMessage>[].obs;
  RxBool loading = false.obs;
  String rideId;

  ChatController(this.rideId);

  Future<void> loadMessages() async {
    loading.value = true;
    try {
      final token = Get.find<AuthController>().token.value;
      messages.value = await ChatService.fetchMessages(token, rideId);
    } catch (e) {
      // Handle error
    } finally {
      loading.value = false;
    }
  }

  Future<void> sendMessage(String message) async {
    final token = Get.find<AuthController>().token.value;
    // Check if there are any passengers before sending a message
    try {
      final driverActiveRideController = Get.find<DriverActiveRideController>();
      if (driverActiveRideController.passengers.isEmpty) {
        Get.snackbar('Error', 'No passengers to send chat to', backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
    } catch (_) {
      // If controller not found, fallback to error
      Get.snackbar('Error', 'No passengers to send chat to', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    try {
      await ChatService.sendMessage(token, rideId, message);
    } catch (e) {
      // If chat room not found, create it and retry
      if (e.toString().contains('Chat room not found')) {
        await ChatService.createChatRoom(token, rideId);
        await ChatService.sendMessage(token, rideId, message);
      } else {
        rethrow;
      }
    }
    await loadMessages();
  }

  Future<void> createChatRoom() async {
    final token = Get.find<AuthController>().token.value;
    await ChatService.createChatRoom(token, rideId);
  }
}


