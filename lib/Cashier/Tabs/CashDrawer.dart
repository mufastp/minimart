import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../Details.dart';

class CashDrawer extends StatelessWidget {
  CashDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CashDrawerController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchPaymentSummary();
      controller.checkOpenRegister();
      controller.fetchCashDrawers();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: GetBuilder<CashDrawerController>(
        builder: (_) => SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20.h),
              if (!_.isRegisterOpen)
                _buildOpenShiftUI(context, _)
              else
                _buildEndShiftUI(context, _),
              SizedBox(height: 20.h),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_.isRegisterOpen) {
                      _.closeRegister();
                    } else {
                      _.openRegister();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    backgroundColor: Colors.lightGreenAccent,
                    minimumSize: Size(150.w, 70.h),
                  ),
                  child: Text(
                    _.isRegisterOpen ? "End Shift" : "Start Shift",
                    style: TextStyle(fontSize: 8.sp),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpenShiftUI(BuildContext context, CashDrawerController _) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Drawer Amount Summary",
                style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.bold),
              ),
              Obx(() => DropdownButton<int>(
                value: _.selectedDrawerId.value,
                hint: Text("Select Drawer", style: TextStyle(fontSize: 8.sp)),
                items: _.drawerList.map<DropdownMenuItem<int>>((drawer) {
                  return DropdownMenuItem<int>(
                    value: drawer['id'],
                    child: Text(drawer['code'], style: TextStyle(fontSize: 8.sp)),
                  );
                }).toList(),
                onChanged: (value) {
                  _.selectedDrawerId.value = value;
                },
              )),
            ],
          ),
        ),
        Center(
          child: Container(
            padding: EdgeInsets.all(16.w),
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r)
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Opening Cash", style: TextStyle(fontSize: 8.sp)),
                    SizedBox(
                      width: 100.w,
                      child: TextField(
                        controller: _.openingAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Amount",
                          hintStyle: TextStyle(fontSize: 8.sp),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEndShiftUI(BuildContext context, CashDrawerController _) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Text(
            "Cash Register: ${_.cashRegisterMaster?['code'] ?? 'N/A'}",
            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Text(
            "Current Shift Opened at: ${_.registerData?['opened_at'] != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(
                DateTime.parse(_.registerData!['opened_at']).toLocal())
                : ''}",
            style: TextStyle(fontSize: 8.sp),
          ),
        ),
        Center(
          child: Container(
            padding: EdgeInsets.all(16.w),
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              children: [
                _buildEditableRow("Opening Cash", _.openingAmountController),
                _buildEditableRow("Sales Cash", TextEditingController(text: _.cash.value.toStringAsFixed(2))),
                _buildEditableRow("Sales Card", TextEditingController(text: _.card.value.toStringAsFixed(2))),
                _buildEditableRow("Sales QR", TextEditingController(text: _.qr.value.toStringAsFixed(2))),
                _buildEditableRow("Expenses", _.expensesController),
                _buildEditableRow("Refund", _.refundController),
                _buildEditableRow("Difference", _.differenceController),
                _buildEditableRow("Closing Amount", "${_.total.toStringAsFixed(2)}"),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: TextField(
                    controller: _.remarksController,
                    decoration: InputDecoration(
                      hintText: "Enter Counter Closure Remarks.",
                      hintStyle: TextStyle(fontSize: 8.sp),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableRow(String title, dynamic input) {
    final controller = input is TextEditingController
        ? input
        : TextEditingController(text: input.toString());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: TextStyle(fontSize: 8.sp))),
          SizedBox(
            width: 100.w,
            child: TextField(
              controller: controller,
              readOnly: true,
              textAlign: TextAlign.right, // Add this line to right-align text
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ],
      ),
    );
  }
}


class CashDrawerController extends GetxController {
  var cash = 0.0.obs;
  var card = 0.0.obs;
  var qr = 0.0.obs;
  double get total => cash.value + card.value + qr.value;
  var isRegisterOpen = false;
  var registerData;
  int? registerId;
  final remarksController = TextEditingController();
  final openingAmountController = TextEditingController();
  final expensesController = TextEditingController(text: "0.00");
  final refundController = TextEditingController(text: "0.00");
  final differenceController = TextEditingController(text: "0.00");
  final closingAmountController = TextEditingController();
  var drawerList = [].obs;
  var selectedDrawerId = Rxn<int>();
  final storeId = Details.storeId;
  final userId = Details.userId;
  Map<String, dynamic>? cashRegisterMaster;


  @override
  void onInit() {
    super.onInit();
    fetchPaymentSummary();
    checkOpenRegister();
    fetchCashDrawers();
  }

  Future<void> fetchPaymentSummary() async {
    final response = await http.get(
      Uri.parse('http://68.183.92.8:3699/api/goodsout-payment-summary?store_id=$storeId&cash_registers_id=${Details.registerId}'),
      // headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      print(response.request);
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) {
        final data = jsonData['data'];
        cash.value = (data['CASH'] ?? 0).toDouble();
        card.value = (data['CARD'] ?? 0).toDouble();
        qr.value = (data['QR'] ?? 0).toDouble();
      }
    }
  }

  Future<void> checkOpenRegister() async {
    try {
      final response = await http.get(
        Uri.parse('http://68.183.92.8:3699/api/cash-register/open/$userId'),
      );

      print(response.body);
      if (response.statusCode == 200) {
        final _box = GetStorage();
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true) {
          isRegisterOpen = true;
          registerData = jsonData['data'];
          cashRegisterMaster = jsonData['cashRegisterMaster']; // ✅ Store master data
          registerId = registerData?['id'];

          if (isRegisterOpen) {
            registerData = jsonData['data'];
            registerId = registerData?['id'];
            final cashregId = registerData?['register_id'];
            _box.write('registerId', registerId);
            _box.write('cashregId', cashregId);
            openingAmountController.text = registerData?['opening_amount']?.toString() ?? '';
          } else {
            registerData = null;
            registerId = null;
            openingAmountController.clear();
          }
        } else {
          isRegisterOpen = false;
          registerData = null;
          registerId = null;
          cashRegisterMaster = null;
        }
      } else {
        isRegisterOpen = false;
        registerData = null;
        registerId = null;
        cashRegisterMaster = null;
      }
      update();
    } catch (e) {
      isRegisterOpen = false;
      registerData = null;
      registerId = null;
      cashRegisterMaster = null;
      update();
    }
  }


  Future<void> fetchCashDrawers() async {
    try {
      final response = await http.get(
        Uri.parse('http://68.183.92.8:3699/api/get-cash-register?store_id=$storeId'),
        // headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        print(response.request);
        print(response.body);
        final jsonData = jsonDecode(response.body);
        if (jsonData['success']) {
          drawerList.value = jsonData['data'];
          if (drawerList.isNotEmpty) {
            selectedDrawerId.value = drawerList.first['id'];
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> openRegister() async {
    final openingAmount = openingAmountController.text.trim();
    final _box = GetStorage();

    final body = {
      "store_id": storeId,
      "user_id": userId,
      "register_id": selectedDrawerId.value ?? 0,
      "opening_amount": double.tryParse(openingAmount) ?? 0.0,
    };

    final response = await http.post(
      Uri.parse('http://68.183.92.8:3699/api/cash-register/open'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    print("Cashier Open Body: $body");
    print("Cashier Open Response: ${response.body}");

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      print(response.body);
      if (jsonData['success'] == true) {
        // ✅ Store printer IP for later usage
        if (drawerList.isNotEmpty) {
          final selectedDrawer = drawerList.firstWhere(
                (drawer) => drawer['id'] == selectedDrawerId.value,
            orElse: () => drawerList.first,
          );
          final printerIp = selectedDrawer['printer'] ?? '';

          _box.write('printerIp', printerIp);
          print("✅ Stored Printer IP: $printerIp");
        }

        openingAmountController.clear();
        await checkOpenRegister();
        fetchPaymentSummary();
        Get.snackbar("Success", "Shift Opened Successfully");
      } else {
        Get.snackbar("Error", jsonData['message'] ?? "Failed to open shift");
      }
    } else {
      Get.snackbar("Error", "Failed to open shift");
    }
  }


  Future<void> closeRegister() async {
    if (registerId == null) {
      Get.snackbar("Error", "No active register found!");
      return;
    }

    // final closingAmount = closingAmountController.text.trim();
    //
    // if (closingAmount.isEmpty) {
    //   Get.snackbar("Validation Error", "Please enter closing amount");
    //   return;
    // }

    final body = {
      "closing_amount": double.tryParse("$total") ?? 0.0,
      "system_sales_cash": cash.value,
      "system_sales_card": card.value,
      "system_sales_qr": qr.value,
      "total_expenses": double.tryParse(expensesController.text) ?? 0.0,
      "total_refunds": double.tryParse(refundController.text) ?? 0.0,
      "difference": double.tryParse(differenceController.text) ?? 0.0,
      "notes": remarksController.text,
    };

    final response = await http.post(
      Uri.parse('http://68.183.92.8:3699/api/cash-register/close/$registerId'),
      headers: {
        // 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
print("total:$total");
    print(body);
    if (response.statusCode == 200) {
      print(response.body);
      openingAmountController.clear();
      remarksController.clear();
      await checkOpenRegister();
      fetchPaymentSummary();
      Get.snackbar("Success", "Shift Closed Successfully");
    } else {
      Get.snackbar("Error", "Failed to close shift");
    }
  }
}


