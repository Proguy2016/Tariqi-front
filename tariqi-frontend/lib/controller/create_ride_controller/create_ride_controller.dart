import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:tariqi/const/api_links_keys/api_links_keys.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/const/routes/routes_names.dart';
import 'package:tariqi/view/search_driver_screen/search_driver_screen.dart';
import 'package:tariqi/const/class/request_state.dart';
import 'package:tariqi/controller/auth_controllers/auth_controller.dart';

class CreateRideController extends GetxController {
  late MapController mapController;
  final RxList<Marker> markers = <Marker>[].obs;
  late TextEditingController pickPointController;
  late TextEditingController targetPointController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // For arrival time
  final selectedArrivalTime = ''.obs;
  TimeOfDay? arrivalTimeOfDay;

  final Rx<RequestState> requestState = RequestState.none.obs;
  Position? userPosition;
  final RxBool isPositionLoaded = false.obs;
  
  // Position states for the markers
  final Rxn<LatLng> pickMarkerPosition = Rxn<LatLng>();
  final Rxn<LatLng> targetMarkerPosition = Rxn<LatLng>();

  @override
  void onInit() {
    initialServices();
    super.onInit();
  }

  void initialServices() async {
    mapController = MapController();
    pickPointController = TextEditingController();
    targetPointController = TextEditingController();

    // Set default position to avoid null errors
    // Later it will be overridden by the actual user position
    userPosition = Position(
      longitude: 0,
      latitude: 0,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0.0,
    );

    // Fetch the user's position
    await getUserPosition();
  }

  Future<void> getUserPosition() async {
    try {
      requestState.value = RequestState.loading;

      // Check location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      // Get the user's current position
      userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      isPositionLoaded.value = true;
      
      // Set the pickup marker position
      final currentLatLng = LatLng(userPosition!.latitude, userPosition!.longitude);
      pickMarkerPosition.value = currentLatLng;

      // Add a marker for the user's position
      markers.clear();
      markers.add(
        Marker(
          point: currentLatLng,
          child: const Icon(Icons.my_location, color: Colors.green, size: 30),
        ),
      );

      // Update the pick point text field with the user's current location
      pickPointController.text = await getLocationName(
        lat: userPosition!.latitude,
        long: userPosition!.longitude,
      );

      // Center the map on the user's position
      mapController.move(currentLatLng, 15.0);

      requestState.value = RequestState.success;
    } catch (e) {
      requestState.value = RequestState.error;
      Get.snackbar("Error", "Failed to retrieve user position: $e");
    }
  }

