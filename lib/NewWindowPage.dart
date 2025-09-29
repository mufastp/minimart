import 'dart:convert';
import 'dart:developer';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:minimart/ProductSearch.dart';
import 'SelectedProductsWidget.dart';

class NewWindowPage extends StatefulWidget {
  @override
  State<NewWindowPage> createState() => _NewWindowPageState();
}

class _NewWindowPageState extends State<NewWindowPage> {
  final cartController = Get.put(CartController());
  String? currencySymbol;
  bool checkout = false;
        String? statusMessage;
  @override
  void initState() {
    super.initState();

    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == "update_cart") {
        checkout=false;
        final List<dynamic> data = jsonDecode(call.arguments);
        cartController.cartItems.value =
            data.map((e) => CartItem.fromJson(e)).toList();
        setState(() {});
      } else if (call.method == "set_currency") {
        log(call.arguments);
        currencySymbol = call.arguments;
        setState(() {});
      } else if (call.method == "go_to_checkout") {
        checkout = true;
        setState(() {});
        Map<String, dynamic> args =
            Map<String, dynamic>.from(jsonDecode(call.arguments));

        currencySymbol = args["currency"];
        statusMessage=args['statusMessage'];

        // Get.toNamed('/checkout', arguments: args);
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Selected Products - New Window'),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        if (cartController.cartItems.isEmpty) {
          return const Center(child: Icon(Icons.shopping_cart_sharp));
        } else {
          return Column(
            children: [
              Expanded(
                child: SelectedProductsWidget(
                  cartController: cartController,
                  currencySymbol: currencySymbol ?? "",
                  newwindow: true,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    checkout == true ? Text(statusMessage??"") : SizedBox(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Sub Total: (${cartController.cartItems.length} Item${cartController.cartItems.length > 1 ? 's' : ''})"),
                        Text(
                            "Total Discount: $currencySymbol${cartController.totalDiscount.toStringAsFixed(2)}"),
                        Text(
                            "VAT: $currencySymbol${cartController.totalTax.toStringAsFixed(2)}"),
                        Text(
                            "Total: $currencySymbol${cartController.grandTotal.toStringAsFixed(2)}",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              )
            ],
          );
        }
      }),
    );
  }
}
