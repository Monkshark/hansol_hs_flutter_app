import 'package:flutter/material.dart';

class MultiSettingCard extends StatefulWidget {
  final int settingsCount;
  final List<SettingInfo> settingInfo;

  const MultiSettingCard({
    Key? key,
    required this.settingsCount,
    required this.settingInfo,
  }) : super(key: key);

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
