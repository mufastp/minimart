// lib/core/dependency_injection.dart
import 'package:get/get.dart';
import 'package:minimart/Customers.dart';

import 'DashBoard.dart';
import 'ProductSearch.dart';

class DependencyInjection {
  static void init() {
    Get.lazyPut(() => DashboardController(), fenix: true);
    Get.lazyPut(() => ProductSearchController(), fenix: true);
    Get.lazyPut(() => CustomerController(), fenix: true);
    Get.lazyPut(() => ProductRepository(), fenix: true);
  }
}