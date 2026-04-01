import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/posts_provider.dart';
import '../providers/settings_provider.dart';
import '../constants/app_constants.dart';
import '../widgets/post_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_state.dart';
import '../widgets/ai_personalization_overlay.dart';
import '../services/ad_service.dart';
import 'post_detail_screen.dart';
import 'settings_screen.dart';

/// Main screen displaying the Reddit posts feed
class PostsFeedScreen extends StatefulWidget {
  const PostsFeedScreen({super.key});

  @override
  State<PostsFeedScreen> createState() => _PostsFeedScreenState();
}

class _PostsFeedScreenState extends State<PostsFeedScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _brainAnimationController;
  bool _isAiAnimating = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _brainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Initialize and fetch posts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PostsProvider>();
      provider.initialize();
      if (provider.posts.isEmpty) {
        provider.fetchPosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _brainAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      context.read<PostsProvider>().loadMorePosts();
    }
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToPostDetail(String postId) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PostDetailScreen(postId: postId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
      ),
    );
  }

  void _handleAiPersonalize() async {
    final provider = context.read<PostsProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    if (provider.posts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No posts to personalize')),
      );
      return;
    }

    if (provider.isAiPersonalized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feed already personalized')),
      );
      return;
    }

    setState(() => _isAiAnimating = true);

    // Show overlay and personalize
    await showAiPersonalizationOverlay(context);

    await provider.personalizeFeed();

    if (mounted && settingsProvider.aiEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.aiSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    }

    setState(() => _isAiAnimating = false);
  }

  Future<void> _handleRefresh() async {
    await context.read<PostsProvider>().refreshPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          // Redeem Button (Rewarded Video)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: RewardedVideoButton(
              onRewardEarned: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.card_giftcard, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Reward earned!'),
                      ],
                    ),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
            ),
          ),
          // AI Personalize button with animated brain icon
          AnimatedBuilder(
            animation: _brainAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _isAiAnimating ? 1.2 : 1.0,
                child: IconButton(
                  onPressed: _isAiAnimating ? null : _handleAiPersonalize,
                  tooltip: AppStrings.aiPersonalize,
                  icon: _isAiAnimating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : Text(
                          '🧠',
                          style: TextStyle(
                            fontSize: 20,
                            color: _brainAnimationController.value > 0.5
                                ? AppColors.accent
                                : AppColors.textPrimary,
                          ),
                        ),
                ),
              );
            },
          ),
          // Settings button
          IconButton(
            onPressed: _navigateToSettings,
            icon: const Icon(Icons.settings),
            tooltip: AppStrings.settings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Ad
          const AdBannerWidget(),

          // Posts Feed
          Expanded(
            child: Consumer<PostsProvider>(
              builder: (context, provider, child) {
                switch (provider.state) {
                  case LoadingState.initial:
                  case LoadingState.loading:
                    return const ShimmerLoadingList();

                  case LoadingState.error:
                    return ErrorState(
                      message: provider.errorMessage,
                      onRetry: () => provider.fetchPosts(),
                    );

                  case LoadingState.loaded:
                  case LoadingState.loadingMore:
                    if (provider.posts.isEmpty) {
                      return EmptyState(
                        title: AppStrings.noPosts,
                        subtitle: AppStrings.noPostsSubtitle,
                        icon: Icons.inbox_outlined,
                        onRetry: () => provider.fetchPosts(),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: AppColors.accent,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: provider.posts.length +
                            (provider.state == LoadingState.loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == provider.posts.length) {
                            return const Padding(
                              padding: EdgeInsets.all(AppDimensions.spacing),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final post = provider.posts[index];

                          // Track post loaded for interstitial ads
                          AdService.instance.onPostLoaded();

                          return PostCard(
                            post: post,
                            index: index,
                            onTap: () => _navigateToPostDetail(post.id),
                            onLikeTap: () => provider.toggleLike(post.id),
                          );
                        },
                      ),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
