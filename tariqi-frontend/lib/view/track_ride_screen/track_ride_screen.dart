import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/const/routes/routes_names.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';
import 'package:tariqi/view/track_ride_screen/widgets/track_map.dart';
import 'package:tariqi/controller/track_ride_controller/track_ride_controller.dart';

class TrackRideScreen extends StatelessWidget {
  const TrackRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TrackRideController());
    return Scaffold(
      appBar: AppBar(
        title: Text("Track Ride"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.offNamed(AppRoutesNames.userTripsScreen),
        ),
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
              trackMapView(controller: controller),
              Obx(
                () => HandlingView(
                  requestState: controller.requestState.value,
                  widget: Container(
                    width: ScreenSize.screenWidth,
                    height: ScreenSize.screenHeight! * 0.05,
                    color: AppColors.blackColor,
                    child: Center(
                      child: Text(
                        "Distance: ${(controller.distance.value / 1000).toStringAsFixed(3)} km",
                        style: TextStyle(color: AppColors.whiteColor),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
