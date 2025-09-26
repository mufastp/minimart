import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:minimart/CheckOut.dart';
import 'package:minimart/Details.dart';
import 'package:flutter/material.dart';

class OrdersPage extends StatelessWidget {
  final OrdersController controller = Get.put(OrdersController());
  final ScrollController scrollController = ScrollController();

  OrdersPage({super.key}) {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 150) {
        if (!controller.isMoreLoading.value) {
          controller.fetchOrders(isFirstLoad: false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Orders", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Printer Settings Icon
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () => controller.showPrinterSettings(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '${Details.userName![0].toUpperCase()}${Details.userName!.substring(1)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.orders.isEmpty) {
          return const Center(child: Text("No orders found"));
        }

        return ListView.builder(
          controller: scrollController,
          itemCount: controller.orders.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.orders.length) {
              return controller.isMoreLoading.value
                  ? const Padding(
                padding: EdgeInsets.all(10),
                child: Center(child: CircularProgressIndicator()),
              )
                  : const SizedBox.shrink();
            }

            final order = controller.orders[index];
            final bool isExpanded = controller.expandedIndex.value == index;

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ExpansionTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                trailing: SizedBox.shrink(),
                backgroundColor: Colors.white,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: order.invoiceNo!,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${order.invoiceNo!} | ${DateFormat('dd MMMM yyyy').format(DateTime.parse(order.inDate!))} ${order.inTime}',
                            style: TextStyle(
                              fontSize: 8.sp,
                            ),
                          ),
                          SizedBox(
                            width: 14,
                          ),
                          Text(
                            order.status == 0
                                ? "Cancelled"
                                : order.status == 1
                                ? "Confirmed"
                                : "",
                            style: TextStyle(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w400,
                              color: order.status == 0
                                  ? Colors.red
                                  : order.status == 1
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          order.customer?.code ?? '',  // ✅ Safe access
                          style: TextStyle(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (order.customer?.code != null && order.customer!.code!.isNotEmpty)
                          Text(' | '),
                        Expanded(
                          child: Text(
                            order.customer?.name ?? '', // ✅ Safe access
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        (order.detail!.isNotEmpty)
                            ? Text(
                          'Total: ${order.total?.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 8.sp),
                        )
                            : Text(
                          'Type:  ',
                          style: TextStyle(
                            fontSize: 8.sp,
                          ),
                        ),
                        order.discount_type == '0'
                            ? Text(
                          'Discount : ${order.discount?.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 8.sp,
                          ),
                        )
                            : order.discount_type == '1'
                            ? Text(
                          'Discount(%): ${order.discount?.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 8.sp,
                          ),
                        )
                            : SizedBox.shrink(),
                        Spacer(),
                        InkWell(
                          onTap: () {
                            print(Details.printerIp);
                            print(order.id);
                            controller.printOrder(order.id!);
                          },
                          child: Icon(
                            Icons.print,
                            color: Colors.blue,
                            size: 30.sp,
                          ),
                        ),
                        SizedBox(
                          width: 10.w,
                        ),
                      ],
                    ),
                    Text(
                      'Total Vat: ${(order.total_tax)}',
                      style: TextStyle(
                        fontSize: 8.sp,
                      ),
                    ),
                    Text(
                      'Grand Total: ${order.grandTotal?.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 8.sp,
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        Divider(
                          color: Colors.grey.shade400,
                        ),
                        for (int i = 0; i < order.detail!.length; i++)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 200.w,
                                child: Text(
                                  ('${order.detail![i].code ?? ''} | ${order.detail![i].name ?? ''}')
                                      .toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 8.sp, fontWeight: FontWeight.w400),
                                ),
                              ),
                              SizedBox(
                                width: 200.w,
                                child: Row(
                                  children: [
                                    Text(
                                      order.detail![i].product_type ?? '',
                                      style: TextStyle(fontSize: 8.sp),
                                    ),
                                    const Text(' | '),
                                    Text(
                                      order.detail![i].unit ?? '',
                                      style: TextStyle(fontSize: 8.sp),
                                    ),
                                    const Text(' | '),
                                    Text(
                                      'Qty: ${order.detail![i].quantity}',
                                      style: TextStyle(fontSize: 8.sp),
                                    ),
                                    const Text(' | '),
                                    Text(
                                      'Vat: ${order.detail![i].taxamt}',
                                      style: TextStyle(
                                        fontSize: 8.sp,
                                      ),
                                    ),
                                    const Text(' | '),
                                    Text(
                                      'Price: ${order.detail![i].mrp}',
                                      style: TextStyle(
                                        fontSize: 8.sp,
                                      ),
                                    ),
                                    const Text(' | '),
                                    Text(
                                      'Amount: ${order.detail![i].amount?.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 8.sp,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              (i == order.detail!.length - 1)
                                  ? Container()
                                  : Divider(color: Colors.grey.shade400),
                            ],
                          ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

class OrdersController extends GetxController {
  var isLoading = false.obs;
  var isMoreLoading = false.obs;
  var orders = <OrderModel>[].obs;
  var page = 1.obs;
  var hasMoreData = true.obs;
  var expandedIndex = (-1).obs;

  var printers = <CashRegister>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCashRegisters();
    fetchOrders(isFirstLoad: true);
  }

  Future<void> fetchOrders({bool isFirstLoad = true}) async {
    try {
      if (isFirstLoad) {
        isLoading.value = true;
        page.value = 1;
        hasMoreData.value = true;
      } else {
        if (!hasMoreData.value) return;
        isMoreLoading.value = true;
      }

      final url = Uri.parse(
          "http://68.183.92.8:3699/api/vansale.pos.index?store_id=${Details.storeId}&user_id=${Details.userId}&van_id=0&page=${page.value}");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print(response.request);
        final data = json.decode(response.body);
        if (data["success"] == true) {
          List<dynamic> orderList = data["data"]["data"];
          var fetchedOrders =
          orderList.map((json) => OrderModel.fromJson(json)).toList();

          if (isFirstLoad) {
            orders.value = fetchedOrders;
          } else {
            orders.addAll(fetchedOrders);
          }

          hasMoreData.value = fetchedOrders.isNotEmpty;
          if (hasMoreData.value) page.value++;
        } else {
          Get.snackbar("Error", "Failed to fetch orders");
        }
      } else {
        Get.snackbar("Error", "Something went wrong: ${response.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
      print(e);
    } finally {
      if (isFirstLoad) {
        isLoading.value = false;
      } else {
        isMoreLoading.value = false;
      }
    }
  }

  Future<void> fetchCashRegisters() async {
    try {
      final url = Uri.parse(
          "http://68.183.92.8:3699/api/get-cash-register?store_id=${Details.storeId}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print(response.request);
        final data = json.decode(response.body);
        if (data["success"] == true) {
          printers.value = (data["data"] as List)
              .map((json) => CashRegister.fromJson(json))
              .toList();
        } else {
          Get.snackbar("Error", "No cash registers found");
        }
      } else {
        Get.snackbar("Error", "Failed to fetch printers");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  Future<void> printOrder(int orderId) async {
    try {
      isLoading.value = true;

      // Verify printer connection first
      final _box = GetStorage();
      final printerIp = _box.read('printerIp') ?? '';

      if (printerIp.isEmpty) {
        Get.snackbar("Error", "No printer IP found. Please open a register first.");
        return;
      }

      // Test printer connection before fetching order details
      final isPrinterConnected = await _testPrinterConnection(printerIp);
      if (!isPrinterConnected) {
        Get.snackbar("Printer Error", "Cannot connect to printer at $printerIp");
        return;
      }

      // Fetch order details
      final orderResponse = await http.get(
        Uri.parse("http://68.183.92.8:3699/api/get_sales_invoice?id=$orderId"),
      ).timeout(const Duration(seconds: 30));

      if (orderResponse.statusCode == 200) {
        final orderData = json.decode(orderResponse.body);
        if (orderData["success"] == true) {
          final completeOrder = OrderModel.fromJson(orderData["data"]);
          await _printInvoiceOnDesktop(completeOrder, printerIp);
          Get.snackbar("Success", "Order printed successfully");
        } else {
          Get.snackbar("Error", "Failed to fetch order details");
        }
      } else {
        Get.snackbar("Error", "Failed to fetch order details: ${orderResponse.statusCode}");
      }
    } on SocketException catch (e) {
      Get.snackbar("Network Error", "Cannot connect to server: ${e.message}");
    } on TimeoutException catch (e) {
      Get.snackbar("Timeout Error", "Request timed out: ${e.message}");
    } catch (e) {
      print("Error printing order: $e");
      Get.snackbar("Error", "Failed to print order: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void showPrinterSettings() {
    final printerIp = GetStorage().read('printerIp') ?? '';

    Get.dialog(
      AlertDialog(
        title: Text("Printer Settings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Current Printer: ${printerIp.isNotEmpty ? printerIp : 'Not set'}"),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (printerIp.isEmpty) {
                  Get.snackbar("Error", "No printer IP configured");
                  return;
                }
                final result = await _testPrinterConnection(printerIp);
                Get.snackbar(
                    result ? "Success" : "Error",
                    result ? "Printer connected successfully" : "Cannot connect to printer"
                );
              },
              child: Text("Test Printer Connection"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<bool> _testPrinterConnection(String printerIp) async {
    try {
      final socket = await Socket.connect(printerIp, 9100)
          .timeout(const Duration(seconds: 5));
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _printInvoiceOnDesktop(OrderModel invoice, String printerIp) async {
    try {
      final socket = await Socket.connect(printerIp, 9100)
          .timeout(const Duration(seconds: 10));
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);

      final List<int> bytes = [];

      // ---------------- HEADER ----------------
      bytes.addAll(generator.text('${invoice.store?.first.name ?? "Store"}',
          styles: const PosStyles(
              align: PosAlign.center, bold: true, height: PosTextSize.size2)));
      bytes.addAll(generator.text('Invoice #: ${invoice.invoiceNo}',
          styles: const PosStyles(align: PosAlign.center, bold: true)));
      bytes.addAll(generator.text('Date: ${invoice.inDate} ${invoice.inTime}'));
      bytes.addAll(generator.text('Customer: ${invoice.customer?.name ?? "Unknown"}'));
      bytes.addAll(generator.text('Phone: ${invoice.customer?.contactNumber ?? "N/A"}'));
      bytes.addAll(generator.text('-' * 48));

      // ---------------- TABLE HEADER ----------------
      bytes.addAll(generator.row([
        PosColumn(text: 'Item', width: 4),
        PosColumn(text: 'Qty', width: 1),
        PosColumn(text: 'Unit', width: 1),
        PosColumn(text: 'Price', width: 3),
        PosColumn(text: 'Amount', width: 3),
      ]));
      bytes.addAll(generator.text('-' * 48));

      // ---------------- ORDER ITEMS ----------------
      int counter = 0;
      for (var item in invoice.detail ?? []) {
        bytes.addAll(generator.row([
          PosColumn(text: item.name ?? 'N/A', width: 4),
          PosColumn(text: '${item.quantity}', width: 1),
          PosColumn(text: item.unit ?? '', width: 1),
          PosColumn(text: '${item.price?.toStringAsFixed(2)}', width: 3),
          PosColumn(text: '${item.amount?.toStringAsFixed(2)}', width: 3),
        ]));

        counter++;

        // ✅ Feed after every 50 items to prevent skipping lines
        if (counter % 50 == 0) {
          bytes.addAll(generator.feed(1));
        }
      }

      bytes.addAll(generator.text('-' * 48));

      // ---------------- TOTALS ----------------
      bytes.addAll(generator.row([
        PosColumn(text: 'Sub Total:', width: 6),
        PosColumn(
            text: '${invoice.total?.toStringAsFixed(2)}',
            width: 6,
            styles: PosStyles(align: PosAlign.right)),
      ]));

      if (invoice.discount != null && invoice.discount! > 0) {
        bytes.addAll(generator.row([
          PosColumn(text: 'Discount:', width: 6),
          PosColumn(
              text: '${invoice.discount?.toStringAsFixed(2)}',
              width: 6,
              styles: PosStyles(align: PosAlign.right)),
        ]));
      }

      if (invoice.total_tax != null && invoice.total_tax! > 0) {
        bytes.addAll(generator.row([
          PosColumn(text: 'Tax:', width: 6),
          PosColumn(
              text: '${invoice.total_tax?.toStringAsFixed(2)}',
              width: 6,
              styles: PosStyles(align: PosAlign.right)),
        ]));
      }

      bytes.addAll(generator.row([
        PosColumn(
            text: 'Grand Total:',
            width: 6,
            styles: PosStyles(bold: true)),
        PosColumn(
            text: '${invoice.grandTotal?.toStringAsFixed(2)}',
            width: 6,
            styles: PosStyles(align: PosAlign.right, bold: true)),
      ]));

      bytes.addAll(generator.text('Payment Mode: ${invoice.billMode}'));
      bytes.addAll(generator.text('Status: ${invoice.paymentStatus}'));

      if (invoice.remarks != null && invoice.remarks!.isNotEmpty) {
        bytes.addAll(generator.text('Remarks: ${invoice.remarks}'));
      }

      bytes.addAll(generator.feed(2));
      bytes.addAll(generator.text('Thank you for your business!',
          styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(generator.feed(2));
      bytes.addAll(generator.cut());

      // ---------------- SEND DATA TO PRINTER IN CHUNKS ----------------
      const int chunkSize = 4096;
      for (int i = 0; i < bytes.length; i += chunkSize) {
        int end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        socket.add(bytes.sublist(i, end));
        await socket.flush();
        await Future.delayed(const Duration(milliseconds: 50)); // give printer time to process
      }

      await socket.close();
    } catch (e) {
      if (e is SocketException) {
        Get.snackbar("Printer Error", "Cannot connect to printer at $printerIp");
      } else if (e is TimeoutException) {
        Get.snackbar("Printer Error", "Connection timeout to printer");
      } else {
        Get.snackbar("Printer Error", e.toString());
      }
      print("Printer Error: $e");
    }
  }

  void toggleExpanded(int index, bool expanded) {
    expandedIndex.value = expanded ? index : -1;
  }
}


class OrderModel {
  int? id;
  int? status;
  double? total;
  double? discount;
  String? invoiceNo;
  String? discount_type;
  String? inDate;
  String? inTime;
  String? remarks;
  double? grandTotal;
  final String? billMode;
  final String? paymentStatus;
  double? total_tax;
  String? round_off;
  final List<Store>? store;
  Customer? customer;
  List<OrderDetail>? detail;

  OrderModel({
    this.id,
    this.status,
    this.total,
    this.discount,
    this.invoiceNo,
    this.discount_type,
    this.inDate,
    this.inTime,
    this.remarks,
    this.grandTotal,
    this.billMode,
    this.paymentStatus,
    this.total_tax,
    this.round_off,
    this.store,
    this.customer,
    this.detail,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      status: json['status'] ?? 0,
      total: (json['total'] != null && json['total'] is num)
          ? (json['total'] as num).toDouble()
          : 0.0,
      discount: (json['discount'] != null && json['discount'] is num)
          ? (json['discount'] as num).toDouble()
          : 0.0,
      invoiceNo: json['invoice_no'] ?? "",
      discount_type: json['discount_type'] ?? "",
      inDate: json['in_date'] ?? "",
      inTime: json['in_time'] ?? "",
      remarks: json['remarks'] ?? "",
      grandTotal: (json['grand_total'] != null && json['grand_total'] is num)
          ? (json['grand_total'] as num).toDouble()
          : 0.0,
      billMode: json['bill_mode'],
      paymentStatus: json['payment_status'],
      total_tax: (json['total_tax'] != null && json['total_tax'] is num)
          ? (json['total_tax'] as num).toDouble()
          : 0.0,
      round_off: json['round_off']?.toString() ?? "0",
      customer: (json['customer'] != null && json['customer'] is List && json['customer'].isNotEmpty)
          ? Customer.fromJson(json['customer'][0])
          : (json['customer'] != null && json['customer'] is Map)
          ? Customer.fromJson(json['customer'])
          : null,
      detail: (json['detail'] is List)
          ? (json['detail'] as List<dynamic>)
          .map((item) => OrderDetail.fromJson(item))
          .toList()
          : [],
    );
  }
}

class Store {
  final String? name;
  final String? contactNumber;

  Store({this.name, this.contactNumber});

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      name: json['name'],
      contactNumber: json['contact_number'],
    );
  }
}

class OrderDetail {
  int? id;
  String? name;
  String? unit;
  String? product_type;
  String? code;
  int? quantity;
  int? taxable;
  double? taxamt;
  double? mrp;
  double? price;
  double? amount;

  OrderDetail({
    this.id,
    this.name,
    this.unit,
    this.quantity,
    this.taxable,
    this.taxamt,
    this.mrp,
    this.price,
    this.amount,
    this.product_type,
    this.code,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      unit: json['unit'] ?? "",
      product_type: json['product_type'] ?? "",
      code: json['code'] ?? "",
      taxamt: (json['tax_amt'] != null && json['tax_amt'] is num)
          ? (json['tax_amt'] as num).toDouble()
          : 0.0,

      quantity: json['quantity'] != null
          ? (json['quantity'] is int
          ? json['quantity'] as int
          : (json['quantity'] as num).toInt())
          : 0,
      taxable: json['taxable'] != null
          ? (json['taxable'] is int
          ? json['taxable'] as int
          : (json['taxable'] as num).toInt())
          : 0,
      mrp: (json['mrp'] != null && json['mrp'] is num)
          ? (json['mrp'] as num).toDouble()
          : 0.0,
      price: (json['price'] != null && json['price'] is num)
          ? (json['price'] as num).toDouble()
          : 0.0,
      amount: (json['amount'] != null && json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : 0.0,
    );
  }
}



class Customer {
  int? id;
  String? name;
  String? code;
  String? contactNumber;

  Customer({this.id, this.name, this.contactNumber, this.code});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      code: json['code'] ?? "",
      contactNumber: json['contact_number'] ?? "",
    );
  }
}
class CashRegister {
  final int id;
  final String code;
  final String description;
  final String printer;
  final int status;
  final int userId;
  final int storeId;
  final String createdAt;
  final String updatedAt;

  CashRegister({
    required this.id,
    required this.code,
    required this.description,
    required this.printer,
    required this.status,
    required this.userId,
    required this.storeId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CashRegister.fromJson(Map<String, dynamic> json) {
    return CashRegister(
      id: json["id"] ?? 0,
      code: json["code"] ?? "",
      description: json["description"] ?? "",
      printer: json["printer"] ?? "",
      status: json["status"] ?? 0,
      userId: json["user_id"] ?? 0,
      storeId: json["store_id"] ?? 0,
      createdAt: json["created_at"] ?? "",
      updatedAt: json["updated_at"] ?? "",
    );
  }
}