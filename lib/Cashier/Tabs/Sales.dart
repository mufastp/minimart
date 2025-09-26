import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SalesController extends GetxController {
  var fromDate = DateTime.now().subtract(const Duration(days: 7)).obs;
  var toDate = DateTime.now().obs;
  var isLoading = false.obs;
  var register = {}.obs;
  var goodsOut = [].obs;

  Future<void> pickDate({required bool isFrom}) async {
    DateTime initial = isFrom ? fromDate.value : toDate.value;
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (isFrom) {
        fromDate.value = picked;
      } else {
        toDate.value = picked;
      }
      fetchSales();
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> fetchSales() async {
    try {
      isLoading(true);
      final url =
          "http://68.183.92.8:2696/api/sales-by-date-range/${GetStorage().read('registerId')}?from_date=${formatDate(fromDate.value)}&to_date=${formatDate(toDate.value)}";
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        register.value = data['register'] ?? {};
        goodsOut.value = data['goods_out'] ?? [];
      } else {
        Get.snackbar("Error", "Failed to load sales data");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  @override
  void onInit() {
    fetchSales();
    super.onInit();
  }
}


class SalesTab extends StatelessWidget {
  final SalesController controller = Get.put(SalesController());

  SalesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date pickers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _dateSelector("From", controller.fromDate.value,
                        () => controller.pickDate(isFrom: true)),
                _dateSelector("To", controller.toDate.value,
                        () => controller.pickDate(isFrom: false)),
              ],
            ),
            const SizedBox(height: 20),

            // Summary Boxes
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _dataBox("Opening Amount", controller.register['opening_amount'].toStringAsFixed(2) ?? 0.00),
                _dataBox("Closing Amount", controller.register['closing_amount'].toStringAsFixed(2) ?? 0.00),
                _dataBox("Cash Sales", controller.register['system_sales_cash'].toStringAsFixed(2) ?? 0.00),
                _dataBox("Card Sales", controller.register['system_sales_card'].toStringAsFixed(2) ?? 0.00),
                _dataBox("QR Sales", controller.register['system_sales_qr'].toStringAsFixed(2) ?? 0.00),
                _dataBox("Expenses", controller.register['total_expenses'].toStringAsFixed(2) ?? 0.00),
                _dataBox("Refunds", controller.register['total_refunds'].toStringAsFixed(2) ?? 0.00),
              ],
            ),

            const SizedBox(height: 20),

            // Sales Table
            Container(
              width: MediaQuery.of(context).size.width * .9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Table(
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade200),
                      children: [
                        _tableHeaderCell("Order Id"),
                        _tableHeaderCell("Type"),
                        _tableHeaderCell("Time"),
                        _tableHeaderCell("Order Total"),
                        _tableHeaderCell("Payment Mode"),
                      ],
                    ),
                    for (var sale in controller.goodsOut)
                      TableRow(
                        decoration: BoxDecoration(
                          color: controller.goodsOut.indexOf(sale) % 2 == 0
                              ? Colors.white
                              : Colors.grey.shade200,
                        ),
                        children: [
                          _tableDataCell(sale['invoice_no'] ?? ""),
                          _tableDataCell(sale['order_type'] ?? ""),
                          _tableDataCell(sale['in_time'] ?? ""),
                          _tableDataCell('\$ ${sale['grand_total']}'),
                          _tableDataCell(sale['payments'] != null && sale['payments'].isNotEmpty
                              ? sale['payments'][0]['payment_method']
                              : ""),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Date picker widget
  Widget _dateSelector(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              "$label: ${date.toString().split(' ')[0]}",
              style: TextStyle(fontSize: 8.sp),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
      ),
    );
  }

  /// Data box
  Widget _dataBox(String title, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(title, style: TextStyle(fontSize: 8.sp),),
        ),
        Container(
          width: 120,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "\$ ${value.toString()}",
              style: TextStyle(fontSize: 8.sp),
            ),
          ),
        ),
      ],
    );
  }

  /// Table header cell
  Widget _tableHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  /// Table data cell
  Widget _tableDataCell(String value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(child: Text(value)),
    );
  }
}
