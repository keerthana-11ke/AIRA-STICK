import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'auth_choice_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool readOnly;

  const OnboardingScreen({super.key, this.readOnly = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (widget.readOnly) {
      // In read-only mode (called from Dashboard), simply go back
      Navigator.of(context).pop();
    } else {
      // On first launch, save preference flag and route to choice selection
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstLaunch', false);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AuthChoiceScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Slide Pages Content
            PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSlide(
                  context: context,
                  title: "Welcome to AIRA",
                  description: "AIRA Guardian is a companion application designed exclusively for the caretakers of visually impaired users. The blind user interacts only with the physical AIRA Smart Stick, while you monitor and supervise coordinates from this app.",
                  icon: Icons.visibility_rounded,
                  accentColor: AppTheme.primaryMahogany,
                  illustrationType: OnboardingIllustration.welcome,
                ),
                _buildSlide(
                  context: context,
                  title: "Pair the Smart Stick",
                  description: "Establish a secure, real-time Bluetooth link between this guardian app and the smart stick during setup to begin receiving distance measurements, battery statuses, and sensor configurations.",
                  icon: Icons.bluetooth_searching_rounded,
                  accentColor: AppTheme.highlightApricot,
                  illustrationType: OnboardingIllustration.pair,
                ),
                _buildSlide(
                  context: context,
                  title: "Voice Alerts & SOS",
                  description: "The Smart Stick speaks acoustic speech warnings (like 'Obstacle Ahead') to the user and triggers cellular GSM SMS backup alerts containing real-time GPS coordinates directly to your phone when the physical SOS button is pressed.",
                  icon: Icons.volume_up_rounded,
                  accentColor: AppTheme.emergencyRed,
                  illustrationType: OnboardingIllustration.alerts,
                ),
                _buildSlide(
                  context: context,
                  title: "Guardian Dashboard",
                  description: "Check the status card indicators on the dashboard to review active telemetry logs, front obstacles, drop-off pits, stick hardware configurations, DFPlayer audio status, and bluetooth signal link qualities.",
                  icon: Icons.dashboard_rounded,
                  accentColor: AppTheme.primaryMahogany,
                  illustrationType: OnboardingIllustration.dashboard,
                ),
                _buildSlide(
                  context: context,
                  title: "Safety & Emergency Tips",
                  description: "Ensure the stick's dual sonar grilles remain clean, charge the device battery immediately when telemetry drops below 15%, and remember that this app serves to assist, always verify safety manually during emergencies.",
                  icon: Icons.gpp_maybe_rounded,
                  accentColor: AppTheme.accentRose,
                  illustrationType: OnboardingIllustration.safety,
                ),
              ],
            ),

            // Top exit controls (Close button for read-only view, Skip for onboarding view)
            Positioned(
              top: 10,
              right: 16,
              child: widget.readOnly
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 28),
                      tooltip: "Close Guide",
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text("Skip"),
                    ),
            ),

            // Bottom controls overlay
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Smooth page indicator dots
                  Row(
                    children: List.generate(_numPages, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryMahogany
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Dynamic Next/Get Started Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(130, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      if (_currentPage == _numPages - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == _numPages - 1
                          ? (widget.readOnly ? "Finish Guide" : "Get Started")
                          : "Next",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

  Widget _buildSlide({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required OnboardingIllustration illustrationType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 90),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Illustration Box
          Expanded(
            child: Center(
              child: _buildIllustration(illustrationType, accentColor),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Icon Label Accent
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 8),
              Text(
                "AIRA System Guide".toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Slide Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Slide Description text
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildIllustration(OnboardingIllustration type, Color accentColor) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accentColor.withOpacity(0.04),
        border: Border.all(color: accentColor.withOpacity(0.1), width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer decorative concentric ring
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withOpacity(0.12), width: 1),
            ),
          ),
          // Inner decorative concentric ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withOpacity(0.18), width: 1.5),
            ),
          ),
          // Custom Icon representation based on onboarding slide
          _getIllustrationIcon(type, accentColor),
        ],
      ),
    );
  }

  Widget _getIllustrationIcon(OnboardingIllustration type, Color accentColor) {
    switch (type) {
      case OnboardingIllustration.welcome:
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.asset(
              "assets/images/logo.jpg",
              width: 140,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
        );
      case OnboardingIllustration.pair:
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.bluetooth, size: 70, color: accentColor),
              Positioned(
                right: 15,
                top: 15,
                child: Icon(Icons.settings_input_antenna, size: 24, color: AppTheme.primaryMahogany),
              ),
            ],
          ),
        );
      case OnboardingIllustration.alerts:
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.notifications_active_rounded, size: 70, color: accentColor),
              Positioned(
                left: 10,
                bottom: 10,
                child: Icon(Icons.sms_rounded, size: 28, color: AppTheme.highlightApricot),
              ),
            ],
          ),
        );
      case OnboardingIllustration.dashboard:
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.analytics_rounded, size: 70, color: accentColor),
              Positioned(
                right: 10,
                bottom: 10,
                child: Icon(Icons.bolt, size: 32, color: AppTheme.highlightApricot),
              ),
            ],
          ),
        );
      case OnboardingIllustration.safety:
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.health_and_safety_rounded, size: 75, color: accentColor),
              Positioned(
                top: 25,
                child: Icon(Icons.tips_and_updates, size: 22, color: AppTheme.highlightApricot),
              ),
            ],
          ),
        );
    }
  }
}

enum OnboardingIllustration {
  welcome,
  pair,
  alerts,
  dashboard,
  safety,
}
