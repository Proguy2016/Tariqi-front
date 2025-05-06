import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/const/images/app_images.dart';
import 'package:latlong2/latlong.dart';
import 'package:tariqi/controller/home_controller/home_controller.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Create a key for the DraggableScrollableSheet
  final GlobalKey _draggableKey = GlobalKey();
  
  // Controller for the draggable sheet
  late DraggableScrollableController _draggableController;
  
  // Controller for the side menu animation
  late AnimationController _sideMenuController;
  late Animation<Offset> _sideMenuAnimation;
  late Animation<double> _backgroundDimAnimation;
  
  @override
  void initState() {
    super.initState();
    _draggableController = DraggableScrollableController();
    
    // Initialize the side menu controller
    _sideMenuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Animation for the side menu
    _sideMenuAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sideMenuController,
      curve: Curves.easeInOut,
    ));
    
    // Animation for dimming the background
    _backgroundDimAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5, // 50% opacity black overlay
    ).animate(CurvedAnimation(
      parent: _sideMenuController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _draggableController.dispose();
    _sideMenuController.dispose();
    super.dispose();
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
    final controller = Get.put(HomeController());
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: _sideMenuController,
        builder: (context, child) {
          return Stack(
            children: [
              // Main content - stays fixed, doesn't slide
              SafeArea(
                child: Column(
                  children: [
                    // Header with menu/back button
                    _homeScreenHeader(
                      homeController: controller,
                      locationFunction: () {
                        controller.getUserLocation();
                      },
                      menuFunction: _toggleSideMenu,
                      isMenuOpen: _sideMenuController.isCompleted,
                    ),
                    
                    // Main content area
                    Expanded(
                      child: Stack(
                        children: [
                          // Map takes full space of the expanded area
                          _mapView(homeController: controller),
                          
                          // Draggable bottom sheet with controller
                          NotificationListener<DraggableScrollableNotification>(
                            onNotification: (notification) {
                              // You can track the sheet position here if needed
                              return false;
                            },
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
              
              // Overlay dim layer - only visible when menu is opening/open
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: _sideMenuController.value == 0,
                  child: GestureDetector(
                    onTap: () {
                      // Close menu when tapping on the overlay
                      _sideMenuController.reverse();
                    },
                    child: Container(
                      color: Colors.black.withOpacity(_backgroundDimAnimation.value),
                    ),
                  ),
                ),
              ),
              
              // Side menu - slides in from left as an overlay
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
                        children: const [
                          SizedBox(height: 30),
                          Text(
                            "Menu",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Add menu items here later
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

  // Improved bottom sheet content with better draggability
  Widget _buildBottomSheetContent({
    required HomeController controller,
    required ScrollController scrollController,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blackColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
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
            // Enhanced drag handle - made larger for better draggability
            GestureDetector(
              // Make the handle area explicitly draggable
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) {
                // Manually handle drag to ensure it responds
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
            
            // Content area with ride options
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(), // Prevents overscroll glow
                controller: scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenSize.screenWidth! * 0.05,
                  vertical: ScreenSize.screenHeight! * 0.01,
                ),
                children: [
                  // Ride option
                  Obx(() => GestureDetector(
                    onTap: () {
                      // Toggle ride selection
                      if (controller.selectedRide.value) {
                        controller.selectedRide.value = false;
                      } else {
                        controller.selectedRide.value = true;
                        controller.selectedPackage.value = false;
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(ScreenSize.screenHeight! * 0.02),
                      decoration: BoxDecoration(
                        color: AppColors.blueColor,
                        border: Border.all(
                          color: controller.selectedRide.value
                              ? AppColors.blackColor
                              : Colors.grey,
                          width: controller.selectedRide.value ? 2.0 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Image.asset(AppImages.rideImage, width: 40, height: 40),
                          const SizedBox(width: 10),
                          const Text(
                            "Ride",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                  SizedBox(height: ScreenSize.screenHeight! * 0.02),

                  // Package option
                  Obx(() => GestureDetector(
                    onTap: () {
                      // Toggle package selection
                      if (controller.selectedPackage.value) {
                        controller.selectedPackage.value = false;
                      } else {
                        controller.selectedPackage.value = true;
                        controller.selectedRide.value = false;
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(ScreenSize.screenHeight! * 0.02),
                      decoration: BoxDecoration(
                        color: AppColors.blueColor,
                        border: Border.all(
                          color: controller.selectedPackage.value
                              ? AppColors.blackColor
                              : Colors.grey,
                          width: controller.selectedPackage.value ? 2.0 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Image.asset(AppImages.packageImage, width: 40, height: 40),
                          const SizedBox(width: 10),
                          const Text(
                            "Package",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                  
               
                  SizedBox(height: ScreenSize.screenHeight! * 0.04),
                  
                 
                  MaterialButton(
                    height: 50,
                    minWidth: double.infinity,
                    color: AppColors.blueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onPressed: () {
                      controller.goToCreateRideScreen();
                    },
                    child: const Text(
                      "Start",
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w500, 
                        color: Colors.white
                      ),
                    ),
                  ),
                  
                  // Add extra space at the bottom for better scrollability
                  SizedBox(height: ScreenSize.screenHeight! * 0.1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeScreenHeader({
    required HomeController homeController,
    required void Function() locationFunction,
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
        // Menu/back button with hover effect
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: menuFunction,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMenuOpen ? Icons.arrow_back : Icons.menu, 
                size: 30, 
                color: Colors.white
              ),
            ),
          ),
        ),
        SizedBox(height: ScreenSize.screenHeight! * 0.006),
        Obx(
          () => Visibility(
            visible: homeController.isLocationDisabled.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "To find your pickup location automatically, turn on location services",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: Colors.white),
                  softWrap: true,
                ),
                SizedBox(height: ScreenSize.screenHeight! * 0.01),
                MaterialButton(
                  color: AppColors.blueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ScreenSize.screenWidth! * 0.1,
                    ),
                  ),
                  onPressed: locationFunction,
                  child: const Text(
                    "Turn On Your Location",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _mapView({
    required HomeController homeController,
  }) {
    return GetBuilder<HomeController>(
      builder: (controller) => FlutterMap(
        mapController: controller.mapController,
        options: MapOptions(
          onTap: (tapPosition, point) => controller.assignMarkers(point: point),
          initialCenter: LatLng(
            controller.userPosition?.latitude ?? 0.0,
            controller.userPosition?.longitude ?? 0.0,
          ),
          initialZoom: 15.0,
        ),
        children: [
          Obx(
            () => HandlingView(
              requestState: homeController.requestState.value,
              widget: TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
            ),
          ),
          MarkerLayer(markers: controller.markers),
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
    );
  }
}