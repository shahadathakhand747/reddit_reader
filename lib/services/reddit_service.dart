import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/post_model.dart';

/// Result wrapper for API responses
class ApiResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResult.success(this.data)
      : error = null,
        isSuccess = true;

  ApiResult.failure(this.error)
      : data = null,
        isSuccess = false;
}

/// Service for interacting with the Reddit API
class RedditService {
  final http.Client _client;

  RedditService({http.Client? client}) : _client = client ?? http.Client();

  /// Get the base URL for Reddit API (with CORS proxy for web)
  String _getBaseUrl(String endpoint) {
    // Use allorigins.win CORS proxy for web platform
    if (kIsWeb) {
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent('${ApiConstants.redditBaseUrl}$endpoint')}';
    }
    return '${ApiConstants.redditBaseUrl}$endpoint';
  }

  /// Fetch posts from a subreddit with pagination
  Future<ApiResult<List<Post>>> fetchPosts({
    required String subreddit,
    int limit = ApiConstants.postsPerPage,
    String? after,
  }) async {
    // Build the endpoint
    String endpoint = '/r/$subreddit.json?limit=$limit';
    if (after != null) {
      endpoint += '&after=$after';
    }

    final String url = _getBaseUrl(endpoint);

    int retries = 0;
    Duration delay = ApiConstants.retryDelay;

    while (retries < ApiConstants.maxRetries) {
      try {
        debugPrint('RedditService: Fetching from $url');

        final response = await _client
            .get(
              Uri.parse(url),
              headers: {
                'User-Agent': 'RedditReaderApp/1.0',
              },
            )
            .timeout(ApiConstants.requestTimeout);

        debugPrint('RedditService: Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body) as Map<String, dynamic>;
          final posts = _parsePosts(jsonData);
          debugPrint('RedditService: Parsed ${posts.length} posts');
          return ApiResult.success(posts);
        } else if (response.statusCode == 429) {
          // Rate limited - exponential backoff
          retries++;
          if (retries < ApiConstants.maxRetries) {
            await Future.delayed(delay);
            delay *= 2; // Exponential backoff
          }
        } else {
          return ApiResult.failure('Failed to load posts: ${response.statusCode}');
        }
      } on TimeoutException {
        retries++;
        if (retries < ApiConstants.maxRetries) {
          await Future.delayed(delay);
          delay *= 2;
        } else {
          return ApiResult.failure('Request timed out. Please try again.');
        }
      } catch (e, stackTrace) {
        debugPrint('RedditService: Error: $e');
        debugPrint('RedditService: StackTrace: $stackTrace');
        return ApiResult.failure('Network error: ${e.toString()}');
      }
    }

    return ApiResult.failure('Failed after $retries retries. Please try again later.');
  }

  /// Parse posts from Reddit API response
  List<Post> _parsePosts(Map<String, dynamic> jsonData) {
    final List<Post> posts = [];

    try {
      final children = jsonData['data']['children'] as List;
      debugPrint('RedditService: Found ${children.length} children');
      for (final child in children) {
        try {
          final post = Post.fromJson(child as Map<String, dynamic>);
          posts.add(post);
        } catch (e) {
          // Skip malformed posts
          debugPrint('RedditService: Error parsing post: $e');
          continue;
        }
      }
    } catch (e) {
      debugPrint('RedditService: Error parsing posts: $e');
      throw Exception('Failed to parse posts: $e');
    }

    return posts;
  }

  /// Get the 'after' parameter for pagination from the last post
  String? getAfterParam(List<Post> posts) {
    if (posts.isEmpty) return null;
    return posts.last.id;
  }

  /// Validate if a subreddit exists
  Future<bool> validateSubreddit(String subreddit) async {
    try {
      final String url = _getBaseUrl('/r/$subreddit/about.json');
      final response = await _client
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'RedditReaderApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Dispose the HTTP client
  void dispose() {
    _client.close();
  }
}
