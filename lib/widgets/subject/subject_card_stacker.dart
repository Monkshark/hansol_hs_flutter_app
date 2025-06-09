import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/device.dart';
import 'subject_card.dart';

class SubjectCardStacker extends StatefulWidget {
  final List<SubjectCard> cards;
  const SubjectCardStacker({Key? key, required this.cards}) : super(key: key);

  @override
  State<SubjectCardStacker> createState() => SubjectCardStackerState();
}

class SubjectCardStackerState extends State<SubjectCardStacker>
    with TickerProviderStateMixin {
  int currentIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  double dragDx = 0.0;
  int swipeDirection = 1;
  bool _isAnimating = false;

  static double cardWidth = Device.getWidth(80);
  static double cardHeight = Device.getHeight(15);
  static double threshold = cardWidth / 3;

  List<bool> checkedList = [];
  List<SubjectCard> effectiveCards = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

    _updateCardList();
  }

  @override
  void didUpdateWidget(SubjectCardStacker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cards != widget.cards) {
      _updateCardList();
    }
  }

  void _updateCardList() {
    setState(() {
      if (widget.cards.length == 2) {
        effectiveCards = [...widget.cards, ...widget.cards];
      } else {
        effectiveCards = widget.cards;
      }
      checkedList = List.filled(effectiveCards.length, false);
      if (currentIndex >= effectiveCards.length) {
        currentIndex = 0;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateToNext({double start = 0}) {
    if (_isAnimating ||
        effectiveCards.length <= 1 ||
        checkedList[currentIndex]) {
      return;
    }
    _isAnimating = true;
    swipeDirection = 1;
    final anim =
        Tween<double>(begin: start, end: -cardWidth).animate(_animation);
    _controller.reset();
    anim.addListener(() => setState(() => dragDx = anim.value));
    _controller.forward().then((_) {
      setState(() {
        currentIndex = (currentIndex + 1) % effectiveCards.length;
        dragDx = 0;
        _isAnimating = false;
      });
    });
  }

  void _animateToPrev({double start = 0}) {
    if (_isAnimating ||
        effectiveCards.length <= 1 ||
        checkedList[currentIndex]) {
      return;
    }
    _isAnimating = true;
    swipeDirection = -1;
    final anim =
        Tween<double>(begin: start, end: cardWidth).animate(_animation);
    _controller.reset();
    anim.addListener(() => setState(() => dragDx = anim.value));
    _controller.forward().then((_) {
      setState(() {
        currentIndex =
            (currentIndex - 1 + effectiveCards.length) % effectiveCards.length;
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
    if (_isAnimating ||
        checkedList[currentIndex] ||
        effectiveCards.length <= 1) {
      return;
    }
    setState(() {
      dragDx += details.primaryDelta!;
      dragDx = dragDx.clamp(-cardWidth * 1.2, cardWidth * 1.2);
      int newDirection = dragDx < 0 ? 1 : -1;
      swipeDirection = newDirection;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isAnimating ||
        checkedList[currentIndex] ||
        effectiveCards.length <= 1) {
      return;
    }
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
    required int cardKey,
    required double dx,
    required double dy,
    required double scale,
    required double opacity,
  }) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Container(
            key: ValueKey('${cardKey}_${effectiveCards[cardKey].subjectName}'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
            ),
            child: SubjectCard(
              subjectName: effectiveCards[cardKey].subjectName,
              classNumber: effectiveCards[cardKey].classNumber,
              checked: checkedList[cardKey],
              onCheck: (value) {
                setState(() {
                  checkedList[cardKey] = value ?? false;
                  if (effectiveCards.length == 4) {
                    int duplicateIndex =
                        (cardKey < 2) ? cardKey + 2 : cardKey - 2;
                    checkedList[duplicateIndex] = value ?? false;
                  }
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int len = effectiveCards.length;
    if (len == 0) return const SizedBox.shrink();

    if (len == 1) {
      return Center(
        child: _buildAnimatedCard(
          cardKey: 0,
          dx: 0,
          dy: 0,
          scale: 1,
          opacity: 1,
        ),
      );
    }

    final backIndex = (currentIndex + 1) % len;
    final prevIndex = (currentIndex - 1 + len) % len;
    final back2Index = (currentIndex + 2) % len;

    double progress = (dragDx.abs() / cardWidth).clamp(0.0, 1.0);
    double lerp(double a, double b) =>
        a + (b - a) * Curves.easeInOut.transform(progress);

    final frontDx = lerp(0, swipeDirection == 1 ? -cardWidth : cardWidth);
    final frontOpacity = lerp(1, 0);

    final backDx = lerp(swipeDirection == 1 ? 18 : -18, 0);
    final backScale = lerp(0.97, 1);
    final backOpacity = lerp(0.73, 1);
    final backDy = lerp(4, 0);

    final backCard = swipeDirection == 1 ? backIndex : prevIndex;
    final back2Card = swipeDirection == 1 ? back2Index : prevIndex;

    Widget secondBack = AnimatedSwitcher(
      duration: const Duration(milliseconds: 600), // 더 부드러운 전환
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: anim,
          child: child,
        ),
      ),
      child: _buildAnimatedCard(
        cardKey: back2Card,
        dx: lerp(
            swipeDirection == 1 ? 35 : -35, swipeDirection == 1 ? 18 : -18),
        dy: lerp(7, 4),
        scale: lerp(0.94, 0.97),
        opacity: Curves.easeInOut.transform(progress) * 0.8, // 서서히 나타나고 사라짐
      ),
    );

    Widget firstBack = AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: _buildAnimatedCard(
        cardKey: backCard,
        dx: backDx,
        dy: backDy,
        scale: backScale,
        opacity: backOpacity,
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
              firstBack,
              _buildAnimatedCard(
                cardKey: currentIndex,
                dx: frontDx,
                dy: 0,
                scale: 1,
                opacity: frontOpacity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
