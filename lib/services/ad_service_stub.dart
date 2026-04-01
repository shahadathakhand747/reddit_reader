import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web implementation of AdService (placeholder)
class AdService {
  static AdService? _instance;
  int _postsLoadedCount = 0;
  int _rewardedVideoRedemptionCount = 0;
  DateTime _lastRewardResetDate = DateTime.now();
  static const int maxDailyRedemptions = 6;
  static const int interstitialInterval = 5;
  bool _isInitialized = false;

  AdService._();

  static AdService get instance {
    _instance ??= AdService._();
    return _instance!;
  }

  bool get isWeb => true;
  bool get isAndroid => false;
  bool get isInitialized => _isInitialized;

  int get remainingRedemptions {
    _checkAndResetDailyCount();
    return maxDailyRedemptions - _rewardedVideoRedemptionCount;
  }

  Future<void> init() async {
    debugPrint('AdService (Web): Placeholder mode');
    await _loadRedemptionCount();
    _checkAndResetDailyCount();
    _isInitialized = true;
  }

  Future<void> loadBannerAd() async {}
  Future<void> loadInterstitialAd() async {}
  Future<void> loadRewardedVideoAd() async {}
  Future<void> showBannerAd() async {}
  void hideBannerAd() {}

  Future<void> showInterstitialAd() async {
    debugPrint('AdService (Web): Interstitial placeholder shown');
  }

  Future<bool> showRewardedVideoAd() async {
    debugPrint('AdService (Web): Rewarded video placeholder');
    _checkAndResetDailyCount();
    if (_rewardedVideoRedemptionCount < maxDailyRedemptions) {
      await Future.delayed(const Duration(seconds: 2));
      _rewardedVideoRedemptionCount++;
      await _saveRedemptionCount();
      return true;
    }
    return false;
  }

  void onPostLoaded() {
    _postsLoadedCount++;
  }

  void resetPostCount() {
    _postsLoadedCount = 0;
  }

  bool shouldShowInterstitial() {
    return false; // No real ads on web
  }

  void _checkAndResetDailyCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = DateTime(_lastRewardResetDate.year, _lastRewardResetDate.month, _lastRewardResetDate.day);
    if (today.isAfter(lastReset)) {
      _rewardedVideoRedemptionCount = 0;
      _lastRewardResetDate = now;
    }
  }

  Future<void> _loadRedemptionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _rewardedVideoRedemptionCount = prefs.getInt('rewarded_video_count') ?? 0;
      final lastResetStr = prefs.getString('rewarded_video_last_reset');
      if (lastResetStr != null) {
        _lastRewardResetDate = DateTime.parse(lastResetStr);
      }
    } catch (e) {
      debugPrint('AdService: Failed to load redemption count: $e');
    }
  }

  Future<void> _saveRedemptionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('rewarded_video_count', _rewardedVideoRedemptionCount);
      await prefs.setString('rewarded_video_last_reset', _lastRewardResetDate.toIso8601String());
    } catch (e) {
      debugPrint('AdService: Failed to save redemption count: $e');
    }
  }

  void dispose() {}
}

/// Banner ad widget for web (placeholder)
class AdBannerWidget extends StatelessWidget {
  final double height;
  const AdBannerWidget({super.key, this.height = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF333333), width: 1),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ad_units, color: Color(0xFFFF4500), size: 20),
            SizedBox(height: 2),
            Text('Ad Placeholder', style: TextStyle(color: Color(0xFF888888), fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// Rewarded video button for web (placeholder)
class RewardedVideoButton extends StatefulWidget {
  final VoidCallback? onRewardEarned;
  const RewardedVideoButton({super.key, this.onRewardEarned});
  @override
  State<RewardedVideoButton> createState() => _RewardedVideoButtonState();
}

class _RewardedVideoButtonState extends State<RewardedVideoButton> {
  bool _isLoading = false;
  int get _remaining => AdService.instance.remainingRedemptions;

  Future<void> _onTap() async {
    if (_isLoading) return;
    if (_remaining <= 0) {
      showDialog(context: context, builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Daily Limit Reached', style: TextStyle(color: Color(0xFFFF4500))),
        content: const Text('Come back tomorrow!', style: TextStyle(color: Color(0xFFCCCCCC))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ));
      return;
    }
    setState(() => _isLoading = true);
    final success = await AdService.instance.showRewardedVideoAd();
    if (mounted) {
      setState(() => _isLoading = false);
      if (success && widget.onRewardEarned != null) widget.onRewardEarned!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF4500), Color(0xFFFF6B35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              else
                const Icon(Icons.play_circle_filled, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              const Text('REDEEM', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: Text('$_remaining', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
