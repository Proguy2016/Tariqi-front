import 'package:flutter/material.dart';
import 'package:get/get_core/get_core.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/controller/intro_controller/splash_controller.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(SplashController());
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            margin: EdgeInsets.only(
              bottom: ScreenSize.screenHeight! * 0.05,
              top: ScreenSize.screenHeight! * 0.1,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  spacing: ScreenSize.screenHeight! * 0.09,
                  children: [
                    _buildSplashLogo(),
                    _safetyCheck(splashController: controller),
                  ],
                ),
                _splashButton(splashController: controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplashLogo() {
    return Container(
      alignment: Alignment.center,
      width: ScreenSize.screenWidth! * 0.4,
      height: ScreenSize.screenHeight! * 0.2,
      decoration: BoxDecoration(
        color: AppColors.blueColor,
        borderRadius: BorderRadius.circular(ScreenSize.screenWidth! * 0.2),
        boxShadow: [
          BoxShadow(
            blurRadius: 3,
            color: AppColors.whiteColor,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        "Tariqi",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _safetyCheck({required SplashController splashController}) {
    return Obx(
      () => HandlingView(
        requestState: splashController.requestState.value,
        widget: Container(
          padding: EdgeInsets.symmetric(
            vertical: ScreenSize.screenHeight! * 0.01,
          ),
          margin: EdgeInsets.symmetric(
            horizontal: ScreenSize.screenWidth! * 0.12,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.whiteColor),

            borderRadius: BorderRadius.circular(ScreenSize.screenWidth! * 0.05),
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: ScreenSize.screenWidth! * 0.03,
            children: [
              Text(
                "Move with safety",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),

              Icon(Icons.check_circle_outline_sharp, size: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _splashButton({required SplashController splashController}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.screenWidth! * 0.12),
      child: MaterialButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ScreenSize.screenWidth! * 0.03),
        ),
        padding: EdgeInsets.symmetric(
          vertical: ScreenSize.screenHeight! * 0.012,
        ),
        color: AppColors.blueColor,
        onPressed: () {
          splashController.navigateToLoginScreen();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: ScreenSize.screenWidth! * 0.03,
          children: [
            Text(
              "Get Started",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            Icon(Icons.arrow_circle_right_outlined, size: 30),
          ],
        ),
      ),
    );
  }
}
