import 'package:flutter/material.dart';
import 'subject_card.dart';

class SubjectCardStacker extends StatefulWidget {
  final List<SubjectCard> cards;
  const SubjectCardStacker({Key? key, required this.cards}) : super(key: key);

  @override
  State<SubjectCardStacker> createState() => _SubjectCardStackerState();
}

class _SubjectCardStackerState extends State<SubjectCardStacker>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSwiping = false;
  double dragDx = 0.0;
  int swipeDirection = 1; // 1: next, -1: prev

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateToNext() async {
    if (_isSwiping || widget.cards.length <= 1) return;
    setState(() {
      _isSwiping = true;
      swipeDirection = 1;
    });
    await _controller.forward();
    setState(() {
      currentIndex = (currentIndex + 1) % widget.cards.length;
      _controller.reset();
      dragDx = 0;
      _isSwiping = false;
    });
  }

  void _animateToPrev() async {
    if (_isSwiping || widget.cards.length <= 1) return;
    setState(() {
      _isSwiping = true;
      swipeDirection = -1;
    });
    await _controller.forward();
    setState(() {
      currentIndex =
          (currentIndex - 1 + widget.cards.length) % widget.cards.length;
      _controller.reset();
      dragDx = 0;
      _isSwiping = false;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isSwiping) return;
    setState(() {
      dragDx += details.primaryDelta!;
      dragDx = dragDx.clamp(-100.0, 100.0);
      swipeDirection = dragDx < 0 ? 1 : -1;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isSwiping) return;
    if (dragDx.abs() > 50 ||
        (details.primaryVelocity != null &&
            details.primaryVelocity!.abs() > 500)) {
      if (dragDx < 0) {
        _animateToNext();
      } else if (dragDx > 0) {
        _animateToPrev();
      }
    } else {
      setState(() {
        dragDx = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int len = widget.cards.length;
    int backIndex = (currentIndex + 1) % len;
    int prevIndex = (currentIndex - 1 + len) % len;

    int nextCardIndex = swipeDirection == 1 ? backIndex : prevIndex;

    return Center(
      child: SizedBox(
        width: 340,
        height: 160,
        child: GestureDetector(
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // "넘어갈 카드"
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  double progress = _isSwiping
                      ? _animation.value
                      : (dragDx.abs() / 100.0).clamp(0.0, 1.0);
                  double dx = 8.0 * (1 - progress);
                  double scale = 0.98 + 0.02 * progress;
                  double opacity = 0.8 + 0.18 * progress;
                  return Transform.translate(
                    offset: Offset(dx, 4),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: widget.cards[nextCardIndex],
                      ),
                    ),
                  );
                },
              ),
              // 현재 카드
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  double progress = _isSwiping
                      ? _animation.value
                      : (dragDx.abs() / 100.0).clamp(0.0, 1.0);
                  double direction = _isSwiping
                      ? swipeDirection.toDouble()
                      : (dragDx < 0
                          ? 1
                          : dragDx > 0
                              ? -1
                              : 0);
                  double dx = -direction * 7.0 * progress + dragDx;
                  double scale = 1 - 0.02 * progress;
                  double opacity = 1 - 0.32 * progress;
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: widget.cards[currentIndex],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
