/// SRIBEESonline - Splash Screen
///
/// App-launch flow:
///   1. Copy the local asset video to the app's cache directory (first launch).
///   2. Play the video via [VideoPlayerController.file] — most reliable on Android.
///   3. Simultaneously fetch dynamic video URL from `GET /api/v1/app/splash-config`.
///      If a dynamic URL exists, it plays that instead on the next launch.
///   4. When the video ends (or on error → show logo for 2 s), determine
///      the next screen by inspecting SharedPreferences:
///        - language_code missing → [LanguageSelectionScreen]
///        - branch_id missing    → [AddressSelectionScreen]
///        - both present         → [HomeScreen]
///
/// Uses VideoPlayerController.file() instead of .asset() for maximum
/// Android compatibility (avoids ExoPlayer asset-bundle access issues).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/api/api_client.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/providers/branch_provider.dart';
import '../../../core/providers/language_provider.dart';
import 'language_selection_screen.dart';
import 'address_selection_screen.dart';
import '../../home/screens/home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _navigating = false;

  // Logo fade-in animation
  late final AnimationController _logoAnim;
  late final Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    _logoAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoOpacity = CurvedAnimation(parent: _logoAnim, curve: Curves.easeIn);
    _initSplash();
  }

  // ========================================================================
  // Initialisation
  // ========================================================================

  Future<void> _initSplash() async {
    await _initLocalAssetVideo();
  }

  /// Play the local video asset directly.
  /// This is the most robust and standard approach in Flutter.
  Future<void> _initLocalAssetVideo() async {
    // Clean up old controller
    if (_videoController != null) {
      _videoController!.removeListener(_onVideoUpdate);
      await _videoController!.dispose();
      _videoController = null;
    }

    final controller = VideoPlayerController.asset('assets/videos/splash.mp4');
    _videoController = controller;

    try {
      await controller.initialize();

      if (!mounted) return;

      if (kDebugMode) {
        final size = controller.value.size;
        final dur = controller.value.duration;
        print('Splash: video initialised — ${size.width}x${size.height}, $dur');
      }

      controller.addListener(_onVideoUpdate);
      await controller.play();

      setState(() => _videoReady = true);
    } catch (e) {
      if (kDebugMode) print('Splash: VideoPlayerController.asset failed — $e');
      await controller.dispose();
      _videoController = null;
      _showLogoFallback();
    }
  }

  /// Fetch the dynamic splash-video URL from the backend (for future use).
  Future<String?> _fetchSplashVideoUrl() async {
    try {
      final api = ref.read(apiClientProvider);
      final response =
          await api.get<Map<String, dynamic>>('/app/splash-config');

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) return null;

      final isActive = data['is_active'] == true;
      if (!isActive) return null;

      return data['splash_video_url'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Called on every video-player tick.
  void _onVideoUpdate() {
    final c = _videoController;
    if (c == null || _navigating) return;

    // Navigate once the video reaches the end.
    if (c.value.isInitialized &&
        c.value.position >= c.value.duration &&
        c.value.duration > Duration.zero) {
      _navigateToNextScreen();
    }
  }

  /// Show the static logo for 2 seconds and then navigate.
  void _showLogoFallback() {
    if (!mounted) return;
    setState(() => _videoReady = false);
    _logoAnim.forward();
    Future.delayed(const Duration(seconds: 2), _navigateToNextScreen);
  }

  // ========================================================================
  // Navigation
  // ========================================================================

  void _navigateToNextScreen() {
    if (_navigating || !mounted) return;
    _navigating = true;

    final hasLanguage = ref.read(hasLanguageProvider);
    final hasBranch = ref.read(hasBranchProvider);

    Widget nextScreen;
    if (!hasLanguage) {
      nextScreen = const LanguageSelectionScreen();
    } else if (!hasBranch) {
      nextScreen = const AddressSelectionScreen();
    } else {
      nextScreen = const HomeScreen();
    }

    pushAndClearFade(context, nextScreen);
  }

  // ========================================================================
  // Lifecycle
  // ========================================================================

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    _logoAnim.dispose();
    super.dispose();
  }

  // ========================================================================
  // Build
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _videoReady ? Colors.black : Colors.white,
      body: _videoReady ? _buildVideoPlayer() : _buildLogoFallback(),
    );
  }

  Widget _buildVideoPlayer() {
    final controller = _videoController!;
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildLogoFallback() {
    return Center(
      child: FadeTransition(
        opacity: _logoOpacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Branding icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_grocery_store_rounded,
                size: 60,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SRIBEESonline',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fresh groceries, delivered.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
