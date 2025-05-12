import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:latlong2/latlong.dart';
import 'package:tariqi/const/class/screen_size.dart';
import 'package:tariqi/const/colors/app_colors.dart';
import 'package:tariqi/controller/home_controller/home_controller.dart';
import 'package:tariqi/view/core_widgets/handling_view.dart';

Widget mapView({required HomeController homeController}) => Container(
  height: ScreenSize.screenHeight! * 0.87,
  padding: EdgeInsets.symmetric(horizontal: ScreenSize.screenWidth! * 0.02),
  child: Stack(
    children: [
      FlutterMap(
        key: ValueKey(homeController.requestState.value),
        mapController: homeController.mapController,
        options: MapOptions(
          onTap:
              (tapPosition, point) =>
                  homeController.assignMarkers(point: point),
          initialCenter: LatLng(
            homeController.userPosition.latitude,
            homeController.userPosition.longitude,
          ), // Center User Position If Permission Granted
          initialZoom: 16.0, // Zoom level
        ),

        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          Obx(
            () => HandlingView(
              requestState: homeController.requestState.value,
              widget: MarkerLayer(markers: homeController.markers),
            ),
          ),

          RichAttributionWidget(
            alignment: AttributionAlignment.bottomLeft,
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
              LogoSourceAttribution(
                Icon(
                  Icons.location_searching_outlined,
                  color: AppColors.blackColor,
                ),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    ],
  ),
);
