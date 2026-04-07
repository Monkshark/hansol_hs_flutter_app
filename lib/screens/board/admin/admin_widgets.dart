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

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: ExpansionTile(
          key: ValueKey<String>('admin_tile_${widget.title}'),
          initiallyExpanded: widget.initiallyExpanded,
          onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
          collapsedBackgroundColor: widget.cardColor,
          backgroundColor: widget.cardColor,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(widget.icon, size: 20, color: widget.color),
          title: Text(widget.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color)),
          children: [if (_expanded) widget.child],
        ),
      ),
    );
  }
}
