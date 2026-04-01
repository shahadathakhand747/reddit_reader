import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';

/// Provider for managing app settings
class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;

  String _selectedSubreddit = 'all';
  bool _aiEnabled = true;
  int _likedPostsCount = 0;
  int _trainedPostsCount = 0;
  bool _isLoading = false;

  SettingsProvider({required StorageService storageService})
      : _storageService = storageService;

  // Getters
  String get selectedSubreddit => _selectedSubreddit;
  bool get aiEnabled => _aiEnabled;
  int get likedPostsCount => _likedPostsCount;
  int get trainedPostsCount => _trainedPostsCount;
  bool get isLoading => _isLoading;
  List<String> get subreddits => SubredditList.defaultSubreddits;

  /// Initialize settings from storage
  void initialize() {
    _selectedSubreddit = _storageService.getSelectedSubreddit();
    _aiEnabled = _storageService.isAiEnabled();
    _likedPostsCount = _storageService.getLikedPostsCount();
    _trainedPostsCount = _storageService.getTrainedPostsCount();
    notifyListeners();
  }

  /// Set selected subreddit
  Future<void> setSelectedSubreddit(String subreddit) async {
    _selectedSubreddit = subreddit;
    await _storageService.setSelectedSubreddit(subreddit);
    notifyListeners();
  }

  /// Toggle AI personalization
  Future<void> toggleAiEnabled() async {
    _aiEnabled = !_aiEnabled;
    await _storageService.setAiEnabled(_aiEnabled);
    notifyListeners();
  }

  /// Set AI personalization enabled
  Future<void> setAiEnabled(bool enabled) async {
    _aiEnabled = enabled;
    await _storageService.setAiEnabled(enabled);
    notifyListeners();
  }

  /// Reset training data
  Future<void> resetTrainingData() async {
    await _storageService.resetTrainingData();
    _trainedPostsCount = 0;
    notifyListeners();
  }

  /// Clear all data
  Future<void> clearAllData() async {
    _isLoading = true;
    notifyListeners();

    await _storageService.clearAllData();

    // Reset to defaults
    _selectedSubreddit = 'all';
    _aiEnabled = true;
    _likedPostsCount = 0;
    _trainedPostsCount = 0;

    _isLoading = false;
    notifyListeners();
  }

  /// Clear only liked posts
  Future<void> clearLikedPosts() async {
    await _storageService.clearLikedPosts();
    _likedPostsCount = 0;
    notifyListeners();
  }

  /// Refresh counts
  void refreshCounts() {
    _likedPostsCount = _storageService.getLikedPostsCount();
    _trainedPostsCount = _storageService.getTrainedPostsCount();
    notifyListeners();
  }

  /// Check if subreddit is in the default list
  bool isSubredditInList(String subreddit) {
    return SubredditList.defaultSubreddits.contains(subreddit.toLowerCase());
  }
}
