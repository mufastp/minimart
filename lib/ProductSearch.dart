import 'dart:convert';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:minimart/Details.dart';
import 'package:minimart/main.dart';

class ProductSearchPage extends StatelessWidget {
  final ProductSearchController controller = Get.put(ProductSearchController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Product',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller.searchController,
              onChanged: (value) => controller.searchProducts(value),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.products.isEmpty) {
                return Center(child: Text('No products found.'));
              }

              return ListView.builder(
                itemCount: controller.products.length,
                itemBuilder: (context, index) {
                  final product = controller.products[index];

                  return ListTile(
                    leading: Icon(Icons.shopping_bag),
                    title: Text(product.productName),
                    subtitle: Text(
                        '${Details.currency}${product.price} - ${product.unitName}'),
                    onTap: () {
                      Get.back(id: 1, result: product);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class CartItem {
  final int productId;
  final String productName;
  final String unitName;
  final String barcode;
  final double originalPrice;
  double price;
  double? discount;
  int quantity;
  int unitId;
  double tax_percentage;
  final String rateChangeAllowed;

  // Controllers (not sent across windows)
  late TextEditingController discountController;
  late TextEditingController priceController;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitName,
    required this.barcode,
    required this.originalPrice,
    required this.price,
    this.discount = 0.0,
    this.quantity = 1,
    required this.unitId,
    required this.tax_percentage,
    required this.rateChangeAllowed,
  }) {
    discountController =
        TextEditingController(text: discount!.toStringAsFixed(1));
    priceController = TextEditingController(text: price.toStringAsFixed(2));
  }

  double get total => price * quantity;

  // 🔹 Convert to Map (for JSON transfer)
  Map<String, dynamic> toJson() {
    return {
      "productId": productId,
      "productName": productName,
      "unitName": unitName,
      "barcode": barcode,
      "originalPrice": originalPrice,
      "price": price,
      "discount": discount,
      "quantity": quantity,
      "unitId": unitId,
      "tax_percentage": tax_percentage,
      "rateChangeAllowed": rateChangeAllowed,
    };
  }

  // 🔹 Recreate from Map (JSON → CartItem)
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json["productId"],
      productName: json["productName"],
      unitName: json["unitName"],
      barcode: json["barcode"],
      originalPrice: (json["originalPrice"] as num).toDouble(),
      price: (json["price"] as num).toDouble(),
      discount: (json["discount"] as num?)?.toDouble() ?? 0.0,
      quantity: json["quantity"] ?? 1,
      unitId: json["unitId"],
      tax_percentage: (json["tax_percentage"] as num).toDouble(),
      rateChangeAllowed: json["rateChangeAllowed"],
    );
  }
}

class CartController extends GetxController {
  final RxList<CartItem> cartItems = <CartItem>[].obs;

  var cardPayment = 0.0.obs;
  var cashPayment = 0.0.obs;
  var mobilePayment = 0.0.obs;
  var roundOff = 0.0.obs;
  final roundOffController = TextEditingController();
  RxString roundOffMessage = ''.obs;
  RxBool isAutoRoundOff = true.obs;

