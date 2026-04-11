import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  List<_OnboardingPage> _pages(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return [
      _OnboardingPage(
        icon: Icons.restaurant,
        title: l.onboarding_meal,
        description: l.onboarding_mealDesc,
        color: const Color(0xFF4CAF50),
      ),
      _OnboardingPage(
        icon: Icons.calendar_view_week,
        title: l.onboarding_timetable,
        description: l.onboarding_timetableDesc,
        color: const Color(0xFF2196F3),
      ),
      _OnboardingPage(
        icon: Icons.event,
        title: l.onboarding_schedule,
        description: l.onboarding_scheduleDesc,
        color: const Color(0xFFFF9800),
      ),
      _OnboardingPage(
        icon: Icons.forum,
        title: l.onboarding_board,
        description: l.onboarding_boardDesc,
        color: const Color(0xFF9C27B0),
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await Permission.notification.request();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pages = _pages(context);
    final isLast = _currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(l.onboarding_skip, style: TextStyle(color: AppColors.theme.darkGreyColor)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = pages[index];
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
                    children: List.generate(pages.length, (i) =>
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
                        isLast ? l.onboarding_start : l.onboarding_next,
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
