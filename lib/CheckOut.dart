import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'Customers.dart';
import 'Details.dart';
import 'ProductSearch.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'orders.dart';

class PaymentMethod {
  final int id;
  final String name;
  final String type;

  PaymentMethod({required this.id, required this.name, required this.type});

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }
}

class PaymentController extends GetxController {
  var paymentMethods = <PaymentMethod>[].obs;
  var paymentAmounts = <int, double>{}.obs;
  var isLoading = true.obs;
  var roundOff = 0.0.obs;
  final roundOffController = TextEditingController();
  RxString roundOffMessage = ''.obs;
  RxBool isAutoRoundOff = true.obs;
  final CartController cartController = Get.find<CartController>();

  @override
  void onInit() {
    super.onInit();
    fetchPaymentMethods();
    roundOffController.text = '';
    applyAutoRoundOffFromStorage();
    // updateTotalPaid();
    roundOffController.addListener(() {
      if (roundOffController.text.isNotEmpty) {
        isAutoRoundOff.value = false;
        roundOff.value = double.tryParse(roundOffController.text) ?? 0.0;
      }
      // updateTotalPaid();
    });
    roundOff.listen((_) {
      // updateTotalPaid();
      updateRoundOffMessage();
    });
    roundOffController.text = roundOff.value.toStringAsFixed(2);
  }


  void applyAutoRoundOffFromStorage() {
    final storedRoundOffStr = Details().round_off;
    debugPrint("Stored round-off value: $storedRoundOffStr");
    final step = double.tryParse(storedRoundOffStr ?? '')?.toInt() ?? 5;
    debugPrint("Parsed step value: $step");
    if (step <= 0) {
      roundOff.value = 0.0;
      roundOffController.text = '';
      return;
    }
    final actualStep = step / 100.0;
    debugPrint("Actual step used for rounding: $actualStep");
    final roundedAmount = (cartController.grandTotal / actualStep).round() * actualStep;
    final diff = double.parse((roundedAmount - cartController.grandTotal).toStringAsFixed(2));
    roundOff.value = diff;
    roundOffController.text = diff.toStringAsFixed(2);
    updateRoundOffMessage();
    debugPrint('Auto Round-off Calculation:');
    debugPrint('Grand Total: ${cartController.grandTotal.toStringAsFixed(2)}');
    debugPrint('Rounded Amount: ${roundedAmount.toStringAsFixed(2)}');
    debugPrint('Difference: ${diff.toStringAsFixed(2)}');
  }
  void toggleAutoRoundOff(bool value) {
    isAutoRoundOff.value = value;
    if (value) {
      applyAutoRoundOffFromStorage();
    } else {
      // When switching to manual mode, keep current value but make editable
      roundOffController.text = roundOff.value.toStringAsFixed(2);
    }
  }

  void updateRoundOffMessage() {
    final storedRoundOffStr = Details().round_off;
    final step = double.tryParse(storedRoundOffStr ?? '')?.toInt() ?? 5;
    final actualStep = step / 100.0;
    roundOffMessage.value = isAutoRoundOff.value
        ? 'Auto Round-off: ${roundOff.value.toStringAsFixed(2)} (Nearest ${actualStep.toStringAsFixed(2)})'
        : 'Manual Round-off: ${roundOff.value.toStringAsFixed(2)}';
  }

