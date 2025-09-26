import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class TodaySale extends StatelessWidget {
  const TodaySale({super.key});

  Future<Map<String, dynamic>> fetchShiftData() async {
    final response = await http.get(
      Uri.parse("http://68.183.92.8:2696/api/cash-registers/${GetStorage().read('registerId')}/end-shift-report"),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return jsonData['data'];
    } else {
      throw Exception('Failed to load shift data');
    }
  }

  Future<Map<String, dynamic>> fetchTodaySales() async {
    final response = await http.get(
      Uri.parse("http://68.183.92.8:2696/api/today-sales-report/${GetStorage().read('registerId')}"),
    );

    if (response.statusCode == 200) {
      print(response.request);
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load today sales data');
    }
  }

  @override
  Widget build(BuildContext context) {
    ScrollController _scrollController = ScrollController();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: FutureBuilder<Map<String, dynamic>>(
        future: Future.wait([fetchShiftData(), fetchTodaySales()]).then((list) {
          return {
            'shift_data': list[0],
            'today_sales': list[1],
          };
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final shift = snapshot.data!['shift_data']['shift_info'];
          final others = snapshot.data!['shift_data']['other_totals'];
          final todaySales = snapshot.data!['today_sales'];
          final goodsOut = todaySales['goods_out'] as List<dynamic>;
          String formatOrderType(String orderType) {
            switch (orderType) {
              case 'dine_in':
                return 'Dine In';
              case 'take_away':
                return 'Take Away';
              case 'delivery':
                return 'Delivery';
              default:
                return orderType; // fallback for unexpected values
            }
          }
          return Scrollbar(
            controller: _scrollController,
            trackVisibility: true,
            thumbVisibility: true,
            thickness: 10.sp,
            radius: Radius.circular(10.r),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    SizedBox(height: 10.h),

                    /// Shift Info Fields
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: [
                        _dataBox("Opening Cash", shift["opening_amount"]),
                        _dataBox("Sales Cash", shift["system_sales_cash"]),
                        _dataBox("Sales Card", shift["system_sales_card"]),
                        _dataBox("Sales QR", shift["system_sales_qr"]),
                        _dataBox("Expenses", shift["total_expenses"]),
                        _dataBox("Refund", shift["total_refunds"]),
                        _dataBox("Closing Cash", shift["closing_amount"] ?? "0.00"),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    /// Sale History Section
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sale History",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 20.h),
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
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                      ),
                                      children: [
                                        _tableHeaderCell("Order Id"),
                                        _tableHeaderCell("Type"),
                                        _tableHeaderCell("Time"),
                                        _tableHeaderCell("Order Total"),
                                        _tableHeaderCell("Payment Mode"),
                                      ],
                                    ),
                                    for (var sale in goodsOut)
                                      TableRow(
                                        decoration: BoxDecoration(
                                          color: goodsOut.indexOf(sale) % 2 == 0
                                              ? Colors.white
                                              : Colors.grey.shade200,
                                        ),
                                        children: [
                                          _tableDataCell(sale['invoice_no']),
                                          _tableDataCell(formatOrderType(sale['order_type'])),
                                          _tableDataCell(sale['in_time']),
                                          _tableDataCell('\$ ${sale['grand_total']}'),
                                          _tableDataCell(sale['payments'][0]['payment_method']),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Read-only data box widget
  Widget _dataBox(String title, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
          child: Text(
            title,
            style: TextStyle(fontSize: 8.sp),
          ),
        ),
        Container(
          width: 80.w,
          height: 60.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
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
        child: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Table data cell
  Widget _tableDataCell(String value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(value),
      ),
    );
  }
}