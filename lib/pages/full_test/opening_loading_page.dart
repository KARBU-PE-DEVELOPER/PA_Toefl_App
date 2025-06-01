import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:toefl/models/test/test_status.dart';
import 'package:toefl/remote/local/shared_pref/test_shared_preferences.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/state_management/full_test_provider.dart';

class OpeningLoadingPage extends ConsumerStatefulWidget {
  const OpeningLoadingPage({
    super.key,
    required this.packetId,
    required this.isRetake,
    required this.packetName,
    required this.packetType,
  });

  final String packetId;
  final bool isRetake;
  final String packetName;
  final String packetType;

  @override
  ConsumerState<OpeningLoadingPage> createState() => _OpeningLoadingPageState();
}

class _OpeningLoadingPageState extends ConsumerState<OpeningLoadingPage>
    with WidgetsBindingObserver {
  bool _isNavigatingToTest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupSecureMode();
    _onInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restoreNormalMode();
    super.dispose();
  }

  void _setupSecureMode() {
    // Hide system navigation bar dan status bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    // Set app ke fullscreen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  void _restoreNormalMode() {
    // Kembalikan system UI normal
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    // Reset orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Jika app di-minimize atau di-pause, paksa kembali ke foreground
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (!_isNavigatingToTest && mounted) {
        // Coba paksa app kembali ke foreground dengan delay
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            // Reset secure mode jika app kembali
            _setupSecureMode();
          }
        });
      }
    }

    // Ketika app resumed, pastikan secure mode masih aktif
    if (state == AppLifecycleState.resumed) {
      if (!_isNavigatingToTest && mounted) {
        _setupSecureMode();
      }
    }
  }

  Future<void> _onInit() async {
    final TestSharedPreference sharedPref = TestSharedPreference();
    final status = await sharedPref.getStatus();

    DateTime startDate = DateTime.now();
    if (status != null) {
      startDate = DateTime.parse(status.startTime);
    } else {
      await sharedPref.saveStatus(TestStatus(
          id: widget.packetId.toString(),
          startTime: DateTime.now().toIso8601String(),
          name: widget.packetName,
          resetTable: true,
          isRetake: widget.isRetake));
    }
    await ref.read(fullTestProvider.notifier).onInit();
    await Future.delayed(const Duration(seconds: 4));
    debugPrint(
        "OpeningLoadingPage: ${widget.packetId}, ${widget.packetName}, ${widget.packetType}, ${widget.isRetake}");

    final diff = DateTime.now().difference(startDate);
    if (!mounted) {
      return;
    } else {
      setState(() {
        _isNavigatingToTest = true;
      });

      Navigator.pushNamed(
        context,
        RouteKey.fullTest,
        arguments: {
          "diffInSeconds": diff.inSeconds + 4,
          "isRetake": widget.isRetake,
          "packetType": widget.packetType,
        },
      ).then((value) {
        Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false, // Mencegah back navigation
      onPopInvoked: (didPop) {
        // Tidak melakukan apa-apa untuk benar-benar disable back
        return;
      },
      child: Scaffold(
        backgroundColor: Colors.black, // Background hitam untuk keamanan
        extendBodyBehindAppBar: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: Stack(
            children: [
              // Overlay untuk intercept semua gesture/touch
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    // Intercept tap tapi tidak lakukan apa-apa
                  },
                  onPanStart: (_) {
                    // Intercept pan gesture
                  },
                  onPanUpdate: (_) {
                    // Intercept pan update
                  },
                  onPanEnd: (_) {
                    // Intercept pan end
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),

              // Main content
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            height: screenHeight * 0.03), // Responsive spacing

                        // Main loading text
                        const Text(
                          "Preparing your test...",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.025),

                        // Warning container
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.red.shade300,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade100,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red.shade600,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "⚠️ IMPORTANT WARNING ⚠️",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "• Do NOT press back button\n• Do NOT press home button\n• Do NOT open recent apps\n• Do NOT switch to other apps\n\nPlease wait until loading completes",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade600,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.04),

                        // Progress indicator
                        Container(
                          width: screenWidth * 0.6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const LinearProgressIndicator(
                            backgroundColor: Colors.grey,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                            minHeight: 6,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        // Loading status text
                        const Text(
                          "Setting up secure environment...",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        // Extra bottom padding untuk memastikan tidak terpotong
                        SizedBox(height: screenHeight * 0.05),
                      ],
                    ),
                  ),
                ),
              ),

              // Extra security overlay untuk corner cases
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 50,
                child: Container(
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
