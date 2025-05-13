import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/device.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class NewsCard extends StatefulWidget {
  final String title;

  const NewsCard({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: Device.getWidth(95),
      height: Device.getHeight(5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.theme.tertiaryColor,
      ),
      child: Text(
        widget.title,
        style: TextStyle(
          color: AppColors.theme.white,
          fontSize: Device.getWidth(4.5),
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
