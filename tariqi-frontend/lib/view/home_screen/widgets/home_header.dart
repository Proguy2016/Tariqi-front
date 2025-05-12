import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/controller/home_controller/home_controller.dart';

PreferredSizeWidget? homeScreenHeader({
  required HomeController homeController,
  required void Function() locationFunction,
  required void Function() menuFunction,
}) => AppBar(
  backgroundColor: Colors.transparent,
  leading: GestureDetector(
    onTap: menuFunction,
    child: Icon(Icons.menu, size: 30),
  ),
  actions: [
    Obx(
      () => Visibility(
        visible: homeController.isLocationDisabled.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MaterialButton(
              color: AppColors.blackColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ScreenSize.screenWidth! * 0.1,
                ),
              ),
              onPressed: locationFunction,
              child: Text("Turn On Your Location"),
            ),
          ],
        ),
      ),
    ),
  ],
);
