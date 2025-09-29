import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:minimart/Details.dart';
import 'ProductSearch.dart';

class SelectedProductsWidget extends StatelessWidget {
  final CartController cartController;
  final String currencySymbol;
  final bool newwindow;

  const SelectedProductsWidget({
    Key? key,
    required this.cartController,
    required this.currencySymbol,
    required this.newwindow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildSelectedProducts();
  }

  Widget _buildSelectedProducts() {
    return Obx(() {
      return ListView(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        children: [
          // Header Row - Removed Expanded widgets
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
            child: _buildHeaderRow(),
          ),
          Divider(thickness: 1, color: Colors.grey.shade300),
          ...cartController.cartItems
              .map((item) => _buildCartItemRow(item))
              .toList(),
        ],
      );
    });
  }

  Widget _buildHeaderRow() {
    return const Row(
      children: [
        Expanded(
            flex: 3,
            child:
                Text("Items", style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
            flex: 1,
            child: Center(
                child: Text("Rate",
                    style: TextStyle(fontWeight: FontWeight.bold)))),
        Expanded(
            flex: 1,
            child: Center(
                child: Text("Qty",
                    style: TextStyle(fontWeight: FontWeight.bold)))),
        Expanded(
            flex: 2,
            child: Center(
                child: Text("Amount",
                    style: TextStyle(fontWeight: FontWeight.bold)))),
        Expanded(
            flex: 2,
            child: Center(
                child: Text("Discount",
                    style: TextStyle(fontWeight: FontWeight.bold)))),
        Expanded(
            flex: 1,
            child: Center(
                child: Text("Vat",
                    style: TextStyle(fontWeight: FontWeight.bold)))),
        Expanded(
            flex: 2,
            child: Center(
                child: Text("Total",
                    style: TextStyle(fontWeight: FontWeight.bold)))),
        Expanded(flex: 1, child: SizedBox()),
      ],
    );
  }

  // Wrap header with same horizontal offset as card.margin + card.padding
  Widget buildHeaderWithAlignedPadding() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 24.w), // 12.w (card margin) + 12.w (card child padding)
      child:
          _buildHeaderRow(), // keep your existing header Row (flex: 3,1,1,2,2,1,2,1)
    );
  }

  // Updated cart item row (replace the existing Row inside your Card)
  Widget _buildCartItemRow(CartItem item) {
    double price = item.price * item.quantity;
    double discount = item.discount ?? 0.0;
    double discountedPrice = price - discount;
    double vat = discountedPrice * (item.tax_percentage / 100);
    double total = discountedPrice + vat;

    final barcode = item.barcode;
    final String currency = (Details.currency?.isNotEmpty ?? false)
        ? Details.currency!
        : currencySymbol;

    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 3.w),
        child: Row(
          children: [
            // SizedBox(width: 10.w,),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (barcode == "null" || barcode.isEmpty)
                        ? item.productName
                        : "${item.productName} | $barcode",
                    style:
                        TextStyle(fontSize: 8.sp, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.unitName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        item.unitName,
                        style:
                            TextStyle(fontSize: 8.sp, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Rate (flex:1)
            newwindow == true
                ? Expanded(
                    flex: 1,
                    child: Center(
                      child: Text(
                        "$currency${price.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 8.sp),
                      ),
                    ),
                  )
                : Expanded(
                    flex: 1,
                    child: Center(
                      child: item.rateChangeAllowed == "YES"
                          ? SizedBox(
                              width: 70.w, // same width you wanted
                              child: TextField(
                                controller: item.priceController,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 6.w, vertical: 4.h),
                                  border: OutlineInputBorder(),
                                ),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                                onChanged: (value) {
                                  final normalized = value.replaceAll(',', '.');
                                  final newPrice =
                                      double.tryParse(normalized) ??
                                          item.originalPrice;
                                  cartController.updatePrice(item, newPrice,
                                      updateControllerText: false);
                                  cartController.cartItems.refresh();
                                },
                              ),
                            )
                          : Text(
                              "${item.price.toStringAsFixed(2)}",
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 8.sp),
                            ),
                    ),
                  ),

            // Qty (flex:1)
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  newwindow == true
                      ? SizedBox()
                      : IconButton(
                          icon: Icon(Icons.remove, size: 12.sp),
                          onPressed: () =>
                              cartController.decreaseQuantity(item),
                        ),
                  Text("${item.quantity}",
                      style: TextStyle(
                          fontSize: 8.sp, fontWeight: FontWeight.bold)),
                  newwindow == true
                      ? SizedBox()
                      : IconButton(
                          icon: Icon(Icons.add, size: 12.sp),
                          onPressed: () =>
                              cartController.increaseQuantity(item),
                        ),
                ],
              ),
            ),

            // Amount (flex:2)
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  "$currency${price.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 8.sp),
                ),
              ),
            ),

            newwindow == true
                ? Expanded(
                    flex: 1,
                    child: Center(
                      child: Text(
                        "$currency${item.discountController.text}",
                        style: TextStyle(fontSize: 8.sp),
                      ),
                    ),
                  )
                : // Discount (flex:2) — keep flex=2 to match header
                Expanded(
                    flex: 2,
                    child: Center(
                      child: SizedBox(
                        width: 70.w, // same width as rate box for visual parity
                        child: TextField(
                          controller: item.discountController,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: "0.0",
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 4.h),
                            border: OutlineInputBorder(),
                          ),
                          textAlign: TextAlign.center,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          onChanged: (value) {
                            String normalizedValue = value.replaceAll(',', '.');
                            double d = double.tryParse(normalizedValue) ?? 0.0;
                            item.discount = d;
                            cartController.updateDiscount(item, d,
                                updateControllerText: false);
                            cartController.cartItems.refresh();
                          },
                        ),
                      ),
                    ),
                  ),

            // Vat (flex:1)
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  "$currency${vat.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 8.sp),
                ),
              ),
            ),

            // Total (flex:2)
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  "$currency${total.toStringAsFixed(2)}",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 8.sp),
                ),
              ),
            ),

            // Delete (flex:1)
            newwindow == true
                ? const SizedBox()
                : Expanded(
                    flex: 1,
                    child: IconButton(
                        icon:
                            Icon(Icons.delete, size: 15.sp, color: Colors.red),
                        onPressed: () {
                          cartController.removeFromCart(item);
                        }),
                  ),
          ],
        ),
      ),
    );
  }
}
