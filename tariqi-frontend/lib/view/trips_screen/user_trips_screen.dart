import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/routes/routes_names.dart';
import 'package:tariqi/controller/user_trips_controller/user_trips_controller.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';
import 'package:tariqi/view/trips_screen/widgets/user_ride_card.dart';

class UserTripsScreen extends StatelessWidget {
  const UserTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserTripsController());
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: GetBuilder<UserTripsController>(
          builder:
              (controller) => Text(
                controller.screenTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ScreenSize.screenWidth! * 0.06,
                ),
              ),
        ),
        toolbarHeight: ScreenSize.screenHeight! * 0.1,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Get.offNamed(AppRoutesNames.homeScreen),
          child: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: SafeArea(
        child: SizedBox.expand(
          child: Obx(
            () => HandlingView(
              requestState: controller.requestState.value,
              widget:
                  controller.userRides.isNotEmpty
                      ? ListView.builder(
                        itemCount: controller.userRides.length,
                        itemBuilder:
                            (context, index) => userRideCard(
                              controller: controller,
                              userRidesModel: controller.userRides[index],
                            ),
                      )
                      : Center(
                        child: Text(
                          "You Have No Trips For Now",
                          style: TextStyle(
                            fontSize: ScreenSize.screenWidth! * 0.06,
                          ),
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
