import 'package:flutter/material.dart';
import 'subject_card.dart';

class SubjectCardStacker extends StatefulWidget {
  final List<SubjectCard> cards;
  const SubjectCardStacker({
    Key? key,
    required this.cards,
  }) : super(key: key);

  @override
  State<SubjectCardStacker> createState() => _SubjectCardStackerState();
}

class _SubjectCardStackerState extends State<SubjectCardStacker>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  double dragDx = 0.0;
  int swipeDirection = 1;
  bool _isAnimating = false;
  static const double cardWidth = 340.0;
  static const double threshold = cardWidth / 3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 240),
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

  void _animateToNext({double start = 0}) {
    if (_isAnimating || widget.cards.length <= 1) return;
    _isAnimating = true;
    swipeDirection = 1;
    final begin = start;
    final end = -cardWidth;
    final anim = Tween<double>(begin: begin, end: end).animate(_animation);
    _controller.reset();
    anim.addListener(() {
      setState(() {
        dragDx = anim.value;
      });
    });
    _controller.forward().then((_) {
      setState(() {
        currentIndex = (currentIndex + 1) % widget.cards.length;
        dragDx = 0;
        _isAnimating = false;
      });
      anim.removeListener(() {});
    });
  }

  void _animateToPrev({double start = 0}) {
    if (_isAnimating || widget.cards.length <= 1) return;
    _isAnimating = true;
    swipeDirection = -1;
    final begin = start;
    final end = cardWidth;
    final anim = Tween<double>(begin: begin, end: end).animate(_animation);
    _controller.reset();
    anim.addListener(() {
      setState(() {
        dragDx = anim.value;
      });
    });
    _controller.forward().then((_) {
      setState(() {
        currentIndex =
            (currentIndex - 1 + widget.cards.length) % widget.cards.length;
        dragDx = 0;
        _isAnimating = false;
      });
      anim.removeListener(() {});
    });
  }

  void _animateBack({double start = 0}) {
    if (_isAnimating) return;
    _isAnimating = true;
    final begin = start;
    final end = 0.0;
    final anim = Tween<double>(begin: begin, end: end).animate(_animation);
    _controller.reset();
    anim.addListener(() {
      setState(() {
        dragDx = anim.value;
      });
    });
    _controller.forward().then((_) {
      setState(() {
        dragDx = 0;
        _isAnimating = false;
      });
      anim.removeListener(() {});
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      dragDx += details.primaryDelta!;
      dragDx = dragDx.clamp(-cardWidth * 1.2, cardWidth * 1.2);
      swipeDirection = dragDx < 0 ? 1 : -1;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isAnimating) return;
    if (dragDx.abs() > threshold) {
      if (dragDx < 0) {
        _animateToNext(start: dragDx);
      } else if (dragDx > 0) {
        _animateToPrev(start: dragDx);
      }
    } else {
      _animateBack(start: dragDx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int len = widget.cards.length;
    int backIndex = (currentIndex + 1) % len;
    int prevIndex = (currentIndex - 1 + len) % len;
    int back2Index = (currentIndex + 2) % len;
    int prev2Index = (currentIndex - 2 + len) % len;

    int nextCardIndex = swipeDirection == 1 ? backIndex : prevIndex;
    int nextNextCardIndex = swipeDirection == 1 ? back2Index : prev2Index;

    double dragProgress = (dragDx.abs() / cardWidth).clamp(0.0, 1.0);

    double back2Dx = swipeDirection == 1
        ? 35 - (dragProgress * 15)
        : -35 + (dragProgress * 15);
    double back2Scale = 0.94 + 0.025 * dragProgress;
    double back2Opacity = 0.4 + 0.22 * dragProgress;

    double backDx = swipeDirection == 1
        ? 18 - (dragProgress * 16)
        : -18 + (dragProgress * 16);
    double backScale = 0.97 + 0.025 * dragProgress;
    double backOpacity = 0.73 + 0.24 * dragProgress;

    double frontDx = dragDx;
    double frontScale = 1 - 0.02 * dragProgress;
    double frontOpacity = 1 - 0.25 * dragProgress;

    return Center(
      child: SizedBox(
        width: cardWidth,
        height: 120,
        child: GestureDetector(
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.cards.length > 2)
                Transform.translate(
                  offset: Offset(back2Dx, 7),
                  child: Transform.scale(
                    scale: back2Scale,
                    child: Opacity(
                      opacity: back2Opacity,
                      child: widget.cards[nextNextCardIndex],
                    ),
                  ),
                ),
              // 바로 뒷카드
              Transform.translate(
                offset: Offset(backDx, 4),
                child: Transform.scale(
                  scale: backScale,
                  child: Opacity(
                    opacity: backOpacity,
                    child: widget.cards[nextCardIndex],
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(frontDx, 0),
                child: Transform.scale(
                  scale: frontScale,
                  child: Opacity(
                    opacity: frontOpacity,
                    child: widget.cards[currentIndex],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
