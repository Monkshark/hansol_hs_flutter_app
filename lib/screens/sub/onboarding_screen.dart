/** Onboarding screen introducing app features with swipeable pages on first launch. */
import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/**
 * 온보딩 화면 (OnboardingScreen)
 *
 * - 첫 실행 시 4페이지 슬라이드로 주요 기능 안내
 * - 급식, 시간표, 일정 관리, 게시판 기능 소개
 * - 완료 시 SharedPreferences에 플래그 저장하여 재표시 방지
 */
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.restaurant,
      title: '급식 정보',
      description: '조식/중식/석식 메뉴를\n한눈에 확인하세요',
      color: Color(0xFF4CAF50),
    ),
    _OnboardingPage(
      icon: Icons.calendar_view_week,
      title: '시간표',
      description: '선택과목 기반 시간표를\n자동으로 구성해드려요',
      color: Color(0xFF2196F3),
    ),
    _OnboardingPage(
      icon: Icons.event,
      title: '일정 관리',
      description: '개인 일정과 학사일정을\n한 곳에서 관리하세요',
      color: Color(0xFFFF9800),
    ),
    _OnboardingPage(
      icon: Icons.forum,
      title: '게시판',
      description: '자유롭게 소통하고\n투표, 일정 공유도 가능해요',
      color: Color(0xFF9C27B0),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('건너뛰기', style: TextStyle(color: AppColors.theme.darkGreyColor)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          color: page.color.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(page.icon, size: 68, color: page.color),
                      ),
                      const SizedBox(height: 40),
                      Text(page.title, style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
                      const SizedBox(height: 14),
                      Text(page.description, style: TextStyle(
                        fontSize: 17, color: AppColors.theme.darkGreyColor, height: 1.6),
                        textAlign: TextAlign.center),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  Row(
                    children: List.generate(_pages.length, (i) =>
                      Container(
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.theme.primaryColor
                              : AppColors.theme.darkGreyColor.withAlpha(60),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // 다음/시작 버튼
                  GestureDetector(
                    onTap: isLast
                        ? _finish
                        : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.theme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isLast ? '시작하기' : '다음',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
