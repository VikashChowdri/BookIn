import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Discover Books',
      'description':
          'Find college books from students around you and discover what you need.',
      'icon': 'search',
    },
    {
      'title': 'Buy, Rent or Exchange',
      'description':
          'Get the books you need without spending more than necessary.',
      'icon': 'swap',
    },
    {
      'title': 'Connect with Students',
      'description':
          'Chat with other students and make book sharing simple and convenient.',
      'icon': 'people',
    },
  ];

  IconData getIcon(String icon) {
    if (icon == 'search') {
      return Icons.search_rounded;
    } else if (icon == 'swap') {
      return Icons.swap_horiz_rounded;
    } else {
      return Icons.people_rounded;
    }
  }

  void nextPage() {
    if (currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void skipOnboarding() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [

            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: skipOnboarding,
                  child: const Text('Skip'),
                ),
              ),
            ),

            // Onboarding pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,

                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },

                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        const SizedBox(height: 20),

                        // Illustration
                        Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            getIcon(
                              onboardingData[index]['icon']!,
                            ),
                            size: 90,
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Title
                        Text(
                          onboardingData[index]['title']!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          onboardingData[index]['description']!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                height: 1.5,
                              ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    height: 8,
                    width: currentPage == index ? 25 : 8,
                    decoration: BoxDecoration(
                      color: currentPage == index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: nextPage,
                  child: Text(
                    currentPage == onboardingData.length - 1
                        ? 'Get Started'
                        : 'Next',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}