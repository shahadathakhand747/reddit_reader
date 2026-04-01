import 'package:flutter/material.dart';

/// App color constants following the dark theme design system
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF0A0A0A); // Rich black background
  static const Color surface = Color(0xFF1A1A1A); // Cards, dialogs
  static const Color accent = Color(0xFFFF4500); // Reddit orange

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White for primary text
  static const Color textSecondary = Color(0xFFB0B0B0); // Grey for secondary

  // Additional UI Colors
  static const Color divider = Color(0xFF2A2A2A);
  static const Color shimmerBase = Color(0xFF1A1A1A);
  static const Color shimmerHighlight = Color(0xFF2A2A2A);
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF4CAF50);
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color likeColor = Color(0xFFFF4757);
  static const Color adPlaceholder = Color(0xFF333333);
}

/// App dimension constants
class AppDimensions {
  static const double cardBorderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double thumbnailSize = 80.0;
  static const double iconSize = 24.0;
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 24.0;
  static const double bannerAdHeight = 50.0;
  static const double interstitialAdDelay = 1500; // milliseconds
}

/// App string constants
class AppStrings {
  static const String appName = 'Reddit Reader';
  static const String aiPersonalize = 'AI Personalize';
  static const String aiAnalyzing = 'AI Analyzing Your Preferences...';
  static const String aiSuccess = 'Feed personalized based on your interests';
  static const String settings = 'Settings';
  static const String postDetail = 'Post Detail';
  static const String noPosts = 'No posts found';
  static const String noPostsSubtitle = 'Pull to refresh or try another subreddit';
  static const String errorLoading = 'Error loading posts';
  static const String retry = 'Retry';
  static const String clearData = 'Clear All Data';
  static const String clearDataConfirm = 'Are you sure you want to clear all data?';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String dataCleared = 'All data has been cleared';
  static const String selectSubreddit = 'Select Subreddit';
  static const String customSubreddit = 'Custom Subreddit';
  static const String enterSubredditName = 'Enter subreddit name';
  static const String about = 'About';
  static const String version = 'Version 1.0.0';
  static const String attribution = 'Content from Reddit';
  static const String privacyPolicy = 'Privacy Policy';
  static const String aiPersonalization = 'AI Personalization';
  static const String enableAI = 'Enable AI Personalization';
  static const String trainedPosts = 'Posts trained';
  static const String resetTraining = 'Reset Training Data';
  static const String viewOnReddit = 'View on Reddit';
  static const String adPlaceholder = 'Ad Placeholder';
  static const String comments = 'Comments';
}

/// Pre-populated list of subreddits
class SubredditList {
  static const List<String> defaultSubreddits = [
    'all',
    'askreddit',
    'worldnews',
    'technology',
    'science',
    'gaming',
    'movies',
    'music',
    'art',
    'funny',
    'memes',
    'pics',
    'gifs',
    'videos',
    'programming',
    'flutter',
    'android',
    'ios',
    'javascript',
    'python',
    'todayilearned',
    'news',
    'politics',
    'business',
    'sports',
    'aww',
  ];
}

/// SharedPreferences keys
class StorageKeys {
  static const String selectedSubreddit = 'selected_subreddit';
  static const String likedPosts = 'liked_posts';
  static const String aiEnabled = 'ai_enabled';
  static const String trainedPostIds = 'trained_post_ids';
}

/// API constants
class ApiConstants {
  static const String redditBaseUrl = 'https://www.reddit.com';
  static const int postsPerPage = 25;
  static const int interstitialAdInterval = 5; // Show ad every 5 posts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}

/// Animation durations
class AnimationDurations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration long = Duration(milliseconds: 500);
  static const Duration aiDelay = Duration(milliseconds: 1500);
}
