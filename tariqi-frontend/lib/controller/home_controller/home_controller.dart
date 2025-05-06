import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:tariqi/const/api_links_keys/api_links_keys.dart';
import 'package:http/http.dart' as http;
import 'package:tariqi/const/class/request_state.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tariqi/const/routes/routes_names.dart';

class HomeController extends GetxController {
  late MapController mapController;
  late TextEditingController pickPointController;
  var isLoading = false.obs;
  Rx<RequestState> requestState = RequestState.none.obs;
   RxBool selectedPackage = false.obs;
  RxBool isLocationDisabled = true.obs;
  Position userPosition = Position(
    longitude: 31.231865086027796,
    latitude: 30.042687574993323,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
  List<Marker> markers = [];

  RxBool selectedRide = true.obs;

  Future<LatLng?> getLocation({required String location}) async {
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
        if (results.isNotEmpty) {
          final geometry = results[0]['geometry'];
          final lat = geometry['lat'];
          final lng = geometry['lng'];
          markers.add(
            Marker(
              point: LatLng(lat, lng),
              child: Icon(
                Icons.location_on,
                color: AppColors.blueColor,
                size: 30,
              ),
            ),
          );
          mapController.move(LatLng(lat, lng), 12);
          requestState.value = RequestState.success;

          return LatLng(lat, lng);
        } else {
          requestState.value = RequestState.failed;
        }
      } else {
        requestState.value = RequestState.failed;
      }
    } on SocketException catch (e) {
      requestState.value = RequestState.error;
      throw Exception('Network error: $e');
    } on TimeoutException catch (e) {
      requestState.value = RequestState.error;
      throw Exception('Request timeout: $e');
    } on HandshakeException catch (e) {
      requestState.value = RequestState.error;
      throw Exception('Handshake error: $e');
    } on Exception catch (e) {
      requestState.value = RequestState.error;
      throw Exception('Failed to get location: $e');
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
    String locationName = "";
    try {
      requestState.value = RequestState.loading;
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'];
        if (results.isNotEmpty) {
          final locationName = results[0]['formatted'];

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
      throw Exception('Network error: $e');
    } on TimeoutException catch (e) {
      requestState.value = RequestState.error;
      throw Exception('Request timeout: $e');
    } on HandshakeException catch (e) {
      requestState.value = RequestState.error;
      throw Exception('Handshake error: $e');
    } on Exception catch (e) {
      requestState.value = RequestState.error;
      throw Exception('Failed to get location: $e');
    }
    return locationName;
  }

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // تأكد إن الـ GPS شغال
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // تحقق من صلاحية الوصول للموقع
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    isLocationDisabled.value = false;
    // هيرجعلك الموقع الحالي
    return await Geolocator.getCurrentPosition();
  }

  void getUserLocation() async {
    try {
      requestState.value = RequestState.loading;
      userPosition = await determinePosition();
      requestState.value = RequestState.success;

      pickPointController.text = await getLocationName(
        lat: userPosition.latitude,
        long: userPosition.longitude,
      );

      markers.add(
        Marker(
          point: LatLng(userPosition.latitude, userPosition.longitude),
          child: Icon(Icons.location_on, color: AppColors.blueColor, size: 30),
        ),
      );

      
    } catch (e) {
      return Future.error('Failed to get user location: $e');
    }
  }

  void checkLocationPremission() async {
    requestState.value = RequestState.loading;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      getUserLocation();
      isLocationDisabled.value = false;
    } else {
      requestState.value = RequestState.none;
      isLocationDisabled.value = true;
    }
  }

  void selectRideType() {
    selectedRide.value = !selectedRide.value;
  }

  void assignMarkers({required LatLng point}) async {
    pickPointController.text = await getLocationName(
      lat: point.latitude,
      long: point.longitude,
    );
    mapController.move(LatLng(point.latitude, point.longitude), 15);
    markers = [
      Marker(
        point: LatLng(point.latitude, point.longitude),
        child: Icon(Icons.location_on, color: AppColors.blueColor, size: 30),
      ),
    ];

    userPosition = Position(
      longitude: point.longitude,
      latitude: point.latitude,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    update();
  }

  void goToCreateRideScreen() {
    Get.offNamed(
      AppRoutesNames.createRideScreen,
      arguments: {
        "markers": markers,
        "pick_point": pickPointController.text,
        "position": userPosition,
      },
    );
  }

  void initControllers() {
    mapController = MapController();
    pickPointController = TextEditingController();
  }

  void disposeController() {
    mapController.dispose();
    pickPointController.dispose();
  }

  @override
  void onInit() {
    initControllers();
    checkLocationPremission();
    super.onInit();
  }

  @override
  void onClose() {
    disposeController();
    super.onClose();
  }
}
