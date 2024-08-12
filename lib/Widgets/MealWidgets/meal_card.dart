import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:hansol_high_school/styles.dart';

class MealCard extends StatefulWidget {
  final String meal;
  final DateTime date;
  final int mealType;
  final String kcal;

  const MealCard({
    required this.meal,
    required this.date,
    required this.mealType,
    required this.kcal,
    Key? key,
  }) : super(key: key);

  @override
  _MealCardState createState() => _MealCardState();
}

class _MealCardState extends State<MealCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _buttonOpacity;
  bool _buttonsVisible = false;
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.5).animate(_controller);
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _buttonsVisible = true;
    });
    _controller.forward().then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        _controller.reverse().then((_) {
          setState(() {
            _buttonsVisible = false;
          });
        });
      });
    });
  }

  Future<void> _shareMealCard() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 5.0);

      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = (await getTemporaryDirectory()).path;
      final imgFile = File('$directory/screenshot.png');
      await imgFile.writeAsBytes(pngBytes);

      final xFile = XFile(imgFile.path);
      await Share.shareXFiles([xFile]);
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = screenWidth * 0.9;
    final cardHeight = screenHeight * 0.2;
    final baseFontSizeHorizontal = screenWidth * 0.025;
    final baseFontSizeVertical = screenHeight * 0.022;

    final combinedFontSize = (baseFontSizeHorizontal + baseFontSizeVertical) / 2;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: _opacity.value,
                child: RepaintBoundary(
                  key: _globalKey,
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        width: 1.5,
                        color: PRIMARY_COLOR,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.date.year.toString(),
                                  style: TextStyle(
                                    fontSize: combinedFontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "${widget.date.month.toString().padLeft(2, '0')}"
                                      "${widget.date.day.toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                    fontSize: combinedFontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6.0),
                                Text(
                                  getMealType(widget.mealType),
                                  style: TextStyle(
                                    fontSize: combinedFontSize * 1.2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 14.0),
                                Text.rich(
                                  TextSpan(
                                    text: widget.kcal,
                                    children: [
                                      if (widget.kcal.length == 10)
                                        const TextSpan(
                                          text: '0',
                                          style: TextStyle(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                    ],
                                  ),
                                  style: TextStyle(
                                    fontSize: combinedFontSize * 0.7,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 48.0),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.meal,
                                      style: TextStyle(
                                        fontSize: combinedFontSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_buttonsVisible) ...[
                Positioned(
                  top: 30,
                  right: 15,
                  child: FadeTransition(
                    opacity: _buttonOpacity,
                    child: ElevatedButton(
                      onPressed: _shareMealCard,
                      child: Icon(
                          Platform.isIOS ? Icons.ios_share : Icons.share),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  right: 15,
                  child: FadeTransition(
                    opacity: _buttonOpacity,
                    child: ElevatedButton(
                      child: const Icon(Icons.info_outline),
                      onPressed: () {
                        // add logic
                      },
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

String getMealType(int mealType) {
  switch (mealType) {
    case 1:
      return "조식";
    case 2:
      return "중식";
    case 3:
      return "석식";
    default:
      return "중식";
  }
}
