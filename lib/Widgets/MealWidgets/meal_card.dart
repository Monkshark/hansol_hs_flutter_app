import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hansol_high_school/Data/device.dart';
import 'package:hansol_high_school/Data/meal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:hansol_high_school/Styles/app_colors.dart';

class MealCard extends StatefulWidget {
  final String? meal;
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

  late Meal mealData;

  @override
  void initState() {
    mealData = Meal(
      meal: widget.meal,
      date: widget.date,
      mealType: widget.mealType,
      kcal: widget.kcal,
    );

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
    if (mealData.meal == null || mealData.meal == "급식 정보가 없습니다") {
      return;
    }
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
                    width: Device.getWidth(85),
                    decoration: BoxDecoration(
                      color: AppColors.theme.mealCardBackgroundColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mealData.meal != null
                                ? mealData.meal!
                                : "급식 정보가 없습니다",
                            style: TextStyle(
                              fontSize: Device.getWidth(3.5),
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        ],
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
                      child:
                          Icon(Platform.isIOS ? Icons.ios_share : Icons.share),
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
