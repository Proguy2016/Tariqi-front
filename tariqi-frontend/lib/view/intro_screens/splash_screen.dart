import 'package:flutter/material.dart';
import 'package:get/get_core/get_core.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/controller/intro_controller/splash_controller.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';
import 'dart:ui';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final controller = Get.put(SplashController());
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
          ),
          // Gradient overlay for better contrast
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.45),
                  Colors.transparent,
                  Colors.black.withOpacity(0.25),
                ],
                stops: [0.0, 0.5, 1.0],
            ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Logo and app name centered together
                Center(
                  child: Column(
                  children: [
                      Container(
                        width: ScreenSize.screenWidth! * 0.22,
                        height: ScreenSize.screenWidth! * 0.22,
      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Image.asset(
                            'assets/images/logo.webp',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Tariqi',
                        style: TextStyle(
                          fontSize: 68,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Color(0xFF2979FF).withOpacity(0.7), // blue neon
                              blurRadius: 24,
          ),
                            Shadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Get Started Button (as is, but with more bottom margin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 36.0),
                  child: SizedBox(
                    width: ScreenSize.screenWidth! * 0.8,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blueColor,
                        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
        ),
                        elevation: 10,
                        shadowColor: AppColors.blueColor.withOpacity(0.4),
        ),
        onPressed: () {
                        controller.navigateToLoginScreen();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
            Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
            ),
                          SizedBox(width: 16),
                          Icon(
                            Icons.arrow_circle_right_outlined,
                            size: 32,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
          ),
        ],
      ),
    );
  }
}
