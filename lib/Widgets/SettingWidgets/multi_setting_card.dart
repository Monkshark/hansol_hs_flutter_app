import 'package:flutter/material.dart';

class MultiSettingCard extends StatefulWidget {
  final List<SettingInfo> settingInfo;
  final int settingCount;

  const MultiSettingCard({
    Key? key,
    required this.settingInfo,
  })  : settingCount = settingInfo.length,
        super(key: key);

  @override
  State<MultiSettingCard> createState() => _MultiSettingCardState();
}

class _MultiSettingCardState extends State<MultiSettingCard> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

enum SettingInfo {
  text,
  child,
}
