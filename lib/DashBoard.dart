import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:minimart/Cashier/Cashier.dart';
import 'package:minimart/CheckOut.dart';
import 'package:minimart/Details.dart';
import 'package:minimart/ProductSearch.dart';
import 'App_Routes.dart';
import 'Cashier/Tabs/CashDrawer.dart';
import 'Customer.dart';
import 'Home.dart';
import 'package:get_storage/get_storage.dart';
import 'orders.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardController extends GetxController with GetSingleTickerProviderStateMixin {
  var tabIndex = 0.obs;
  late TabController tabController;
  final box = GetStorage();
  final OrdersController ordersController = Get.put(OrdersController());
  final CartController cartController = Get.put(CartController());
  // final CashDrawerController cashDrawerController = Get.put(CashDrawerController());

  @override
  void onInit() {
    super.onInit();
    print("UserId: ${Details.userId}");
    print("StoreId: ${Details.storeId}");
    tabController = TabController(length: 8, vsync: this);
    tabController.addListener(_handleTabSelection);
    Future.delayed(Duration(milliseconds: 300), () {
      checkCashierStatus();
    });
  }

  Future<void> checkCashierStatus() async {
    try {
      final url = Uri.parse("http://68.183.92.8:3699/api/cash-register/open/${Details.userId}");
      print("🔹 Checking cashier status for: ${Details.userId}");
      print("🔹 API URL: $url");

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          // 'Authorization': 'Bearer ${Details().token}', // ✅ Added token
        },
      );

      print("🔹 Response Status: ${response.statusCode}");
      print("🔹 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // ✅ Cashier already open
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          print("✅ Cashier is open, dashboard ready!");
        }
      }
      else if (response.statusCode == 404) {
        // ❌ Cashier not opened yet
        final data = jsonDecode(response.body);
        _showOpenCashierDialog(data["message"] ?? "You need to open the cashier before proceeding.");
      }
      else {
        // 🔴 Other errors
        Get.snackbar(
          "Error",
          "Failed to check cashier status (Code: ${response.statusCode})",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("❌ Exception while checking cashier status: $e");
      Get.snackbar(
        "Error",
        "Something went wrong: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }



  void _showOpenCashierDialog(String message) {
    Get.defaultDialog(
      title: "Open Cashier",
      middleText: message,
      barrierDismissible: false, // ✅ Cannot close the dialog without action
      textConfirm: "Ok",
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        // Get.to(() => Cashier()); // ✅ Navigate to cashier opening page
      },
    );
  }


  void _handleTabSelection() {
    if (tabController.indexIsChanging) {
      int newIndex = tabController.index;
      if (newIndex == 7) {
        logout();
      } else {
        tabIndex.value = newIndex;
        update();
      }
    }
  }

  void changeTabIndex(int index) {
    if (index == 6) {
      logout();
    } else {
      tabIndex.value = index;
      tabController.animateTo(index);
      if (index == 0) {
        Get.toNamed('/home', id: 1);
      } else if (index == 1) {
        Get.toNamed('/customer', id: 1);
      } else if (index == 2) {
        if (Get.isRegistered<CashDrawerController>()) {
          Get.delete<CashDrawerController>(force: true);
        }
        Get.put(CashDrawerController());
        Get.toNamed('/cashier', id: 1);
      } else if (index == 3) {
        ordersController.fetchOrders();
        ordersController.fetchCashRegisters();
        Get.toNamed('/orders', id: 1);
      }
      update();
    }
  }

  void logout() {
    Get.defaultDialog(
      title: 'Logout',
      middleText: 'Are you sure you want to logout?',
      textCancel: 'Cancel',
      textConfirm: 'Logout',
      confirmTextColor: Colors.white,
      onConfirm: () {
        final box = GetStorage();
        final savedPrinterIp = box.read('printerIp');
        box.erase();
        if (savedPrinterIp != null) {
          box.write('printerIp', savedPrinterIp);
        }
        cartController.cartItems.clear();
        Get.offAllNamed(AppRoutes.login);
      },
    );
  }


  @override
  void onClose() {
    tabController.removeListener(_handleTabSelection);
    tabController.dispose();
    super.onClose();
  }
}



class DashboardPage extends StatelessWidget {
  final DashboardController controller = Get.put(DashboardController(), permanent: true);
  final CartController cartController = Get.put(CartController(), permanent: true);
  DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Obx(() => NavigationRail(
              backgroundColor: Colors.black87,
              indicatorColor: Colors.lightBlueAccent,
              selectedIndex: controller.tabIndex.value,
              onDestinationSelected: controller.changeTabIndex,
              labelType: NavigationRailLabelType.selected,
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              minWidth: 60.w,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home, color: Colors.white),
                  label: Text('Home', style: TextStyle(color: Colors.white)),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people, color: Colors.white),
                  label: Text('Customers', style: TextStyle(color: Colors.white)),
                ),
                // NavigationRailDestination(
                //   icon: Icon(Icons.table_bar, color: Colors.white),
                //   label: Text('Tables', style: TextStyle(color: Colors.white)),
                // ),
                NavigationRailDestination(
                  icon: Icon(Icons.point_of_sale, color: Colors.white),
                  label: Text('Cashier', style: TextStyle(color: Colors.white)),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.shopping_basket, color: Colors.white),
                  label: Text('Orders', style: TextStyle(color: Colors.white)),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics, color: Colors.white),
                  label: Text('Reports', style: TextStyle(color: Colors.white)),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings, color: Colors.white),
                  label: Text('Settings', style: TextStyle(color: Colors.white)),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.logout, color: Colors.white),
                  label: Text('Logout', style: TextStyle(color: Colors.white)),
                ),
              ],
            )),
            Expanded(
              child: Navigator(
                key: Get.nestedKey(1),
                initialRoute: '/selection',
                onGenerateRoute: (settings) {
                  Widget page;
                  switch (settings.name) {
                    case '/home':
                      page = HomePage();
                      break;
                    case '/productsearch':
                      page = ProductSearchPage();
                      break;
                    case '/checkout':
                      page = CheckoutPage();
                      break;
                    case '/orders':
                      page = OrdersPage();
                      break;
                    case '/cashier':
                      page = Cashier();
                      case '/customer':
                      page = CustomerPage();
                    default:
                      page = HomePage();
                  }
                  return MaterialPageRoute(builder: (_) => page, settings: settings);
                },

              ),
            ),
          ],
        ),
      ),
    );
  }
}