import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hansol_high_school/data/api_strings.dart';
import 'package:hansol_high_school/data/meal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class MealCard extends StatefulWidget {
  final String? meal;
  final DateTime date;
  final int mealType;
  final String kcal;
  final String ntrInfo;

  const MealCard({
    required this.meal,
    required this.date,
    required this.mealType,
    required this.kcal,
    this.ntrInfo = '',
    Key? key,
  }) : super(key: key);

  @override
  State<MealCard> createState() => _MealCardState();
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
    super.initState();
    mealData = Meal(
      meal: widget.meal,
      date: widget.date,
      mealType: widget.mealType,
      kcal: widget.kcal,
      ntrInfo: widget.ntrInfo,
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (mealData.meal == null || mealData.meal == ApiStrings.mealNoData) return;
    if (_buttonsVisible) {
      _controller.reverse().then((_) {
        setState(() => _buttonsVisible = false);
      });
    } else {
      setState(() => _buttonsVisible = true);
      _controller.forward();
    }
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
      final imgFile = File('$directory/meal_screenshot.png');
      await imgFile.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(imgFile.path)]),
      );
    } catch (e) {
      log('Share error: $e');
    }
  }

  Map<String, String> _getAllergyMap(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return {
      '1': l10n.data_allergyEgg, '2': l10n.data_allergyMilk, '3': l10n.data_allergyBuckwheat, '4': l10n.data_allergyPeanut,
      '5': l10n.data_allergyBean, '6': l10n.data_allergyWheat, '7': l10n.data_allergyMackerel, '8': l10n.data_allergyCrab,
      '9': l10n.data_allergyShrimp, '10': l10n.data_allergyPork, '11': l10n.data_allergyPeach, '12': l10n.data_allergyTomato,
      '13': l10n.data_allergySulfite, '14': l10n.data_allergyWalnut, '15': l10n.data_allergyChicken, '16': l10n.data_allergyBeef,
      '17': l10n.data_allergySquid, '18': l10n.data_allergyShellfish,
    };
  }

  Set<String> _extractAllergyNumbers(String? meal, Map<String, String> allergyMap) {
    if (meal == null) return {};
    final regex = RegExp(r'\(([0-9.,\s]+)\)');
    final matches = regex.allMatches(meal);
    final numbers = <String>{};
    for (final match in matches) {
      final inside = match.group(1)!;
      for (final num in inside.split(RegExp(r'[.,\s]+'))) {
        final trimmed = num.trim();
        if (trimmed.isNotEmpty && allergyMap.containsKey(trimmed)) {
          numbers.add(trimmed);
        }
      }
    }
    return numbers;
  }

  void _showNutritionInfo() {
    final allergyMap = _getAllergyMap(context);
    final allergyNumbers = _extractAllergyNumbers(mealData.meal, allergyMap);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.theme.darkGreyColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.meal_nutritionTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 16),
                _infoRow(AppLocalizations.of(context)!.meal_mealType, _localizedMealType(context, mealData.getMealTypeKey())),
                _infoRow(AppLocalizations.of(context)!.meal_calorie, mealData.kcal.isNotEmpty ? mealData.kcal : AppLocalizations.of(context)!.meal_noInfoShort),
                if (mealData.ntrInfo.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!.meal_nutrition, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  ...mealData.ntrInfo.split('\n').where((s) => s.trim().isNotEmpty).map((line) {
                    final parts = line.split(':');
                    if (parts.length >= 2) {
                      return _infoRow(parts[0].trim(), parts.sublist(1).join(':').trim());
                    }
                    return _infoRow('', line.trim());
                  }),
                ],
                if (allergyNumbers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.meal_allergy,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (allergyNumbers.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)))).map((num) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.theme.primaryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.theme.primaryColor.withAlpha(60),
                          ),
                        ),
                        child: Text(
                          '$num. ${allergyMap[num]}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.theme.primaryColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _localizedMealType(BuildContext context, String key) {
    final l = AppLocalizations.of(context)!;
    switch (key) {
      case 'breakfast': return l.meal_breakfast;
      case 'lunch': return l.meal_lunch;
      case 'dinner': return l.meal_dinner;
      default: return l.meal_lunch;
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: AppColors.theme.mealTypeTextColor)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      ),
    );
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
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.theme.mealCardBackgroundColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        mealData.meal ?? AppLocalizations.of(context)!.meal_noData,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.6,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_buttonsVisible)
                Positioned(
                  right: 16,
                  child: FadeTransition(
                    opacity: _buttonOpacity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionButton(
                          icon: Platform.isIOS ? Icons.ios_share : Icons.share,
                          onTap: _shareMealCard,
                        ),
                        const SizedBox(height: 12),
                        _actionButton(
                          icon: Icons.info_outline,
                          onTap: _showNutritionInfo,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.theme.primaryColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
