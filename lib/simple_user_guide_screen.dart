import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SimpleUserGuideScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SimpleUserGuideScreen({super.key, required this.onComplete});

  @override
  State<SimpleUserGuideScreen> createState() => _SimpleUserGuideScreenState();
}

class _SimpleUserGuideScreenState extends State<SimpleUserGuideScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showAgain = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeGuide() async {
    if (!_showAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_user_guide', false);
    }
    widget.onComplete();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeGuide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final List<Map<String, String>> guidePages = [
      {
        'title': l10n.userGuideStep1Title,
        'description': l10n.userGuideStep1Description,
      },
      {
        'title': l10n.userGuideStep2Title,
        'description': l10n.userGuideStep2Description,
      },
      {
        'title': l10n.userGuideStep3Title,
        'description': l10n.userGuideStep3Description,
      },
      {
        'title': l10n.userGuideStep4Title,
        'description': l10n.userGuideStep4Description,
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.userGuideTitle,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _completeGuide,
                    child: Text(l10n.userGuideSkipButton),
                  ),
                ],
              ),
            ),
            Text(
              l10n.userGuideSubtitle,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: guidePages.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final page = guidePages[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 使用内置图标
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _getIconForPage(index),
                            size: 80,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page['title']!,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page['description']!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  guidePages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  Checkbox(
                    value: _showAgain,
                    onChanged: (value) {
                      setState(() {
                        _showAgain = value ?? true;
                      });
                    },
                  ),
                  Text(
                    _showAgain
                        ? l10n.userGuideShowNextTime // "下次启动时显示"
                        : l10n.userGuideShowAgain, // "不再显示"
                    style: TextStyle(
                      color: _showAgain ? null : Colors.red,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _currentPage < guidePages.length - 1
                          ? l10n.userGuideNextButton
                          : l10n.userGuideDoneButton,
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

  IconData _getIconForPage(int index) {
    switch (index) {
      case 0:
        return Icons.mic;
      case 1:
        return Icons.auto_awesome;
      case 2:
        return Icons.description;
      case 3:
        return Icons.save;
      default:
        return Icons.help_outline;
    }
  }
}

// 检查是否应该显示用户引导
Future<bool> shouldShowUserGuide() async {
  final prefs = await SharedPreferences.getInstance();
  // 默认为 true，表示首次安装应该显示引导
  return prefs.getBool('show_user_guide') ?? true;
}
