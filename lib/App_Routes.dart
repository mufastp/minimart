// lib/routes/AppRoutes/App_Routes.dart
import 'package:get/get.dart';
import 'package:minimart/CheckOut.dart';
import 'package:minimart/Login.dart';

import 'DashBoard.dart';
import 'Home.dart';
import 'ProductSearch.dart';
import 'NewWindowPage.dart';

class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String productSearch = '/productsearch';
  static const String checkOut = '/checkout';
  static const String newWindow = '/newwindow';

  static final routes = [
    GetPage(name: login, page: () => LoginPage()),
    GetPage(
      name: initial,
      page: () => DashboardPage(),
    ),
    GetPage(
      name: home,
      page: () => HomePage(),
    ),
    GetPage(
      name: productSearch,
      page: () => ProductSearchPage(),
      transition: Transition.rightToLeft, // optional
    ),
    GetPage(
      name: checkOut,
      page: () => CheckoutPage(),
      transition: Transition.rightToLeft, // optional
    ),
    GetPage(
      name: newWindow,
      page: () => NewWindowPage(),
    ),
    // Add other routes as needed
  ];
}