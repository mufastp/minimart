import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomContainer extends StatelessWidget {
  final double height;
  final double width;
  final Color color;
  final String text;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;
  final BorderRadiusGeometry borderRadius;

  const CustomContainer({
    Key? key,
    this.height = 70.0,
    this.width = 250.0,
    this.color = const Color(0xFFF5F5F5),
    required this.text,
    this.padding = const EdgeInsets.only(left: 30),
    this.alignment = Alignment.centerLeft,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height.h,
      width: width.w,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: color,
      ),
      child: Padding(
        padding: padding,
        child: Align(
          alignment: alignment,
          child: Text(
            text,
            style: TextStyle(fontSize:10.sp,color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}