  Future<LatLng?> getTargetLocation({required String location}) async {
    if (location.isEmpty) {
      Get.snackbar("Error", "Please enter a location");
      return null;
    }

    final geoCodeKey = ApiLinksKeys.geoCodingKey;
    final url = Uri.parse(
      '${ApiLinksKeys.baseUrl}?q=$location&key=$geoCodeKey',
    );
    try {
      requestState.value = RequestState.loading;
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'];
        if (results != null && results.isNotEmpty) {
          final geometry = results[0]['geometry'];
          if (geometry != null && geometry['lat'] != null && geometry['lng'] != null) {
            final lat = double.parse(geometry['lat'].toString());
            final lng = double.parse(geometry['lng'].toString());
            
            final targetPoint = LatLng(lat, lng);
            targetMarkerPosition.value = targetPoint;

            if (markers.length < 2) {
              markers.add(
                Marker(
                  point: targetPoint,
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.blueColor,
                    size: 30,
                  ),
                ),
              );
            } else {
              markers[1] = Marker(
                point: targetPoint,
                child: Icon(
                  Icons.location_on,
                  color: AppColors.blueColor,
                  size: 30),
              );
            }

            if (userPosition != null) {
              mapController.fitCamera(
                CameraFit.coordinates(
                  coordinates: [
                    LatLng(userPosition!.latitude, userPosition!.longitude),
                    targetPoint,
                  ],
                ),
              );
            } else {
              mapController.move(targetPoint, 15.0);
            }
            
            requestState.value = RequestState.success;
            return targetPoint;
          }
        }
        requestState.value = RequestState.failed;
        Get.snackbar("Error", "Location not found");
      } else {
        requestState.value = RequestState.failed;
        Get.snackbar("Error", "Failed to get location details");
      }
    } on SocketException catch (e) {
      requestState.value = RequestState.error;
      Get.snackbar("Error", "Network error: $e");
    } on TimeoutException catch (e) {
      requestState.value = RequestState.error;
      Get.snackbar("Error", "Request timeout: $e");
    } on HandshakeException catch (e) {
      requestState.value = RequestState.error;
      Get.snackbar("Error", "Handshake error: $e");
    } on FormatException catch (e) {
      requestState.value = RequestState.error;
      Get.snackbar("Error", "Data format error: $e");
    } on Exception catch (e) {
      requestState.value = RequestState.error;
      Get.snackbar("Error", "Failed to get location: $e");
    }
    return null;
  }

  Future<String> getLocationName({
    required double lat,
    required double long,
  }) async {
    final geoCodeKey = ApiLinksKeys.geoCodingKey;
    final url = Uri.parse(
      '${ApiLinksKeys.baseUrl}?q=$lat+$long&key=$geoCodeKey&pretty=1',
    );
    String locationName = "Unknown location";
    try {
      requestState.value = RequestState.loading;
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'];
        if (results != null && results.isNotEmpty && results[0]['formatted'] != null) {
          locationName = results[0]['formatted'].toString();
          requestState.value = RequestState.success;
          return locationName;
        } else {
          requestState.value = RequestState.failed;
        }
      } else {
        requestState.value = RequestState.failed;
      }
    } on SocketException catch (e) {
      requestState.value = RequestState.error;
      Get.snackbar("Error", "Network error: $e");
    } on TimeoutException catch (e) {
      requestState.value = RequestState.error;
      Get.snackbar("Error", "Request timeout: $e");
    } on HandshakeException catch (e) {
      requestState.value = RequestState.error;
      Get.snackbar("Error", "Handshake error: $e");
    } on FormatException catch (e) {
      requestState.value = RequestState.error;
      Get.snackbar("Error", "Data format error: $e");
    } on Exception catch (e) {
      requestState.value = RequestState.error;
      Get.snackbar("Error", "Failed to get location name: $e");
    }
    return locationName;
  }

  void assignMarkers({required LatLng point}) async {
    // Update the target marker position
    targetMarkerPosition.value = point;
    
    // Update the target point text field
    targetPointController.text = await getLocationName(
      lat: point.latitude,
      long: point.longitude,
    );

    // Make sure we have the user position marker
    if (markers.isEmpty && userPosition != null) {
      markers.add(
        Marker(
          point: LatLng(userPosition!.latitude, userPosition!.longitude),
          child: const Icon(Icons.my_location, color: Colors.green, size: 30),
        ),
      );
    }

    // Add or update the target marker
    if (markers.length < 2) {
      markers.add(
        Marker(
          point: point,
          child: Icon(Icons.location_on, color: AppColors.blueColor, size: 30),
        ),
      );
    } else {
      markers[1] = Marker(
        point: point,
        child: Icon(Icons.location_on, color: AppColors.blueColor, size: 30),
      );
    }

    // Fit both markers on the map
    if (markers.length >= 2) {
      mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: markers.map((marker) => marker.point).toList(),
        ),
      );
    } else {
      // Center the map on the new marker
      mapController.move(point, 15.0);
    }
  }
  
  void setArrivalTime(TimeOfDay time) {
    arrivalTimeOfDay = time;
    // Format the time for display
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    selectedArrivalTime.value = '$hour:$minute';
  }

  Future<void> requestRide(String rideId) async {
    if (!formKey.currentState!.validate()) {
      Get.snackbar("Error", "Please fill in all required fields.");
      return;
    }

    if (userPosition == null) {
      Get.snackbar("Error", "User position not available.");
      return;
    }

    final String apiUrl = "${ApiLinksKeys.baseUrl}/user/respond/to/request/$rideId";

    try {
      requestState.value = RequestState.loading;

      final authController = Get.find<AuthController>();
      final token = authController.token.value;

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "pickupPoint": pickPointController.text,
          "targetPoint": targetPointController.text,
          "userPosition": {
            "latitude": userPosition!.latitude,
            "longitude": userPosition!.longitude,
          },
          "arrivalTime": selectedArrivalTime.value,
        }),
      );

      if (response.statusCode == 200) {
        requestState.value = RequestState.success;
        Get.snackbar("Success", "Ride requested successfully!");
        Get.to(() => const SearchDriverScreen());
      } else {
        requestState.value = RequestState.error;
        try {
          final errorData = jsonDecode(response.body);
          Get.snackbar("Error", errorData["message"] ?? "Failed to request ride.");
        } catch (e) {
          Get.snackbar("Error", "Failed to request ride.");
        }
      }
    } catch (e) {
      requestState.value = RequestState.error;
      Get.snackbar("Error", "An error occurred: $e");
    }
  }

  Future<void> createAndRequestRide() async {
    if (!formKey.currentState!.validate()) {
      Get.snackbar("Error", "Please fill in all required fields.");
      return;
    }

    if (userPosition == null) {
      Get.snackbar("Error", "User position not available.");
      return;
    }
    
    if (selectedArrivalTime.value.isEmpty) {
      Get.snackbar("Error", "Please select an arrival time.");
      return;
    }

    const String createRideUrl = "${ApiLinksKeys.baseUrl}/driver/create/ride";

    try {
      requestState.value = RequestState.loading;

      final authController = Get.find<AuthController>();
      final token = authController.token.value;

      // Create the ride
      final createResponse = await http.post(
        Uri.parse(createRideUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "pickupPoint": pickPointController.text,
          "targetPoint": targetPointController.text,
          "userPosition": {
            "latitude": userPosition!.latitude,
            "longitude": userPosition!.longitude,
          },
          "arrivalTime": selectedArrivalTime.value,
        }),
      );

      if (createResponse.statusCode == 201) {
        final responseData = jsonDecode(createResponse.body);
        final rideId = responseData['ride_id'];

        // Request the ride using the ride_id
        await requestRide(rideId);
      } else {
        requestState.value = RequestState.error;
        final errorData = jsonDecode(createResponse.body);
        Get.snackbar("Error", errorData["message"] ?? "Failed to create ride.");
      }
    } catch (e) {
      requestState.value = RequestState.error;
      Get.snackbar("Error", "An error occurred: $e");
    }
  }

  Future<void> findAndRequestRide() async {
    const String getRidesUrl = "${ApiLinksKeys.baseUrl}/rides";

    try {
      requestState.value = RequestState.loading;

      final authController = Get.find<AuthController>();
      final token = authController.token.value;

      // Fetch the list of rides
      final response = await http.get(
        Uri.parse(getRidesUrl),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final rides = jsonDecode(response.body) as List;

        // Search for a compatible ride
        final compatibleRide = rides.firstWhere(
          (ride) =>
              ride['availableSeats'] > 0 &&
              ride['rideStatus'] == 'scheduled',
          orElse: () => null,
        );

        if (compatibleRide != null) {
          final rideId = compatibleRide['_id'];

          // Request the ride using the ride_id
          await requestRide(rideId);
        } else {
          requestState.value = RequestState.error;
          Get.snackbar("Error", "No compatible rides found.");
        }
      } else {
        requestState.value = RequestState.error;
        final errorData = jsonDecode(response.body);
        Get.snackbar("Error", errorData["message"] ?? "Failed to fetch rides.");
      }
    } catch (e) {
      requestState.value = RequestState.error;
      Get.snackbar("Error", "An error occurred: $e");
    }
  }

  void createRide() {
    if (userPosition == null) {
      Get.snackbar("Error", "User position not available.");
      return;
    }
    
    if (pickMarkerPosition.value == null || targetMarkerPosition.value == null) {
      Get.snackbar("Error", "Please set pickup and destination points.");
      return;
    }
    
    if (selectedArrivalTime.value.isEmpty) {
      Get.snackbar("Error", "Please select an arrival time.");
      return;
    }
    
    if (formKey.currentState!.validate()) {
      try {
        requestState.value = RequestState.loading;
        
        // Call the API to create the ride
        final authController = Get.find<AuthController>();
        final token = authController.token.value;
        
        const String createRideUrl = "${ApiLinksKeys.baseUrl}/driver/create/ride";
        
        http.post(
          Uri.parse(createRideUrl),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({
            "pickupPoint": {
              "address": pickPointController.text,
              "lat": pickMarkerPosition.value!.latitude,
              "lng": pickMarkerPosition.value!.longitude
            },
            "destinationPoint": {
              "address": targetPointController.text,
              "lat": targetMarkerPosition.value!.latitude,
              "lng": targetMarkerPosition.value!.longitude
            },
            "arrivalTime": selectedArrivalTime.value,
            "maxPassengers": 4 // Default maximum passengers
          }),
        ).then((response) {
          if (response.statusCode == 201 || response.statusCode == 200) {
            // Ride created successfully
            final responseData = jsonDecode(response.body);
            final rideId = responseData['ride_id'] ?? responseData['_id'];
            
            requestState.value = RequestState.success;
            
            // Navigate directly to the driver active ride screen
            Get.offNamed(
              AppRoutesNames.driverActiveRideScreen,
              arguments: {
                "rideId": rideId,
              },
            );
          } else {
            // Handle error
            requestState.value = RequestState.failed;
            final errorData = jsonDecode(response.body);
            Get.snackbar("Error", errorData["message"] ?? "Failed to create ride.");
          }
        }).catchError((error) {
          requestState.value = RequestState.error;
          Get.snackbar("Error", "Failed to create ride: $error");
        });
      } catch (e) {
        requestState.value = RequestState.error;
        Get.snackbar("Error", "An error occurred: $e");
      }
    }
  }

  @override
  void onClose() {
    pickPointController.dispose();
    targetPointController.dispose();
    mapController.dispose();
    super.onClose();
  }
}