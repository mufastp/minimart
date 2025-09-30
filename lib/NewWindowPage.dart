import 'dart:convert';
import 'dart:developer';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:minimart/CheckOut.dart';
import 'package:minimart/Details.dart';
import 'package:minimart/ProductSearch.dart';
import 'SelectedProductsWidget.dart';

class NewWindowPage extends StatefulWidget {
  @override
  State<NewWindowPage> createState() => _NewWindowPageState();
}

class _NewWindowPageState extends State<NewWindowPage> {
  final cartController = Get.put(CartController());
  final paymentController = Get.put(PaymentController());

  List<PaymentMethodAmountMapper> mapper = [];
  double get paidAmount => mapper.fold(
        0,
        (previousValue, element) => previousValue + element.amount,
      );
  double get remaining => cartController.grandTotal - paidAmount;

  String? currencySymbol;
  @override
  void initState() {
    super.initState();

    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == "update_cart") {
        final List<dynamic> data = jsonDecode(call.arguments);
        cartController.cartItems.value =
            data.map((e) => CartItem.fromJson(e)).toList();
      } else if (call.method == "set_currency") {
        log(call.arguments);
        currencySymbol = call.arguments;
        setState(() {});
      } else if (call.method == "confirm_checkout") {
        final List<dynamic> data = jsonDecode(call.arguments);
        List<PaymentMethodAmountMapper> payments =
            data.map((e) => PaymentMethodAmountMapper.fromJson(e)).toList();
        mapper = payments;
        setState(() {});
      }
//    else if (call.method == "go_to_checkout") {
//    Map<String, dynamic> args = Map<String, dynamic>.from(jsonDecode(call.arguments));
// args["currency"] = currencySymbol;

// Get.toNamed('/checkout', arguments: args);

//   }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
  final String? currency = (Details.currency?.isNotEmpty ?? false)
        ? Details.currency!
        : currencySymbol;
    String statusMessage;
    Color statusColor;
    if (remaining > 0) {
      statusMessage =
          "Remaining: $currency${remaining.toStringAsFixed(2)}";
      statusColor = Colors.red;
    } else if (remaining < 0) {
      statusMessage =
          "Cash Change: $currency${remaining.abs().toStringAsFixed(2)}";
      statusColor = Colors.green;
    } else {
      statusMessage = "Exact Amount Paid";
      statusColor = Colors.blue;
    }

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
                  currencySymbol: currency ?? "",
                  newwindow: true,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        if(mapper.isNotEmpty)...[
                         ... List.generate(mapper.length,(index) => Text(
                          "${mapper[index].name}-$currency ${mapper[index].amount}",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ), ),
                          
                           Text(
                          statusMessage,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        )
                        ]
                       
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Sub Total: (${cartController.cartItems.length} Item${cartController.cartItems.length > 1 ? 's' : ''})"),
                        Text(
                            "Total Discount: $currency${cartController.totalDiscount.toStringAsFixed(2)}"),
                        Text(
                            "VAT: $currency${cartController.totalTax.toStringAsFixed(2)}"),
                        Text(
                            "Total: $currency${cartController.grandTotal.toStringAsFixed(2)}",
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
