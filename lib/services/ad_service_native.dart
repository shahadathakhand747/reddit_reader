import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startapp_sdk/startapp.dart';

/// Android implementation of AdService with real StartApp SDK integration
/// App ID: 202746890
class AdService {
  static AdService? _instance;
  late StartAppSdk _startAppSdk;

  StartAppBannerAd? _bannerAd;
  StartAppInterstitialAd? _interstitialAd;
  StartAppRewardedVideoAd? _rewardedVideoAd;

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

  bool get isWeb => kIsWeb;
  bool get isAndroid => !kIsWeb;
  bool get isInitialized => _isInitialized;

  int get remainingRedemptions {
    _checkAndResetDailyCount();
    return maxDailyRedemptions - _rewardedVideoRedemptionCount;
  }

  Future<void> init() async {
    debugPrint('AdService: Initializing StartApp SDK...');

    await _loadRedemptionCount();
    _checkAndResetDailyCount();

    try {
      _startAppSdk = StartAppSdk();
      // Real ads - test mode disabled
      debugPrint('AdService: StartApp SDK initialized successfully');
    } catch (e) {
      debugPrint('AdService: StartApp init error: $e');
    }

    _isInitialized = true;
  }

  Future<void> loadBannerAd() async {
    if (!isAndroid) return;
    try {
      _bannerAd = await _startAppSdk.loadBannerAd(StartAppBannerType.BANNER);
      debugPrint('AdService: Banner ad loaded');
    } catch (e) {
      debugPrint('AdService: Banner load error: $e');
    }
  }

  Future<void> loadInterstitialAd() async {
    if (!isAndroid) return;
    try {
      _interstitialAd = await _startAppSdk.loadInterstitialAd(
        onAdHidden: () {
          debugPrint('AdService: Interstitial hidden');
          _interstitialAd?.dispose();
          _interstitialAd = null;
        },
      );
      debugPrint('AdService: Interstitial ad loaded');
    } catch (e) {
      debugPrint('AdService: Interstitial load error: $e');
    }
  }

  Future<void> loadRewardedVideoAd() async {
    if (!isAndroid) return;
    try {
      _rewardedVideoAd = await _startAppSdk.loadRewardedVideoAd(
        onAdHidden: () {
          debugPrint('AdService: Rewarded video hidden');
          _rewardedVideoAd?.dispose();
          _rewardedVideoAd = null;
        },
        onVideoCompleted: () {
          debugPrint('AdService: Rewarded video completed');
          _onRewardedVideoCompleted();
        },
      );
      debugPrint('AdService: Rewarded video ad loaded');
    } catch (e) {
      debugPrint('AdService: Rewarded video load error: $e');
    }
  }

  void showInterstitialAd() {
    if (!isAndroid || _interstitialAd == null) return;

    HapticFeedback.mediumImpact();

    _interstitialAd!.show().then((shown) {
      if (shown) {
        _interstitialAd = null;
        loadInterstitialAd();
      }
    });
  }

  Future<bool> showRewardedVideoAd() async {
    if (!isAndroid) return false;

    _checkAndResetDailyCount();
    if (_rewardedVideoRedemptionCount >= maxDailyRedemptions) {
      debugPrint('AdService: Daily redemption limit reached');
      return false;
    }

    if (_rewardedVideoAd == null) {
      debugPrint('AdService: Rewarded video not loaded');
      return false;
    }

    HapticFeedback.heavyImpact();

    final result = await _rewardedVideoAd!.show().then((shown) => shown ?? false);
    _rewardedVideoAd = null;
    loadRewardedVideoAd();
    return result;
  }

  Future<void> _onRewardedVideoCompleted() async {
    _rewardedVideoRedemptionCount++;
    await _saveRedemptionCount();
    debugPrint('AdService: Reward earned! Total today: $_rewardedVideoRedemptionCount/$maxDailyRedemptions');
  }

  void onPostLoaded() {
    _postsLoadedCount++;
    if (shouldShowInterstitial()) {
      debugPrint('AdService: Triggering interstitial at $_postsLoadedCount posts');
      if (_interstitialAd == null) {
        loadInterstitialAd();
      } else {
        showInterstitialAd();
      }
    }
  }

  void resetPostCount() {
    _postsLoadedCount = 0;
  }

  bool shouldShowInterstitial() {
    return _postsLoadedCount > 0 && _postsLoadedCount % interstitialInterval == 0;
  }

  void _checkAndResetDailyCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = DateTime(_lastRewardResetDate.year, _lastRewardResetDate.month, _lastRewardResetDate.day);
    if (today.isAfter(lastReset)) {
      _rewardedVideoRedemptionCount = 0;
      _lastRewardResetDate = now;
      debugPrint('AdService: Daily redemption count reset');
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

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedVideoAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    _rewardedVideoAd = null;
    _postsLoadedCount = 0;
  }
}

/// Banner ad widget for Android with StartApp
class AdBannerWidget extends StatefulWidget {
  final double height;
  const AdBannerWidget({super.key, this.height = 60});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  StartAppBannerAd? _bannerAd;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    try {
      _bannerAd = await AdService.instance._startAppSdk.loadBannerAd(
        StartAppBannerType.BANNER,
        prefs: const StartAppAdPreferences(adTag: 'banner_widget'),
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('AdService: Banner load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border.all(color: const Color(0xFF333333), width: 1),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFF4500),
            ),
          ),
        ),
      );
    }

    if (_bannerAd == null) {
      return Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border.all(color: const Color(0xFF333333), width: 1),
        ),
        child: const Center(
          child: Icon(Icons.ad_units, color: Color(0xFFFF4500), size: 24),
        ),
      );
    }

    return Container(
      height: widget.height,
      width: double.infinity,
      color: const Color(0xFF1A1A1A),
      child: StartAppBanner(_bannerAd!),
    );
  }
}

/// Rewarded video button for Android
class RewardedVideoButton extends StatefulWidget {
  final VoidCallback? onRewardEarned;
  const RewardedVideoButton({super.key, this.onRewardEarned});

  @override
  State<RewardedVideoButton> createState() => _RewardedVideoButtonState();
}

class _RewardedVideoButtonState extends State<RewardedVideoButton> {
  bool _isLoading = false;
  bool _showSuccess = false;
  int get _remaining => AdService.instance.remainingRedemptions;

  Future<void> _onTap() async {
    if (_isLoading) return;
    if (_remaining <= 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Daily Limit Reached',
              style: TextStyle(color: Color(0xFFFF4500))),
          content: const Text(
              'You\'ve already redeemed your daily limit of 6 rewards. Come back tomorrow!',
              style: TextStyle(color: Color(0xFFCCCCCC))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'))
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Load rewarded video first
    await AdService.instance.loadRewardedVideoAd();
    final success = await AdService.instance.showRewardedVideoAd();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _showSuccess = success;
      });
      if (success && widget.onRewardEarned != null) {
        widget.onRewardEarned!();
      }
      if (success) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _showSuccess = false);
      }
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
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4500), Color(0xFFFF6B35)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4500).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ))
              else if (_showSuccess)
                const Icon(Icons.check_circle, color: Colors.white, size: 18)
              else
                const Icon(Icons.play_circle_filled, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              const Text('REDEEM',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('$_remaining',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
