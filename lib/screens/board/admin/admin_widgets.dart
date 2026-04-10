import 'package:flutter/material.dart';

class AdminSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color cardColor;
  final List<Widget> children;

  const AdminSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.cardColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

class AdminTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color cardColor;
  final bool initiallyExpanded;
  final Widget child;

  const AdminTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.cardColor,
    this.initiallyExpanded = false,
    required this.child,
  });

  @override
  State<AdminTile> createState() => AdminTileState();
}

class AdminTileState extends State<AdminTile> {
  late bool _expanded;
  DateTime _lastScrollTime = DateTime(2000);

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      _lastScrollTime = DateTime.now();
    }
    return false;
  }

  void _toggle() {
    // 스크롤 직후 탭 무시 (빠른 스크롤 중 오작동 방지)
    if (DateTime.now().difference(_lastScrollTime).inMilliseconds < 150) return;
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Container(
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 20, color: widget.color),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(widget.title, style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more, size: 22,
                        color: textColor?.withAlpha(150)),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _expanded ? widget.child : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