  Future<void> fetchPaymentMethods() async {
    try {
      isLoading.value = true;
      final response = await http.get(Uri.parse(
          "http://68.183.92.8:3699/api/payment-methods?store_id=${Details.storeId}"));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        paymentMethods.value =
            data.map((e) => PaymentMethod.fromJson(e)).toList();
        for (var method in paymentMethods) {
          paymentAmounts[method.id] = 0.0;
        }
      } else {
        Get.snackbar("Error", "Failed to load payment methods");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Prepare Final Payment Payload
  List<Map<String, dynamic>> preparePayments() {
    return paymentAmounts.entries
        .where((entry) => entry.value > 0)
        .map((entry) =>
    {
      "payment_method_id": entry.key,
      "amount": entry.value,
    })
        .toList();
  }



  /// Submit Checkout API
  Future<void> submitCheckout({
    int? customerId,
    required List<CartItem> cartItems,
    required double totalAmount,
    required double grandTotal,
    required double totalDiscount,
    required double totalTax,
    required String remarks,
    required double roundOff,
  }) async {
    final CartController cartController = Get.put(CartController());
    final OrdersController ordersController = Get.put(OrdersController());

    // Prepare Product-wise Data
    final List<int> productIds = cartItems.map((item) => item.productId ?? 0)
        .toList();
    final List<int> quantities = cartItems.map((item) => item.quantity ?? 0)
        .toList();
    final List<int> unitIds = cartItems.map((item) => item.unitId ?? 0)
        .toList();
    final List<double> mrps = cartItems.map((item) => item.price ?? 0.0)
        .toList();

    final dynamic totalTaxes = cartItems.length == 1 ? 0.0 : cartItems.map((
        item) => 0.0).toList();
    final dynamic totals = cartItems.length == 1
        ? cartItems[0].total ?? 0.0
        : cartItems.map((item) => item.total ?? 0.0).toList();
    final dynamic discounts = cartItems.length == 1 ? 0.0 : cartItems.map((
        item) => 0.0).toList();

    final List<Map<String, dynamic>> payments = preparePayments();

    final data = {
      'van_id': 1,
      'store_id': Details.storeId,
      'user_id': Details.userId,
      'item_id': productIds,
      'quantity': quantities,
      'unit': unitIds,
      'mrp': mrps,
      'discount_type': 'percentage',
      'cash_registers_id': Details.registerId,
      'cash_register_master_id': Details.cashregId,
      'customer_id': customerId ?? 0,
      'if_vat': 1,
      'product_type': [1],
      'total_tax': totalTax,
      'discount': totalDiscount,
      'total': totals,
      'round_off': roundOff,
      'grand_total': grandTotal.toStringAsFixed(2),
      'remarks': remarks,
      'payments': payments,
    };

    try {
      final response = await http.post(
        Uri.parse("http://68.183.92.8:3699/api/vansale.pos.store"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      print('📤 Request Body: ${jsonEncode(data)}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final int orderId = responseData["data"]["id"];
        cartItems.clear();
        cartController.clearCart();
        paymentAmounts.clear();
        Get.defaultDialog(
          title: "Payment Successful 🎉",
          middleText: "Do you want to print the receipt?",
          textCancel: "No",
          textConfirm: "Print",
          confirmTextColor: Colors.white,
          onConfirm: () async {
            Get.back();
            await ordersController.printOrder(orderId);
          },
          onCancel: () {
            Get.back(); // Close the dialog
            Get.offNamed('/home', id: 1); // Navigate to home
          },
        );
      } else {
        Get.snackbar('Error', 'Failed to submit the payment. Try again.');
      }
    } catch (e) {
      print("❌ ERROR: $e");
      Get.snackbar('Exception', e.toString());
    }
  }
}

class CheckoutPage extends StatelessWidget {
  final CartController cartController = Get.find<CartController>();
  final CustomerController customerController = Get.put(CustomerController());
  final PaymentController paymentController = Get.put(PaymentController());
  // Add these variables to store the passed values
  double get subtotal => cartController.subtotal;
  double get totalDiscount => cartController.totalDiscount;
  double get totalTax => cartController.totalTax;
  // double get grandTotal => cartController.grandTotal;
  double get finalTotal => cartController.grandTotal + paymentController.roundOff.value;


  CheckoutPage({super.key}); // Remove the argument parsing
  @override
  Widget build(BuildContext context) {
    paymentController.fetchPaymentMethods();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurpleAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (customerController.isLoading.value || paymentController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// LEFT PANEL
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      title: "Customer Information",
                      child: Column(
                        children: [
                          Autocomplete<Customerss>(
                            optionsBuilder: (TextEditingValue value) {
                              if (value.text.isEmpty) return customerController.customers;
                              return customerController.customers.where((c) =>
                              c.name.toLowerCase().contains(value.text.toLowerCase()) ||
                                  c.code.toLowerCase().contains(value.text.toLowerCase()));
                            },
                            displayStringForOption: (c) => '${c.name}',
                            onSelected: (selected) =>
                            customerController.selectedCustomer.value = selected,
                            fieldViewBuilder: (context, controller, focusNode, _) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Select customer',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 14.h),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 8.h),
                          _buildTextField("Full Name"),
                          SizedBox(height: 8.h),
                          _buildTextField("Phone Number"),
                          SizedBox(height: 8.h),
                          _buildTextField("Loyalty Card Number (Optional)"),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    _buildSectionCard(
                      title: "Order Items (${cartController.cartItems.length})",
                      child: SizedBox(
                        height: 160.h,
                        child: Scrollbar(
                          child: ListView.builder(
                            itemCount: cartController.cartItems.length,
                            itemBuilder: (context, index) {
                              final item = cartController.cartItems[index];
                              // FIXED: Calculate correct total with discount and tax
                              double price = item.price * item.quantity;
                              double discount = item.discount ?? 0.0;
                              double discountedPrice = price - discount;
                              double vat = discountedPrice * (item.tax_percentage / 100);
                              double total = discountedPrice + vat;

                              return ListTile(
                                dense: true,
                                title: Text(item.productName),
                                trailing: Text(
                                  "${item.quantity} x ${Details.currency}${item.price.toStringAsFixed(2)} = ${Details.currency}${total.toStringAsFixed(2)}",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    _buildSectionCard(
                      title: "Order Notes (Optional)",
                      child: TextField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add any special notes...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 20.w),

              /// RIGHT PANEL
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildSectionCard(
                      title: "Order Total",
                      child: Column(
                        children: [
                          _buildTotalRow("Subtotal", subtotal),
                          _buildTotalRow("Discount", -totalDiscount),
                          _buildTotalRow("Tax (6%)", totalTax),
                          _buildRoundOffField(), // Add this line
                          Divider(),
                          _buildTotalRow("Total", finalTotal, highlight: true, bold: true),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildSectionCard(
                      title: "Payment Method",
                      child: Obx(() {
                        return Column(
                          children: paymentController.paymentMethods.map((method) {
                            return _buildRadioPaymentMethod(
                              method.name,
                              _getPaymentIcon(method.type),
                              method.id,
                            );
                          }).toList(),
                        );
                      }),
                    ),
                    SizedBox(height: 24.h),
                    _buildCheckoutButton(),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 12.h),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildRadioPaymentMethod(String title, IconData icon, int methodId) {
    return Row(
      children: [
        Icon(icon),
        SizedBox(width: 8.w),
        Expanded(child: Text(title)),
        SizedBox(
          width: 100.w,
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              paymentController.paymentAmounts[methodId] = amount;
            },
            decoration: InputDecoration(
              hintText: 'Amount',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              contentPadding:
              EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getPaymentIcon(String type) {
    switch (type.toLowerCase()) {
      case "card":
        return Icons.credit_card;
      case "cash":
        return Icons.money;
      case "qr":
        return Icons.qr_code_2;
      case "mobile":
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  Widget _buildCheckoutButton() {
    return Obx(() {
      double paid = paymentController.paymentAmounts.values.fold(0.0, (a, b) => a + b);
      // double total = cartController.totalAmountss;
      double total = finalTotal;
      double remaining = total - paid;
      String statusMessage;
      Color statusColor;
      if (remaining > 0) {
        statusMessage = "Remaining: ${Details.currency}${remaining.toStringAsFixed(2)}";
        statusColor = Colors.red;
      } else if (remaining < 0) {
        statusMessage = "Cash Change: ${Details.currency}${remaining.abs().toStringAsFixed(2)}";
        statusColor = Colors.green;
      } else {
        statusMessage = "Exact Amount Paid";
        statusColor = Colors.blue;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              fixedSize: Size(200.w, 80.h),
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: remaining <= 0.01 ? () async {
              try {
                final response = await GetConnect().get(
                  "http://68.183.92.8:3699/api/cash-register/open/${Details.userId}",
                );

                if (response.statusCode == 200 && response.body['success'] == true) {
                  print(response.request);
                  // box.write('key', value)
                  print(cartController.totalDiscount);
                  print(cartController.totalTax);
                  await paymentController.submitCheckout(
                    totalDiscount: cartController.totalDiscount,
                    totalTax: cartController.totalTax,
                    customerId: customerController.selectedCustomer.value?.id ?? 0,
                    remarks: 'Delivered successfully',
                    cartItems: cartController.cartItems,
                    totalAmount: cartController.totalAmountss,
                    grandTotal: finalTotal,
                    roundOff: paymentController.roundOff.value,
                  );
                } else {
                  Get.dialog(
                    AlertDialog(
                      title: const Text("Cashier Closed"),
                      content: const Text(
                        "Please open the cashier section before processing the payment.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                Get.dialog(
                  AlertDialog(
                    title: const Text("Network Error"),
                    content: Text("Something went wrong: $e"),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              }
            }
                : null,
            icon: const Icon(Icons.check, color: Colors.white),
            label: Text(
              'Process Payment • ${Details.currency}${total.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            statusMessage,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTotalRow(String label, double amount,
      {bool bold = false, bool highlight = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('${Details.currency}${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: highlight ? Colors.green : null,
              )),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
    );
  }

  Widget _buildRoundOffField() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Round Off", style: TextStyle(fontSize: 10.sp)),
          SizedBox(
            width: 100.w,
            child: Obx(() {
              return TextField(
                controller: paymentController.roundOffController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                readOnly: paymentController.isAutoRoundOff.value,
                decoration: InputDecoration(
                  labelText: 'Round Off',
                  labelStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.rounded_corner, size: 20),
                  hintText: paymentController.isAutoRoundOff.value
                      ? 'Auto calculated: ${paymentController.roundOff.value.toStringAsFixed(2)}'
                      : 'Enter amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    paymentController.roundOff.value = double.tryParse(value) ?? 0.0;
                  }
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}