  @override
  void onInit() {
    super.onInit();
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

  void addToCart(Product product) {
    final existingItem = cartItems.firstWhereOrNull(
      (item) =>
          item.productId == product.productId &&
          item.unitName == product.unitName,
    );

    if (existingItem != null) {
      existingItem.quantity++;
    } else {
      cartItems.add(CartItem(
        productId: product.productId,
        productName: product.productName,
        unitName: product.unitName,
        barcode: product.barcode.toString(),
        price: product.price,
        unitId: product.unitId,
        tax_percentage: product.tax_percentage,
        rateChangeAllowed: product.rateChangeAllowed,
        originalPrice: product.price,
      ));
    }

    cartItems.refresh();
    sendCartToSecondWindow(needOpen: true);
  }

  void sendCartToSecondWindow({bool needOpen = false}) async {
    if (windowId != null) {
      final items = cartItems.map((e) => e.toJson()).toList();
      DesktopMultiWindow.invokeMethod(
          windowId!, "update_cart", jsonEncode(items));
    } else {
      if (needOpen) {
        openNewWindow();
        await Future.delayed(const Duration(seconds: 1));
        sendCartToSecondWindow();
      }
    }
  }

  void updatePrice(CartItem item, double newPrice,
      {bool updateControllerText = true}) {
    item.price = newPrice;
    if (updateControllerText) {
      item.priceController.text = newPrice.toStringAsFixed(2);
    }
    update(); // refresh UI
    sendCartToSecondWindow();
  }

  void updateDiscount(CartItem item, double discount,
      {bool updateControllerText = true}) {
    item.discount = discount;
    if (updateControllerText) {
      item.discountController.text = discount.toStringAsFixed(1);
    }
    update(); // refresh UI
    sendCartToSecondWindow();
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
    final roundedAmount = (grandTotal / actualStep).round() * actualStep;
    final diff = double.parse((roundedAmount - grandTotal).toStringAsFixed(2));
    roundOff.value = diff;
    roundOffController.text = diff.toStringAsFixed(2);
    updateRoundOffMessage();
    debugPrint('Auto Round-off Calculation:');
    debugPrint('Grand Total: ${grandTotal.toStringAsFixed(2)}');
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
    sendCartToSecondWindow();
  }

  void updateRoundOffMessage() {
    final storedRoundOffStr = Details().round_off;
    final step = double.tryParse(storedRoundOffStr ?? '')?.toInt() ?? 5;
    final actualStep = step / 100.0;
    roundOffMessage.value = isAutoRoundOff.value
        ? 'Auto Round-off: ${roundOff.value.toStringAsFixed(2)} (Nearest ${actualStep.toStringAsFixed(2)})'
        : 'Manual Round-off: ${roundOff.value.toStringAsFixed(2)}';
    sendCartToSecondWindow();
  }

  void removeFromCart(CartItem item) {
    cartItems.remove(item);
    sendCartToSecondWindow();
  }

  void increaseQuantity(CartItem item) {
    item.quantity++;
    cartItems.refresh();
    sendCartToSecondWindow();
  }

  void decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
      cartItems.refresh();
    } else {
      removeFromCart(item);
    }
    sendCartToSecondWindow();
  }

  double get totalAmountss => cartItems.fold(
        0,
        (sum, item) {
          double itemTotal = item.price * item.quantity;
          double discount = item.discount ?? 0.0;
          double discountedPrice = itemTotal - discount;

          // Use the dynamic tax percentage instead of fixed 6%
          double vat = discountedPrice * (item.tax_percentage / 100);

          return sum + discountedPrice + vat;
        },
      );

  double get totalPayment =>
      cardPayment.value + cashPayment.value + mobilePayment.value;

  double get remainingToPay => totalAmountss - totalPayment;

  void updateRoundOff(double value) {
    roundOff.value = value;
    roundOffController.text = value.toStringAsFixed(2);
  }

// In your CartController class, add these computed values
  double get subtotal => cartItems.fold(0, (sum, item) {
        double itemTotal = item.price * item.quantity;
        double discount = item.discount ?? 0.0;
        return sum + (itemTotal - discount);
      });
  double get totalDiscount =>
      cartItems.fold(0, (sum, item) => sum + (item.discount ?? 0.0));
  double get totalTax {
    double totalTax = 0;

    for (var item in cartItems) {
      double price = item.price * item.quantity;
      double discount = item.discount ?? 0.0;
      double discountedPrice = price - discount;

      // Calculate VAT for this item using the dynamic tax percentage
      double itemTax = (discountedPrice * (item.tax_percentage / 100));

      // Round to 2 decimal places to avoid floating point errors
      itemTax = double.parse(itemTax.toStringAsFixed(2));

      totalTax += itemTax;
    }

    // Round the final total to avoid floating point errors
    return double.parse(totalTax.toStringAsFixed(2));
  }

  double get grandTotal {
    return subtotal + totalTax + roundOff.value;
  }
  // double get grandTotal => subtotal - totalDiscount + totalTax;

  void clearCart() {
    cartItems.clear();
    roundOffController.clear();
    roundOffController.text = "0.00";
    cardPayment.value = 0.0;
    cashPayment.value = 0.0;
    mobilePayment.value = 0.0;
    roundOff.value = 0.0;
  }
}

class Product {
  final int productId;
  final String productName;
  final String? productCode;
  final int unitId;
  final String unitName;
  final double price;
  final double tax_percentage;
  final String? barcode;
  final String rateChangeAllowed; // Add this field

  Product({
    required this.productId,
    required this.productName,
    this.productCode,
    required this.unitId,
    required this.unitName,
    required this.price,
    required this.tax_percentage,
    this.barcode,
    required this.rateChangeAllowed, // Add this to constructor
  });
}

