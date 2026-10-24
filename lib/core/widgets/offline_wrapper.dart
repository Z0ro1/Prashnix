import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class OfflineWrapper extends StatefulWidget {
  final Widget child;

  const OfflineWrapper({super.key, required this.child});

  @override
  State<OfflineWrapper> createState() => _OfflineWrapperState();
}

class _OfflineWrapperState extends State<OfflineWrapper> {
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // If it only contains 'none', or if the list is empty, device is offline.
    final isOffline = results.isEmpty || (results.length == 1 && results.first == ConnectivityResult.none);
    if (mounted && _isOffline != isOffline) {
      setState(() {
        _isOffline = isOffline;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOffline)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: Container(
                color: AppColors.background.withOpacity(0.97), // Slight transparency to show app underneath
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Creative Animated Visual
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ripple effect
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                            )
                            .animate(onPlay: (controller) => controller.repeat())
                            .scale(duration: 2.seconds, begin: const Offset(0.7, 0.7), end: const Offset(1.4, 1.4))
                            .fadeOut(duration: 2.seconds),
                            
                            // Core icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.error,
                                    blurRadius: 20,
                                    spreadRadius: -5,
                                  )
                                ]
                              ),
                              child: const Icon(
                                Icons.wifi_off_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .scaleXY(begin: 1.0, end: 1.1, duration: 1.2.seconds, curve: Curves.easeInOut),
                          ],
                        ),
                        const SizedBox(height: 48),
                        
                        // Clear Message
                        const Text(
                          "Connection Lost!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ).animate().slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutCubic).fadeIn(),
                        
                        const SizedBox(height: 16),
                        
                        const Text(
                          "Prashnix needs an active internet connection to sync your progress, update the leaderboard, and fetch new questions.\n\nPlease connect to Wi-Fi or mobile data to continue learning.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ).animate().slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutCubic).fadeIn(delay: 200.ms),
                        
                        const SizedBox(height: 48),
                        
                        // Waiting Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Waiting for connection...",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              )
                              .animate(onPlay: (controller) => controller.repeat(reverse: true))
                              .fade(begin: 0.4, end: 1.0, duration: 1.seconds),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms).scaleXY(begin: 0.9, end: 1.0),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),
      ],
    );
  }
}
