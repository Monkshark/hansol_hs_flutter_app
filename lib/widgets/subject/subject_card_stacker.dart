import 'package:flutter/material.dart';
import 'subject_card.dart';

class SubjectCardStacker extends StatefulWidget {
  final List<SubjectCard> cards;
  const SubjectCardStacker({Key? key, required this.cards}) : super(key: key);

  @override
  State<SubjectCardStacker> createState() => _SubjectCardStackerState();
}

class _SubjectCardStackerState extends State<SubjectCardStacker>
    with TickerProviderStateMixin {
  int currentIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  double dragDx = 0.0;
  int swipeDirection = 1;
  bool _isAnimating = false;

  static const double cardWidth = 340.0;
  static const double cardHeight = 120.0;
  static const double threshold = cardWidth / 3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
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
    final anim =
        Tween<double>(begin: start, end: -cardWidth).animate(_animation);
    _controller.reset();
    anim.addListener(() => setState(() => dragDx = anim.value));
    _controller.forward().then((_) {
      setState(() {
        currentIndex = (currentIndex + 1) % widget.cards.length;
        dragDx = 0;
        _isAnimating = false;
      });
    });
  }

  void _animateToPrev({double start = 0}) {
    if (_isAnimating || widget.cards.length <= 1) return;
    _isAnimating = true;
    swipeDirection = -1;
    final anim =
        Tween<double>(begin: start, end: cardWidth).animate(_animation);
    _controller.reset();
    anim.addListener(() => setState(() => dragDx = anim.value));
    _controller.forward().then((_) {
      setState(() {
        currentIndex =
            (currentIndex - 1 + widget.cards.length) % widget.cards.length;
        dragDx = 0;
        _isAnimating = false;
      });
    });
  }

  void _animateBack({double start = 0}) {
    if (_isAnimating) return;
    _isAnimating = true;
    final anim = Tween<double>(begin: start, end: 0.0).animate(_animation);
    _controller.reset();
    anim.addListener(() => setState(() => dragDx = anim.value));
    _controller.forward().then((_) {
      setState(() {
        dragDx = 0;
        _isAnimating = false;
      });
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      final newDx = (dragDx + details.primaryDelta!)
          .clamp(-cardWidth * 1.2, cardWidth * 1.2);
      final newDirection = newDx < 0 ? 1 : -1;
      if (newDirection != swipeDirection) {}
      dragDx = newDx;
      swipeDirection = newDirection;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isAnimating) return;
    if (dragDx.abs() > threshold) {
      if (dragDx < 0) {
        _animateToNext(start: dragDx);
      } else {
        _animateToPrev(start: dragDx);
      }
    } else {
      _animateBack(start: dragDx);
    }
  }

  Widget _buildAnimatedCard({
    required Widget child,
    required double dx,
    required double dy,
    required double scale,
    required double opacity,
    required int cardKey,
    Key? key,
  }) {
    return Transform.translate(
      key: key,
      offset: Offset(dx, dy),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int len = widget.cards.length;
    if (len == 0) return const SizedBox.shrink();

    final backIndex = (currentIndex + 1) % len;
    final back2Index = (currentIndex + 2) % len;
    final prevIndex = (currentIndex - 1 + len) % len;
    final prev2Index = (currentIndex - 2 + len) % len;

    double progress = (dragDx.abs() / cardWidth).clamp(0.0, 1.0);
    double lerp(double a, double b) => a + (b - a) * progress;

    final frontDx = lerp(0, swipeDirection == 1 ? -cardWidth : cardWidth);
    final frontOpacity = lerp(1, 0);

    final backDx = lerp(swipeDirection == 1 ? 18 : -18, 0);
    final backScale = lerp(0.97, 1);
    final backOpacity = lerp(0.73, 1);
    final backDy = lerp(4, 0);

    final fadeStart =
        (progress < 0.5) ? 0.0 : ((progress - 0.5) * 2).clamp(0.0, 1.0);
    final back2Dx =
        lerp(swipeDirection == 1 ? 35 : -35, swipeDirection == 1 ? 18 : -18);
    final back2Scale = lerp(0.94, 0.97);
    final back2Opacity = fadeStart * 0.4;
    final back2Dy = lerp(7, 4);

    final backCard = swipeDirection == 1 ? backIndex : prevIndex;
    final back2Card = swipeDirection == 1 ? back2Index : prev2Index;

    Widget secondBack = AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: _buildAnimatedCard(
        key: ValueKey('second-$back2Card'),
        child: widget.cards[back2Card],
        dx: back2Dx,
        dy: back2Dy,
        scale: back2Scale,
        opacity: back2Opacity,
        cardKey: back2Card,
      ),
    );

    Widget firstBack = AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: _buildAnimatedCard(
        key: ValueKey('first-$backCard'),
        child: widget.cards[backCard],
        dx: backDx,
        dy: backDy,
        scale: backScale,
        opacity: backOpacity,
        cardKey: backCard,
      ),
    );

    return Center(
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: GestureDetector(
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (len > 2) secondBack,
              if (len > 1) firstBack,
              _buildAnimatedCard(
                key: ValueKey('front-$currentIndex'),
                child: widget.cards[currentIndex],
                dx: frontDx,
                dy: 0,
                scale: 1,
                opacity: frontOpacity,
                cardKey: currentIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
