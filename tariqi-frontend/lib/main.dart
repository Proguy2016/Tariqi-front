import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tariqi/const/routes/routes.dart';
import 'package:tariqi/controller/auth_controllers/auth_controller.dart';
import 'package:tariqi/services/driver_service.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
  final authController = Get.put(AuthController());
  Get.put(DriverService(), permanent: true);
  await authController.loadToken();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark(),
      getPages: routes,
    );
  }
}
