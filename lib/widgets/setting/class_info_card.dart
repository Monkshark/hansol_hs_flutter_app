import 'package:flutter/material.dart';

class SettingCard extends StatefulWidget {
  final String name;
  final Widget child;

  const SettingCard({
    Key? key,
    required this.name,
    required this.child,
  }) : super(key: key);

  @override
  State<SettingCard> createState() => _SettingCardState();
}

class _SettingCardState extends State<SettingCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 20),
              Text(
                widget.name,
                style: const TextStyle(fontSize: 20),
              ),
              const Spacer(),
              widget.child,
              const SizedBox(width: 20),
            ],
          ),
          const Divider(thickness: 1, color: Colors.grey),
        ],
      ),
    );
  }
}
