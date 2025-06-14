import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toefl/remote/local/shared_pref/auth_shared_preferences.dart';
import 'package:toefl/remote/local/shared_pref/onboarding_shared_preferences.dart';

import '../routes/route_key.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final OnBoardingSharedPreference onBoardingSharedPreference =
        OnBoardingSharedPreference();
    bool isOnAppInit = await onBoardingSharedPreference.isOnInit();

    if (isOnAppInit) {
      Navigator.of(context).pushReplacementNamed(RouteKey.onBoarding);
      return; 
    } else {
      final AuthSharedPreference authSharedPreference = AuthSharedPreference();
      final isVerified = await authSharedPreference.getVerifiedAccount();
      await authSharedPreference.getBearerToken().then((value) async {
        final bool isLogin = (value ?? "").isNotEmpty;
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          if (isLogin && isVerified) {
            Navigator.of(context).pushReplacementNamed(RouteKey.main);
          } else {
            Navigator.of(context).pushReplacementNamed(RouteKey.login);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, // Atau sesuai dengan theme app Anda
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.1, // 10% margin kiri-kanan
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo utama
              Container(
                constraints: BoxConstraints(
                  maxWidth: screenWidth * 0.6, // Maksimal 60% lebar layar
                  maxHeight: screenHeight * 0.3, // Maksimal 30% tinggi layar
                ),
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  fit: BoxFit.contain, // Maintain aspect ratio
                ),
              ),

              const SizedBox(height: 30),

              // Loading indicator (opsional)
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),

              const SizedBox(height: 20),

              // Loading text (opsional)
              const Text(
                "Loading...",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
