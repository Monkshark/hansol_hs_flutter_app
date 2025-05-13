import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/device.dart';

class SingleSettingCard extends StatefulWidget {
  final String text;
  final Widget child;

  const SingleSettingCard({
    Key? key,
    required this.text,
    required this.child,
  }) : super(key: key);

  @override
  State<SingleSettingCard> createState() => _SingleSettingCardState();
}

class _SingleSettingCardState extends State<SingleSettingCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: Device.getWidth(94),
      height: Device.getHeight(6.5),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: Device.getWidth(4),
          ),
          Expanded(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: Device.getWidth(4.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
