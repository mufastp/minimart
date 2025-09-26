import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomBoxFields extends StatefulWidget {
  final String? txt;
  final Color? clr;

  CustomBoxFields({
    Key? key,
    this.txt='',
    this.clr = Colors.transparent, // Default to transparent color if not provided
  }) : super(key: key);

  @override
  _CustomBoxFieldsState createState() => _CustomBoxFieldsState();
}

class _CustomBoxFieldsState extends State<CustomBoxFields> {
  TextEditingController _controller = TextEditingController();
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // When the TextField loses focus, append .00 if necessary
        String text = _controller.text;
        if (text.isNotEmpty && !text.contains('.')) {
          setState(() {
            _controller.text = '$text.00';
            _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length));
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 70.h,
              width: MediaQuery.of(context).size.width * .12,
              decoration: BoxDecoration(
                color: widget.clr,
                borderRadius: BorderRadius.all(Radius.circular(6)),
                border: Border.all(color: Colors.black),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    textAlign: TextAlign.right, // Align text to the right
                    focusNode: _focusNode,
                    controller: _controller,
                    style:
                    TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                    cursorHeight: 30,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6), // Limit input to 6 digits
                    ],
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      suffixStyle: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w), // Add spacing between the container and text
            Text(
              widget.txt!,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10.sp),
            ),
          ],
        ),
      ],
    );
  }
}
