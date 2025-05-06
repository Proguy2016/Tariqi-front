// lib/view/driver/driver_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/const/images/app_images.dart';
import 'package:latlong2/latlong.dart';
import 'package:tariqi/controller/driver/driver_home_controller.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';
import 'package:tariqi/const/class/request_state.dart';
import 'package:tariqi/const/routes/routes_names.dart';
import 'package:tariqi/services/driver_service.dart';
import 'dart:developer';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> 
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey _draggableKey = GlobalKey();
  late DraggableScrollableController _draggableController;
  late AnimationController _sideMenuController;
  late Animation<Offset> _sideMenuAnimation;
  late Animation<double> _backgroundDimAnimation;
  late DriverHomeController controller;
  
  @override
  void initState() {
    super.initState();
    // Register as an observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    _draggableController = DraggableScrollableController();
    _sideMenuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sideMenuAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sideMenuController,
      curve: Curves.easeInOut,
    ));
    _backgroundDimAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _sideMenuController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize the controller here so we can access it in lifecycle methods
    controller = Get.put(DriverHomeController());
    
    // Check for active rides when the screen is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.checkForActiveRide();
    });
  }
  
  @override
  void dispose() {
    // Clean up app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // End all active rides when screen is disposed
    _endAllRides();
    
    _draggableController.dispose();
    _sideMenuController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log("App lifecycle state changed to: $state");
    
    // When app is paused, inactive, or detached, end all rides
    if (state == AppLifecycleState.detached || 
        state == AppLifecycleState.paused) {
      _endAllRides();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for active rides when dependencies change (e.g., when returning to this screen)
    controller.checkForActiveRide();
  }
  
  // Helper method to end all active rides
  Future<void> _endAllRides() async {
    log("Ending active ride on app exit");
    try {
      final driverService = DriverService();
      await driverService.endAllActiveRides();
    } catch (e) {
      log("Error ending ride on app exit: $e");
    }
  }

  void _toggleSideMenu() {
    if (_sideMenuController.isCompleted) {
      _sideMenuController.reverse();
    } else {
      _sideMenuController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: _sideMenuController,
        builder: (context, child) {
          return Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    _driverScreenHeader(
                      controller: controller,
                      menuFunction: _toggleSideMenu,
                      isMenuOpen: _sideMenuController.isCompleted,
                    ),
                    // Active Ride Banner
                    Obx(() => controller.hasActiveRide.value 
                      ? _buildActiveRideBanner(controller) 
                      : const SizedBox.shrink()
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          _mapView(controller: controller),
                          NotificationListener<DraggableScrollableNotification>(
                            onNotification: (notification) => false,
                            child: DraggableScrollableSheet(
                              key: _draggableKey,
                              controller: _draggableController,
                              initialChildSize: 0.08,
                              minChildSize: 0.08,
                              maxChildSize: 0.6,
                              snap: true,
                              snapSizes: const [0.15, 0.3, 0.6],
                              builder: (context, scrollController) {
                                return _buildBottomSheetContent(
                                  controller: controller,
                                  scrollController: scrollController,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: _sideMenuController.value == 0,
                  child: GestureDetector(
                    onTap: () => _sideMenuController.reverse(),
                    child: Container(
                      color: Colors.black.withOpacity(_backgroundDimAnimation.value),
                    ),
                  ),
                ),
              ),
              SlideTransition(
                position: _sideMenuAnimation,
                child: Container(
                  width: ScreenSize.screenWidth! * 0.7,
                  height: double.infinity,
                  color: AppColors.blackColor,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 30),
                          const Text(
                            "Driver Menu",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(color: Colors.white),
                          _buildDriverInfo(controller),
                          const Divider(color: Colors.white),
                          // Active Ride Button
                          Obx(() => controller.hasActiveRide.value
                            ? ListTile(
                                leading: const Icon(Icons.directions_car, color: Colors.green),
                                title: const Text("Resume Active Ride", style: TextStyle(color: Colors.white)),
                                onTap: () {
                                  // Close menu first
                                  _sideMenuController.reverse();
                                  // Navigate to active ride
                                  controller.goToActiveRide();
                                },
                              )
                            : const SizedBox.shrink()
                          ),
                          ListTile(
                            leading: const Icon(Icons.settings, color: Colors.white),
                            title: const Text("Settings", style: TextStyle(color: Colors.white)),
                            onTap: () {},
                          ),
                          ListTile(
                            leading: const Icon(Icons.logout, color: Colors.white),
                            title: const Text("Logout", style: TextStyle(color: Colors.white)),
                            onTap: () => controller.logout(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDriverInfo(DriverHomeController controller) {
    return Obx(() {
      if (controller.requestState.value == RequestState.loading) {
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      } else if (controller.requestState.value == RequestState.failed) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
            "Failed to load driver info",
            style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => controller.getDriverInfo(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: const Text("Retry"),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Get.offAllNamed(AppRoutesNames.loginScreen), 
                child: const Text(
                  "Login Again",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        );
      }
      return Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: controller.driverProfilePic.value.isNotEmpty
                ? NetworkImage(controller.driverProfilePic.value)
                : null,
            child: controller.driverProfilePic.value.isEmpty
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            controller.driverEmail.value,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            "${controller.carMake.value} ${controller.carModel.value}",
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            "License: ${controller.licensePlate.value}",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      );
    });
  }

  Widget _buildBottomSheetContent({
    required DriverHomeController controller,
    required ScrollController scrollController,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blackColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) {
                final delta = details.primaryDelta! / MediaQuery.of(context).size.height;
                _draggableController.jumpTo(_draggableController.size - delta);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Container(
                    width: 50,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                controller: scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenSize.screenWidth! * 0.05,
                  vertical: ScreenSize.screenHeight! * 0.01,
                ),
                children: [
                  rideFormField(
                    label: "Destination",
                    submitFunction: (value) => 
                        controller.getDestinationLocation(location: value),
                    textEditingController: controller.destinationController,
                    hint: "Enter destination point",
                  ),
                  SizedBox(height: ScreenSize.screenHeight! * 0.02),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Max Passengers",
                              style: const TextStyle(color: Colors.white),
                            ),
                            Obx(() => Slider(
                              value: controller.maxPassengers.value.toDouble(),
                              min: 1,
                              max: 6,
                              divisions: 5,
                              label: controller.maxPassengers.value.toString(),
                              onChanged: (value) => controller.setMaxPassengers(value.toInt()),
                              activeColor: AppColors.blueColor,
                              inactiveColor: Colors.grey,
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenSize.screenHeight! * 0.02),
                  Obx(() => controller.requestState.value == RequestState.loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : MaterialButton(
                    height: 50,
                    minWidth: double.infinity,
                    color: AppColors.blueColor,
                          disabledColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onPressed: controller.isReadyToStart.value
                        ? () => controller.startRide()
                        : null,
                    child: const Text(
                      "Start Ride",
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w500, 
                        color: Colors.white),
                    ),
                  )),
                  if (controller.requestState.value == RequestState.failed)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        "An error occurred. Please try again.",
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(height: ScreenSize.screenHeight! * 0.1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _driverScreenHeader({
    required DriverHomeController controller,
    required void Function() menuFunction,
    required bool isMenuOpen,
  }) => Container(
    width: ScreenSize.screenWidth,
    color: AppColors.blackColor,
    padding: EdgeInsets.symmetric(
      horizontal: ScreenSize.screenWidth! * 0.05,
      vertical: ScreenSize.screenHeight! * 0.01,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: menuFunction,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Icon(
                isMenuOpen ? Icons.arrow_back : Icons.menu, 
                size: 30, 
                color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: ScreenSize.screenHeight! * 0.006),
        Obx(
          () => Visibility(
            visible: controller.isLocationDisabled.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Location services required",
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Please enable location services to create rides and connect with nearby passengers",
                  style: TextStyle(
                    fontSize: 14, 
                    color: Colors.white70),
                ),
                SizedBox(height: ScreenSize.screenHeight! * 0.02),
                MaterialButton(
                  height: 44,
                  minWidth: 200,
                  color: AppColors.blueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onPressed: () => controller.getUserLocation(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Enable Location",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _mapView({required DriverHomeController controller}) {
    return GetBuilder<DriverHomeController>(
      builder: (controller) => Stack(
        children: [
          FlutterMap(
            mapController: controller.mapController,
            options: MapOptions(
              initialCenter: LatLng(
                controller.userPosition?.latitude ?? 24.7136,
                controller.userPosition?.longitude ?? 46.6753,
              ),
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all, // Enable all gestures
              ),
              onTap: (tapPosition, latlng) {
                controller.setDestinationFromMap(latlng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(markers: controller.markers),
              PolylineLayer(
                polylines: controller.routePolyline,
              ),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  const TextSourceAttribution('OpenStreetMap contributors'),
                  LogoSourceAttribution(
                    const Icon(
                      Icons.location_searching_outlined,
                      color: Colors.black,
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
          
          // Default location indicator
          Obx(() => controller.usingDefaultLocation.value
            ? Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Using default location for testing. Click the location button to use your real location.",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox.shrink()
          ),
          
          // Location button
          Positioned(
            right: 16,
            bottom: 90,
            child: FloatingActionButton.extended(
              heroTag: "locationButton",
              backgroundColor: Colors.white,
              onPressed: () => controller.getUserLocation(),
              icon: const Icon(Icons.my_location, color: Colors.blue),
              label: Obx(() => Text(
                controller.usingDefaultLocation.value ? "Use Real Location" : "Refresh Location",
                style: TextStyle(color: Colors.blue),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget rideFormField({
    required String label,
    required Function(String) submitFunction,
    required TextEditingController textEditingController,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: textEditingController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          onSubmitted: submitFunction,
        ),
      ],
    );
  }

  // Active ride banner widget
  Widget _buildActiveRideBanner(DriverHomeController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade800,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "You have an active ride",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Tap to continue your ongoing ride",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => controller.goToActiveRide(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade800,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text("RESUME"),
          ),
        ],
      ),
    );
  }
}