class ProductRepository {
  final String baseUrl = 'http://68.183.92.8:3699/api/product-search';

  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?store_id=${Details.storeId}&query=$query'),
      );

      print('API URL: ${response.request?.url}');
      print('API Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Case 1: Response is a list of products (regular search)
        if (decoded is List) {
          return decoded.map<Product>((item) {
            return Product(
              productId: item['product_id'] ?? 0,
              productName: item['product_name'] ?? '',
              productCode: item['product_code'],
              unitId: item['unit_id'] ?? 0,
              tax_percentage: _parseTaxPercentage(item['tax_percentage']),
              unitName: item['unit_name'] ?? '',
              price: _parsePrice(item['price']),
              barcode: item['barcode']?.toString(),
              rateChangeAllowed: item['rate_change_allowed'] ?? 'NO',
            );
          }).toList();
        }

        // Case 2: Response is a map with barcode data (barcode search)
        else if (decoded is Map && decoded['type'] == 'barcode') {
          final data = decoded['data'];
          return [
            Product(
              productId: data['product_id'] ?? 0,
              productName: data['product_name'] ?? '',
              productCode: data['product_code'],
              unitId: data['unit_id'] ?? 0,
              tax_percentage: _parseTaxPercentage(data['tax_percentage']),
              unitName: data['unit_name'] ?? '',
              price: _parsePrice(data['price']),
              barcode: data['barcode']?.toString(),
              rateChangeAllowed: data['rate_change_allowed'] ?? 'NO',
            )
          ];
        }

        // Case 3: Response is a map but not barcode type
        else if (decoded is Map &&
            decoded.containsKey('data') &&
            decoded['data'] is Map) {
          final data = decoded['data'];
          return [
            Product(
              productId: data['product_id'] ?? 0,
              productName: data['product_name'] ?? '',
              productCode: data['product_code'],
              unitId: data['unit_id'] ?? 0,
              tax_percentage: _parseTaxPercentage(data['tax_percentage']),
              unitName: data['unit_name'] ?? '',
              price: _parsePrice(data['price']),
              barcode: data['barcode']?.toString(),
              rateChangeAllowed: data['rate_change_allowed'] ?? 'NO',
            )
          ];
        }

        return [];
      } else if (response.statusCode == 404) {
        final decoded = json.decode(response.body);
        if (decoded['message'] == "No results found") {
          throw Exception("No results found");
        } else {
          throw Exception("Unexpected error: ${decoded['message']}");
        }
      } else {
        throw Exception(
            "Failed to load products. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print('Error in searchProducts: $e');
      throw Exception("Error: $e");
    }
  }

  // Helper method to parse tax percentage
  double _parseTaxPercentage(dynamic taxValue) {
    if (taxValue == null) return 0.0;
    if (taxValue is double) return taxValue;
    if (taxValue is int) return taxValue.toDouble();
    if (taxValue is String) {
      return double.tryParse(taxValue) ?? 0.0;
    }
    return 0.0;
  }

  // Helper method to parse price
  double _parsePrice(dynamic priceValue) {
    if (priceValue == null) return 0.0;
    if (priceValue is double) return priceValue;
    if (priceValue is int) return priceValue.toDouble();
    if (priceValue is String) {
      return double.tryParse(priceValue) ?? 0.0;
    }
    return 0.0;
  }
}

class ProductSearchController extends GetxController {
  final searchController = TextEditingController();
  final products = <Product>[].obs;
  final isLoading = false.obs;
  final ProductRepository _repository = ProductRepository();
  final FocusNode searchFocusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (searchFocusNode.context != null &&
            searchFocusNode.context!.mounted) {
          searchFocusNode.requestFocus();
        }
      });
    });
    setCurrencyOnSecondWindow();
  }

  void setCurrencyOnSecondWindow() async {
    if (windowId != null) {
      DesktopMultiWindow.invokeMethod(
          windowId!, "set_currency", Details.currency ?? "");
    } else {
      // openNewWindow();
      // await Future.delayed(const Duration(seconds: 1));
      setCurrencyOnSecondWindow();
    }
  }

  Future<void> searchProducts(
    String query, {
    bool isScanned = false,
    FocusNode? searchFocusNode,
  }) async {
    query = query.trim().replaceAll('\n', '').replaceAll('\r', '');

    if (query.isEmpty) {
      products.clear();
      return;
    }

    isLoading.value = true;
    print('Searching for: "$query"');

    try {
      final result = await _repository.searchProducts(query);
      print('Found ${result.length} products');

      products.value = result;

      // Only auto-add to cart if it's a barcode scan AND we found exactly one product
      if (isScanned && products.length == 1) {
        final product = products.first;
        final cartController = Get.find<CartController>();
        cartController.addToCart(product);

        Get.snackbar(
          'Added',
          '${product.productName} added to cart',
          snackPosition: SnackPosition.BOTTOM,
        );

        searchController.clear();
        products.clear();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (searchFocusNode?.context != null &&
              searchFocusNode!.context!.mounted) {
            searchFocusNode.requestFocus();
          }
        });
      }
    } catch (e) {
      print('Error in search: $e');
      products.clear();
      Get.snackbar('Error', 'Failed to search products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }
}
