import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 글쓰기 화면의 이미지 첨부 섹션
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
            height: 100,
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
                        child: Image.file(images[index], width: 100, height: 100, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4, right: 4,
                        child: GestureDetector(
                          onTap: () => onRemove(index),
                          child: Container(
                            width: 22, height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4, left: 4,
                        child: Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(child: Text('${index + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
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
                  Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.theme.darkGreyColor),
                  const SizedBox(width: 6),
                  Text('사진 추가 (${images.length}/5)',
                    style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
