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

  static const double maxDrag = 55.0; // 카드가 움직일 수 있는 최대 거리

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 210),
      vsync: this,
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
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
      dragDx = dragDx.clamp(-maxDrag, maxDrag); // 최대 이동 거리 제한
      swipeDirection = dragDx < 0 ? 1 : -1;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isSwiping) return;
    if (dragDx.abs() > maxDrag / 2 ||
        (details.primaryVelocity != null &&
            details.primaryVelocity!.abs() > 350)) {
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
        height: 120,
        child: GestureDetector(
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  double progress = _isSwiping
                      ? _animation.value
                      : (dragDx.abs() / maxDrag).clamp(0.0, 1.0);
                  double dx = 7.0 * (1 - progress);
                  double scale = 0.984 + 0.016 * progress;
                  double opacity = 0.80 + 0.18 * progress;
                  return Transform.translate(
                    offset: Offset(dx, 3.5),
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
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  double progress = _isSwiping
                      ? _animation.value
                      : (dragDx.abs() / maxDrag).clamp(0.0, 1.0);
                  double direction = _isSwiping
                      ? swipeDirection.toDouble()
                      : (dragDx < 0
                          ? 1
                          : dragDx > 0
                              ? -1
                              : 0);
                  double dx = -direction * 7.5 * progress + dragDx;
                  double scale = 1 - 0.016 * progress;
                  double opacity = 1 - 0.28 * progress;
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
