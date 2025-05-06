import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:tariqi/const/routes/routes_names.dart';
import 'package:tariqi/view/auth_screens/login_screen.dart';
import 'package:tariqi/view/auth_screens/signup_screen.dart';
import 'package:tariqi/view/create_ride_screen/create_ride_screen.dart';
import 'package:tariqi/view/home_screen/home_screen.dart';
import 'package:tariqi/view/intro_screens/splash_screen.dart';
import 'package:tariqi/view/success_screen/success_create_ride.dart';
import 'package:tariqi/view/search_driver_screen/search_driver_screen.dart';
import 'package:tariqi/view/driver/driver_active_ride_screen.dart';
import 'package:tariqi/view/driver/driver_home_screen.dart';
/// This file defines the application's route configuration using the GetX package.
///
/// It imports necessary screens and middleware, and sets up a list of `GetPage`
/// objects, each representing a route in the application. Each route is associated
/// with a specific screen and, optionally, middleware for handling route-specific
/// logic.
///
/// The routes include:
/// - SplashScreen with middleware for initial loading.
/// - LoginScreen for user authentication.
/// - SignupScreen for new user registration.
/// - HomePage as the main application screen.

List<GetPage<dynamic>> routes = [
  GetPage(
    name: AppRoutesNames.splashScreen,
    page: () => SplashScreen(),
    // middlewares: [SplashMiddleware()],
  ),
  GetPage(name: AppRoutesNames.loginScreen, page: () => LoginScreen()),
  GetPage(name: AppRoutesNames.signupScreen, page: () => SignupScreen()),
  GetPage(name: AppRoutesNames.homeScreen, page: () => HomeScreen()),
  GetPage(name: AppRoutesNames.createRideScreen, page: () => CreateRideScreen()),
  GetPage(name: AppRoutesNames.successCreateRide, page: () => SearchDriverScreen()),
  GetPage(
  name: AppRoutesNames.driverHomeScreen,
  page: () => const DriverHomeScreen(),
),
GetPage(
  name: AppRoutesNames.driverActiveRideScreen,
  page: () => const DriverActiveRideScreen(),
),
];
