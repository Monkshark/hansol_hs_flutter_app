import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/styles/responsive.dart';

class WriteImageSection extends StatelessWidget {
  final List<File> images;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onRemove;
  final VoidCallback onPick;
  final Color fillColor;

  const WriteImageSection({
    super.key,
    required this.images,
    required this.onReorder,
    required this.onRemove,
    required this.onPick,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty)
          SizedBox(
            height: Responsive.r(context, 100),
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              onReorder: onReorder,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: child,
              ),
              itemBuilder: (context, index) {
                return Padding(
                  key: ValueKey(images[index].path),
                  padding: EdgeInsets.only(right: index < images.length - 1 ? 8 : 0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(images[index], width: Responsive.r(context, 100), height: Responsive.r(context, 100), fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4, right: 4,
                        child: GestureDetector(
                          onTap: () => onRemove(index),
                          child: Container(
                            width: Responsive.r(context, 22), height: Responsive.r(context, 22),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, size: Responsive.r(context, 14), color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4, left: 4,
                        child: Container(
                          width: Responsive.r(context, 20), height: Responsive.r(context, 20),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(child: Text('${index + 1}',
                            style: TextStyle(color: Colors.white, fontSize: Responsive.sp(context, 11), fontWeight: FontWeight.w700))),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (images.length < 5) ...[
          if (images.isNotEmpty) const SizedBox(height: 8),
          GestureDetector(
            onTap: onPick,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: Responsive.r(context, 18), color: AppColors.theme.darkGreyColor),
                  const SizedBox(width: 6),
                  Text(AppLocalizations.of(context)!.write_imageAddButton(images.length, 5),
                    style: TextStyle(fontSize: Responsive.sp(context, 13), color: AppColors.theme.darkGreyColor)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
