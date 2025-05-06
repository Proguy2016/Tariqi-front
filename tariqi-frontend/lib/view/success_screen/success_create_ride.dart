import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/const/functions/field_valid.dart';
import 'package:tariqi/const/images/app_images.dart';
import 'package:tariqi/controller/success_controller/success_ride_controller.dart';
import 'package:tariqi/view/core_widgets/ride_form_field.dart';

class SuccessCreateRide extends StatelessWidget {
  const SuccessCreateRide({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SuccessRideController());
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            child: Column(
              spacing: ScreenSize.screenHeight! * 0.04,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Your Ride Created SuccessFully",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: ScreenSize.screenHeight! * 0.02),
                Image.asset(AppImages.successImage),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenSize.screenWidth! * 0.02,
                  ),
                  child: Column(
                    spacing: ScreenSize.screenHeight! * 0.02,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      rideFormField(
                        validate: (value) {
                          return validFields(
                            val: value!,
                            type: "pick",
                            fieldName: "Pick Point",
                            minVal: 1,
                            maxVal: 350,
                          );
                        },
                        prifixtext: "From",
                        label: controller.pickPoint,
                        enabled: false,
                        submitFunction: (value) {},
                        textEditingController: TextEditingController(),
                        hint: controller.pickPoint,
                      ),

                      rideFormField(
                        validate: (value) {
                          return validFields(
                            val: value!,
                            type: "pick",
                            fieldName: "Pick Point",
                            minVal: 1,
                            maxVal: 350,
                          );
                        },
                        prifixtext: "To",
                        label: controller.targetPoint,
                        enabled: false,
                        submitFunction: (value) {},
                        textEditingController: TextEditingController(),
                        hint: controller.targetPoint,
                      ),
                    ],
                  ),
                ),

                MaterialButton(
                  padding: EdgeInsets.symmetric(
                    vertical: ScreenSize.screenHeight! * 0.01,
                    horizontal: ScreenSize.screenWidth! * 0.1,
                  ),
                  color: AppColors.blackColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onPressed: () {
                    // Handle Checkout Ride
                  },
                  child: Text(
                    "Check Out",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
