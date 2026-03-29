import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class ThemeStyleScreen extends StatelessWidget {
  const ThemeStyleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('테마 설정'),
        backgroundColor: AppColors.theme.primaryColor,
      ),
      body: const Center(
        child: Text('테마 설정은 설정 화면에서 변경할 수 있습니다.'),
      ),
    );
  }
}
