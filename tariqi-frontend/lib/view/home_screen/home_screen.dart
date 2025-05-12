import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/controller/home_controller/home_controller.dart';
import 'package:tariqi/view/home_screen/widgets/custom_drawer.dart';
import 'package:tariqi/view/home_screen/widgets/home_header.dart';
import 'package:tariqi/view/home_screen/widgets/map_view.dart';
import 'package:tariqi/view/home_screen/widgets/ride_kind.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final homeController = Get.put(HomeController());
    return Scaffold(
      key: homeController.scaffoldKey,
      drawer: customDrawer(
        homeController: homeController,

        messagesFunction: () {
          // Handle messages Page Route
        },
      ),
      extendBodyBehindAppBar: true,
      appBar: homeScreenHeader(
        menuFunction: () {
          homeController.scaffoldKey.currentState!.openDrawer();
        },
        homeController: homeController,
        locationFunction: () {
          homeController.getUserLocation();
        },
      ),
      body: SlidingUpPanel(
        parallaxEnabled: true,
        backdropColor: Colors.transparent,
        maxHeight: ScreenSize.screenHeight! * 0.01,
        minHeight: ScreenSize.screenHeight! * 0.00,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        panelBuilder: (controller) => Container(),
        body: SafeArea(
          child: Stack(
            children: [
              mapView(homeController: homeController),

              Positioned(
                right: 0,
                left: 0,
                top: 0,
                child: chooseRideKind(
                  startRide: () {
                    homeController.goToCreateRideScreen();
                  },
                  homeController: homeController,
                  textEditingController: homeController.pickPointController,

                  pickPointFunction: (value) {
                    homeController.getClientLocation(location: value);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
