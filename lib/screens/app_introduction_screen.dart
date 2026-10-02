import 'package:flutter/material.dart';

class AppIntroductionScreen extends StatefulWidget {
  const AppIntroductionScreen({super.key});

  @override
  State<AppIntroductionScreen> createState() => _AppIntroductionScreenState();
}

class _AppIntroductionScreenState extends State<AppIntroductionScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<Map<String, dynamic>> _introPages = [
    {
      'title': 'Personalized Exercise Plans',
      'description':
          'Get customized exercise routines based on your mood, pain points, and fitness goals.',
      'icon': Icons.fitness_center,
      'color': const Color(0xFF059669),
    },
    {
      'title': 'Track Your Progress',
      'description':
          'Monitor your health metrics and exercise history to see your improvement over time.',
      'icon': Icons.insert_chart,
      'color': const Color(0xFF1FCC79),
    },
    {
      'title': 'Adaptive Workouts',
      'description':
          'CAREX adjusts to your needs, providing exercises that match your current physical state.',
      'icon': Icons.psychology,
      'color': const Color(0xFFF55A5A),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _goToNextPage() {
    if (_currentPage < _introPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishIntroduction();
    }
  }

  void _finishIntroduction() {
    Navigator.pushReplacementNamed(context, '/signin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF059669),
              const Color(0xFF047857),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _introPages.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final page = _introPages[index];
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              page['icon'],
                              size: 100,
                              color: page['color'],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            page['title'],
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            page['description'],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Page indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _introPages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _currentPage == index ? 20 : 10,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: _currentPage == index
                                ? const Color(0xFF059669)
                                : const Color(0xFFD8D8D8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (_currentPage < _introPages.length - 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _finishIntroduction,
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _goToNextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Next',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Center(
                        child: SizedBox(
                          width: 200,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _goToNextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
