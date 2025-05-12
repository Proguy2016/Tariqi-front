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
import 'package:tariqi/controller/notification_controller.dart';
import 'package:tariqi/models/app_notification.dart';

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
    
    // Initialize services and controllers immediately
    controller = Get.put(DriverHomeController());
    final notificationController = Get.put(NotificationController());
    if (notificationController.notifications.isEmpty) {
      notificationController.loadNotifications();
    }
    
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
                  decoration: BoxDecoration(
                  color: AppColors.blackColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          const Text(
                            "Driver Menu",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Profile Card
                          Card(
                            color: Colors.white.withOpacity(0.06),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              child: Obx(() => Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 38,
                                    backgroundColor: Colors.grey[700],
                                    backgroundImage: controller.driverProfilePic.value.isNotEmpty
                                        ? NetworkImage(controller.driverProfilePic.value)
                                        : null,
                                    child: controller.driverProfilePic.value.isEmpty
                                        ? const Icon(Icons.person, size: 38, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    controller.driverEmail.value,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${controller.carMake.value} ${controller.carModel.value}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    'License: ${controller.licensePlate.value}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Divider(color: Colors.white.withOpacity(0.15), thickness: 1),
                          // Menu Items
                          const SizedBox(height: 10),
                          Obx(() => controller.hasActiveRide.value
                            ? ListTile(
                                leading: const Icon(Icons.directions_car, color: Colors.green),
                                title: const Text("Resume Active Ride", style: TextStyle(color: Colors.white)),
                                onTap: () {
                                  _sideMenuController.reverse();
                                  controller.goToActiveRide();
                                },
                                contentPadding: EdgeInsets.zero,
                                horizontalTitleGap: 12,
                              )
                            : const SizedBox.shrink()
                          ),
                          ListTile(
                            leading: const Icon(Icons.account_circle, color: Colors.white),
                            title: const Text("View Profile", style: TextStyle(color: Colors.white)),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Driver Profile'),
                                  content: Obx(() => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: CircleAvatar(
                                          radius: 40,
                                          backgroundImage: controller.driverProfilePic.value.isNotEmpty
                                              ? NetworkImage(controller.driverProfilePic.value)
                                              : null,
                                          child: controller.driverProfilePic.value.isEmpty
                                              ? const Icon(Icons.person, size: 40)
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text('Email: ${controller.driverEmail.value}'),
                                      const SizedBox(height: 8),
                                      Text('Car: ${controller.carMake.value} ${controller.carModel.value}'),
                                      Text('License Plate: ${controller.licensePlate.value}'),
                                      const SizedBox(height: 8),
                                      Text('Driving License: ${controller.drivingLicense.value}'),
                                    ],
                                  )),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            contentPadding: EdgeInsets.zero,
                            horizontalTitleGap: 12,
                          ),
                          // Notifications ListTile with badge
                          Obx(() {
                            final unreadCount = notificationController.notifications.where((n) => !n.read).length;
                            return Stack(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.notifications, color: Colors.white),
                                  title: const Text("Notifications", style: TextStyle(color: Colors.white)),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Notifications'),
                                        content: SizedBox(
                                          width: 320,
                                          child: Obx(() {
                                            final notifications = notificationController.notifications;
                                            if (notifications.isEmpty) {
                                              return const Text('No notifications.');
                                            }
                                            return ListView.separated(
                                              shrinkWrap: true,
                                              itemCount: notifications.length,
                                              separatorBuilder: (c, i) => const Divider(),
                                              itemBuilder: (c, i) {
                                                final n = notifications[i];
                                                return ListTile(
                                                  leading: Icon(
                                                    n.read ? Icons.notifications_none : Icons.notifications_active,
                                                    color: n.read ? Colors.grey : Colors.blue,
                                                  ),
                                                  title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.bold)),
                                                  subtitle: Text(n.message),
                                                  trailing: n.read ? null : const Icon(Icons.circle, color: Colors.red, size: 10),
                                                  onTap: () {
                                                    // Mark as read in-place
                                                    notificationController.notifications[i] = AppNotification(
                                                      id: n.id,
                                                      type: n.type,
                                                      title: n.title,
                                                      message: n.message,
                                                      recipientId: n.recipientId,
                                                      createdAt: n.createdAt,
                                                      read: true,
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          }),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                    _sideMenuController.reverse(); // Close the menu when dialog opens
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  horizontalTitleGap: 12,
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    left: 18,
                                    top: 10,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '$unreadCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }),
                          ListTile(
                            leading: const Icon(Icons.logout, color: Colors.white),
                            title: const Text("Logout", style: TextStyle(color: Colors.white)),
                            onTap: () => controller.logout(),
                            contentPadding: EdgeInsets.zero,
                            horizontalTitleGap: 12,
                          ),
                          const Spacer(),
                          Divider(color: Colors.white.withOpacity(0.10), thickness: 1),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              'Tariqi Driver v1.0',
                              style: TextStyle(color: Colors.white24, fontSize: 12, letterSpacing: 1.1),
                            ),
                          ),
                          const SizedBox(height: 8),
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