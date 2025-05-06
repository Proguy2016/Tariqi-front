import 'package:get/get.dart';

class SuccessRideController extends GetxController {
  String pickPoint = "";
  String targetPoint = "";
  double positionLat = 0.0;
  double positionLong = 0.0;

  initialServices() {
    pickPoint = Get.arguments["pick_point"];
    targetPoint = Get.arguments["target_point"];
  }

  @override
  void onInit() {
    initialServices();
    super.onInit();
  }
}