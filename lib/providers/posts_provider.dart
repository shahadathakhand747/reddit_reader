import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../services/reddit_service.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../constants/app_constants.dart';

/// Enum representing the loading state
enum LoadingState { initial, loading, loaded, error, loadingMore }

/// Provider for managing posts state
class PostsProvider extends ChangeNotifier {
  final RedditService _redditService;
  final StorageService _storageService;
  final AdService _adService;

  List<Post> _posts = [];
  LoadingState _state = LoadingState.initial;
  String _errorMessage = '';
  String _currentSubreddit = 'all';
  String? _afterParam;
  bool _hasMorePosts = true;
  bool _isAiPersonalized = false;

  PostsProvider({
    required RedditService redditService,
    required StorageService storageService,
    required AdService adService,
  })  : _redditService = redditService,
        _storageService = storageService,
        _adService = adService;

  // Getters
  List<Post> get posts => _posts;
  LoadingState get state => _state;
  String get errorMessage => _errorMessage;
  String get currentSubreddit => _currentSubreddit;
  bool get hasMorePosts => _hasMorePosts;
  bool get isAiPersonalized => _isAiPersonalized;

  /// Initialize the provider with saved subreddit
  void initialize() {
    _currentSubreddit = _storageService.getSelectedSubreddit();
    _updatePostsWithLikedStatus();
  }

  /// Update subreddit and fetch new posts
  Future<void> setSubreddit(String subreddit) async {
    if (_currentSubreddit == subreddit) return;

    _currentSubreddit = subreddit;
    _posts = [];
    _afterParam = null;
    _hasMorePosts = true;
    _isAiPersonalized = false;
    _adService.resetPostCount();

    await _storageService.setSelectedSubreddit(subreddit);
    await fetchPosts();
  }

  /// Fetch initial posts
  Future<void> fetchPosts() async {
    _state = LoadingState.loading;
    _errorMessage = '';
    notifyListeners();

    final result = await _redditService.fetchPosts(
      subreddit: _currentSubreddit,
      after: null,
    );

    if (result.isSuccess && result.data != null) {
      _posts = result.data!;
      _afterParam = _redditService.getAfterParam(_posts);
      _hasMorePosts = _posts.length >= ApiConstants.postsPerPage;
      _updatePostsWithLikedStatus();
      _state = LoadingState.loaded;

      // Record posts loaded for ad triggering
      for (int i = 0; i < _posts.length; i++) {
        _adService.onPostLoaded();
      }
    } else {
      _errorMessage = result.error ?? AppStrings.errorLoading;
      _state = LoadingState.error;
    }

    notifyListeners();
  }

  /// Load more posts for infinite scroll
  Future<void> loadMorePosts() async {
    if (_state == LoadingState.loadingMore || !_hasMorePosts) return;

    _state = LoadingState.loadingMore;
    notifyListeners();

    final result = await _redditService.fetchPosts(
      subreddit: _currentSubreddit,
      after: _afterParam,
    );

    if (result.isSuccess && result.data != null) {
      final newPosts = result.data!;
      _posts.addAll(newPosts);
      _afterParam = _redditService.getAfterParam(newPosts);
      _hasMorePosts = newPosts.length >= ApiConstants.postsPerPage;
      _updatePostsWithLikedStatus();
      _state = LoadingState.loaded;

      // Record posts loaded for ad triggering
      for (int i = 0; i < newPosts.length; i++) {
        _adService.onPostLoaded();

        // Trigger interstitial ad every 5 posts
        if (_adService.shouldShowInterstitial()) {
          _adService.showInterstitialAd();
        }
      }
    } else {
      _errorMessage = result.error ?? 'Failed to load more posts';
      _hasMorePosts = false;
      _state = LoadingState.loaded;
    }

    notifyListeners();
  }

  /// Refresh posts (pull-to-refresh)
  Future<void> refreshPosts() async {
    _isAiPersonalized = false;
    _adService.resetPostCount();
    await fetchPosts();
  }

  /// Toggle like status for a post
  Future<void> toggleLike(String postId) async {
    await _storageService.toggleLikedPost(postId);

    // Update the post in the list
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts[index] = _posts[index].copyWith(
        isLiked: _storageService.isPostLiked(postId),
      );
      notifyListeners();
    }
  }

  /// Check if a post is liked
  bool isPostLiked(String postId) {
    return _storageService.isPostLiked(postId);
  }

  /// Update all posts with current liked status
  void _updatePostsWithLikedStatus() {
    _posts = _posts.map((post) {
      return post.copyWith(
        isLiked: _storageService.isPostLiked(post.id),
      );
    }).toList();
  }

  /// Personalize feed based on liked posts (Fake AI)
  Future<void> personalizeFeed() async {
    if (_storageService.getLikedPostsCount() == 0) {
      return;
    }

    // Get liked post IDs
    final likedPostIds = _storageService.getLikedPosts();

    // Sort posts: liked posts first, then by score
    _posts.sort((a, b) {
      final aLiked = likedPostIds.contains(a.id);
      final bLiked = likedPostIds.contains(b.id);

      if (aLiked && !bLiked) return -1;
      if (!aLiked && bLiked) return 1;

      // If both liked or both not liked, sort by score
      return b.score.compareTo(a.score);
    });

    _isAiPersonalized = true;

    // Add liked posts to trained posts for AI
    for (final postId in likedPostIds) {
      await _storageService.addTrainedPost(postId);
    }

    notifyListeners();
  }

  /// Get post by ID
  Post? getPostById(String postId) {
    try {
      return _posts.firstWhere((p) => p.id == postId);
    } catch (e) {
      return null;
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _redditService.dispose();
    super.dispose();
  }
}
