import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/const/routes/routes_names.dart';
import 'package:tariqi/controller/create_ride_controller/create_ride_controller.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:tariqi/view/create_ride_screen/widgets/create_ride_map.dart';
import 'package:tariqi/view/create_ride_screen/widgets/ride_info.dart';

class CreateRideScreen extends StatelessWidget {
  const CreateRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final createRideController = Get.put(CreateRideController());
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create Your Ride",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Get.offNamed(AppRoutesNames.homeScreen),
          child: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: SlidingUpPanel(
        parallaxEnabled: true,
        backdropColor: Colors.transparent,
        maxHeight: ScreenSize.screenHeight! * 0.35,
        minHeight: ScreenSize.screenHeight! * 0.1,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        panelBuilder:
            (controller) => SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.blackColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),

                padding: EdgeInsets.symmetric(
                  horizontal: ScreenSize.screenWidth! * 0.05,
                  vertical: ScreenSize.screenHeight! * 0.04,
                ),
                child: buildInputRideInfo(controller: createRideController),
              ),
            ),
        body: SafeArea(child: createRideMap(controller: createRideController)),
      ),
    );
  }


}
