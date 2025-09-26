import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class CustomInfoBox extends StatelessWidget {
  final String title;
  final String value;
  final Color clr;

  const CustomInfoBox({
    Key? key,
    required this.title,
    required this.value,
    required this.clr,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12.sp),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 15.sp, color: clr),
                ),
                Text(
                  "\$",
                  style: TextStyle(fontSize: 10.sp, color: clr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
