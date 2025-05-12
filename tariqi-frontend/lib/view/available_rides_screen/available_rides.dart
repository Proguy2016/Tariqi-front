import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/controller/available_rides_controller/available_rides_controller.dart';
import 'package:tariqi/view/available_rides_screen/widgets/map_view.dart';
import 'package:tariqi/view/available_rides_screen/widgets/ride_card.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';

class AvailableRidesScreen extends StatelessWidget {
  const AvailableRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final availableRidesController = Get.put(AvailableRidesController());
    int index = 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Available Rides')),
      body: SlidingUpPanel(
        parallaxEnabled: true,
        color: AppColors.blackColor,
        maxHeight: ScreenSize.screenHeight! * 0.6,
        minHeight: ScreenSize.screenHeight! * 0.1,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),

        panelBuilder:
            (controller) => SizedBox(
              height: ScreenSize.screenHeight! * 0.55,
              child: Obx(
                () => HandlingView(
                  requestState: availableRidesController.requestState.value,
                  widget: ListView.builder(
                    itemCount: availableRidesController.availableRides.length,
                    itemBuilder: (context, index) {
                      index = index;
                      return rideCard(
                        bookRideFunction: () {},
                        availableRidesController: availableRidesController,
                        rides: availableRidesController.availableRides[index],
                        index: index,
                        onRideTapFunction:
                            () => availableRidesController.moveToRideLocation(
                              latitude:
                                  availableRidesController
                                      .availableRides[index]
                                      .optimizedRoute!
                                      .first
                                      .lat!,
                              longitude:
                                  availableRidesController
                                      .availableRides[index]
                                      .optimizedRoute!
                                      .first
                                      .lng!,
                            ),
                      );
                    },
                  ),
                ),
              ),
            ),
        body: SafeArea(child: ridesMapView(index: index)),
      ),
    );
  }
}
