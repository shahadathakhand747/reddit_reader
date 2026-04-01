import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Service for managing local storage using SharedPreferences
class StorageService {
  SharedPreferences? _prefs;

  /// Initialize the storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ==================== Subreddit Management ====================

  /// Get the currently selected subreddit
  String getSelectedSubreddit() {
    return prefs.getString(StorageKeys.selectedSubreddit) ?? 'all';
  }

  /// Save the selected subreddit
  Future<bool> setSelectedSubreddit(String subreddit) {
    return prefs.setString(StorageKeys.selectedSubreddit, subreddit);
  }

  // ==================== Liked Posts Management ====================

  /// Get all liked post IDs
  Set<String> getLikedPosts() {
    final List<String>? likedList = prefs.getStringList(StorageKeys.likedPosts);
    return likedList?.toSet() ?? {};
  }

  /// Add a post to liked posts
  Future<bool> addLikedPost(String postId) {
    final likedPosts = getLikedPosts();
    likedPosts.add(postId);
    return prefs.setStringList(StorageKeys.likedPosts, likedPosts.toList());
  }

  /// Remove a post from liked posts
  Future<bool> removeLikedPost(String postId) {
    final likedPosts = getLikedPosts();
    likedPosts.remove(postId);
    return prefs.setStringList(StorageKeys.likedPosts, likedPosts.toList());
  }

  /// Toggle like status for a post
  Future<bool> toggleLikedPost(String postId) {
    final likedPosts = getLikedPosts();
    if (likedPosts.contains(postId)) {
      likedPosts.remove(postId);
    } else {
      likedPosts.add(postId);
    }
    return prefs.setStringList(StorageKeys.likedPosts, likedPosts.toList());
  }

  /// Check if a post is liked
  bool isPostLiked(String postId) {
    return getLikedPosts().contains(postId);
  }

  /// Get the count of liked posts
  int getLikedPostsCount() {
    return getLikedPosts().length;
  }

  // ==================== AI Personalization ====================

  /// Get AI personalization enabled status
  bool isAiEnabled() {
    return prefs.getBool(StorageKeys.aiEnabled) ?? true;
  }

  /// Set AI personalization enabled status
  Future<bool> setAiEnabled(bool enabled) {
    return prefs.setBool(StorageKeys.aiEnabled, enabled);
  }

  /// Get trained post IDs for AI personalization
  Set<String> getTrainedPostIds() {
    final List<String>? trainedList = prefs.getStringList(StorageKeys.trainedPostIds);
    return trainedList?.toSet() ?? {};
  }

  /// Add a post ID to trained posts
  Future<bool> addTrainedPost(String postId) {
    final trainedPosts = getTrainedPostIds();
    trainedPosts.add(postId);
    return prefs.setStringList(StorageKeys.trainedPostIds, trainedPosts.toList());
  }

  /// Get the count of trained posts
  int getTrainedPostsCount() {
    return getTrainedPostIds().length;
  }

  /// Reset all training data
  Future<bool> resetTrainingData() {
    return prefs.setStringList(StorageKeys.trainedPostIds, []);
  }

  // ==================== Data Management ====================

  /// Clear all locally stored data
  Future<bool> clearAllData() {
    return prefs.clear();
  }

  /// Clear only liked posts
  Future<bool> clearLikedPosts() {
    return prefs.remove(StorageKeys.likedPosts);
  }

  /// Reset to defaults (keeps subreddit selection)
  Future<void> resetToDefaults() async {
    await prefs.remove(StorageKeys.likedPosts);
    await prefs.remove(StorageKeys.aiEnabled);
    await prefs.remove(StorageKeys.trainedPostIds);
  }

  // ==================== Export/Import ====================

  /// Export all data as JSON string
  String exportData() {
    final data = {
      StorageKeys.selectedSubreddit: getSelectedSubreddit(),
      StorageKeys.likedPosts: getLikedPosts().toList(),
      StorageKeys.aiEnabled: isAiEnabled(),
      StorageKeys.trainedPostIds: getTrainedPostIds().toList(),
    };
    return json.encode(data);
  }

  /// Import data from JSON string
  Future<bool> importData(String jsonString) async {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;

      if (data.containsKey(StorageKeys.selectedSubreddit)) {
        await setSelectedSubreddit(data[StorageKeys.selectedSubreddit] as String);
      }
      if (data.containsKey(StorageKeys.likedPosts)) {
        final likedPosts = (data[StorageKeys.likedPosts] as List).cast<String>();
        await prefs.setStringList(StorageKeys.likedPosts, likedPosts);
      }
      if (data.containsKey(StorageKeys.aiEnabled)) {
        await setAiEnabled(data[StorageKeys.aiEnabled] as bool);
      }
      if (data.containsKey(StorageKeys.trainedPostIds)) {
        final trainedPosts = (data[StorageKeys.trainedPostIds] as List).cast<String>();
        await prefs.setStringList(StorageKeys.trainedPostIds, trainedPosts);
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
