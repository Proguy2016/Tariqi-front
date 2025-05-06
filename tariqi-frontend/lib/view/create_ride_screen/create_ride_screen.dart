import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/const/functions/field_valid.dart';
import 'package:tariqi/const/routes/routes_names.dart';
import 'package:tariqi/controller/create_ride_controller/create_ride_controller.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';
import 'package:tariqi/view/core_widgets/ride_form_field.dart';
import 'package:tariqi/view/search_driver_screen/search_driver_screen.dart';
import 'package:tariqi/const/class/request_state.dart';

class CreateRideScreen extends StatelessWidget {
  const CreateRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateRideController());
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Get.offNamed(AppRoutesNames.homeScreen),
          child: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text("Create Ride"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ScreenSize.screenWidth! * 0.05,
                vertical: ScreenSize.screenHeight! * 0.02,
              ),
              child: _buildInputRideInfo(controller: controller, context: context),
            ),
            Expanded(
              child: Stack(
                children: [
                  _createRideMap(controller: controller),
                  Positioned(
                    bottom: 20,
                    left: ScreenSize.screenWidth! * 0.25,
                    right: ScreenSize.screenWidth! * 0.25,
                    child: _buildCreateButton(controller),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRideInfo({required CreateRideController controller, required BuildContext context}) {
    return Form(
      key: controller.formKey,
      child: Column(
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
            label: "Pick Point",
            enabled: false,
            submitFunction: (value) {},
            textEditingController: controller.pickPointController,
            hint: "Enter pickup point",
          ),
          SizedBox(height: ScreenSize.screenHeight! * 0.02),
          rideFormField(
            validate: (value) {
              return validFields(
                val: value!,
                type: "target",
                fieldName: "Target Point",
                minVal: 1,
                maxVal: 350,
              );
            },
            label: "Target Point",
            submitFunction: (value) =>
                controller.getTargetLocation(location: value),
            textEditingController: controller.targetPointController,
            hint: "Enter Target point",
          ),
          SizedBox(height: ScreenSize.screenHeight! * 0.02),
          // Arrival Time Field
          Obx(() => InkWell(
              onTap: () => _showTimePicker(context, controller),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.selectedArrivalTime.value.isEmpty
                          ? "Select Arrival Time"
                          : "Arrive by: ${controller.selectedArrivalTime.value}",
                      style: TextStyle(
                        color: controller.selectedArrivalTime.value.isEmpty
                            ? Colors.grey.shade600
                            : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(Icons.access_time, color: Colors.grey),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context, CreateRideController controller) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.blackColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      // Format the time
      final hour = pickedTime.hour.toString().padLeft(2, '0');
      final minute = pickedTime.minute.toString().padLeft(2, '0');
      controller.selectedArrivalTime.value = '$hour:$minute';
      controller.setArrivalTime(pickedTime);
    }
  }

  Widget _createRideMap({required CreateRideController controller}) {
    return Obx(() {
      return FlutterMap(
        mapController: controller.mapController,
        options: MapOptions(
          onTap: (tapPosition, point) => controller.assignMarkers(point: point),
          initialCenter: controller.userPosition != null
              ? LatLng(
                  controller.userPosition!.latitude,
                  controller.userPosition!.longitude,
                )
              : const LatLng(0, 0), // Provide default coordinates if null
          initialZoom: 12.0,
        ),
        children: [
          HandlingView(
            requestState: controller.requestState.value,
            widget: TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
          ),
          MarkerLayer(markers: controller.markers),
          RichAttributionWidget(
            alignment: AttributionAlignment.bottomLeft,
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
              LogoSourceAttribution(
                Icon(
                  Icons.location_searching_outlined,
                  color: AppColors.blackColor,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildCreateButton(CreateRideController controller) {
    return Obx(() => MaterialButton(
          padding: EdgeInsets.symmetric(
            vertical: ScreenSize.screenHeight! * 0.01,
          ),
          color: AppColors.blackColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          onPressed: controller.requestState.value == RequestState.loading ||
                   controller.selectedArrivalTime.value.isEmpty
              ? null
              : () => controller.createRide(),
          child: controller.requestState.value == RequestState.loading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  "Start",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ));
  }
}