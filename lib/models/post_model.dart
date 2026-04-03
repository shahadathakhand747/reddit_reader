/// Media type enumeration for Reddit posts
enum MediaType {
  none,
  image,
  video,
  audio,
  gallery,
  link,
  selftext,
}

/// Model representing a Reddit post with full media support
class Post {
  final String id;
  final String title;
  final String author;
  final String subreddit;
  final int score;
  final int numComments;
  final DateTime createdUtc;
  final String? thumbnail;
  final String? selftext;
  final String url;
  final String? permalink;
  final String? previewImage;
  final bool isSelf;
  final bool isLiked;

  // Full media support
  final MediaType mediaType;
  final String? videoUrl;
  final String? videoFallbackUrl;
  final int? videoDuration;
  final String? audioUrl;
  final List<String> galleryImages;
  final String? crossPostParent;

  Post({
    required this.id,
    required this.title,
    required this.author,
    required this.subreddit,
    required this.score,
    required this.numComments,
    required this.createdUtc,
    this.thumbnail,
    this.selftext,
    required this.url,
    this.permalink,
    this.previewImage,
    required this.isSelf,
    this.isLiked = false,
    this.mediaType = MediaType.none,
    this.videoUrl,
    this.videoFallbackUrl,
    this.videoDuration,
    this.audioUrl,
    this.galleryImages = const [],
    this.crossPostParent,
  });

  /// Create a Post from Reddit API JSON data
  factory Post.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    // Determine media type first
    MediaType mediaType = MediaType.none;
    String? videoUrl;
    String? videoFallbackUrl;
    int? videoDuration;
    String? audioUrl;
    List<String> galleryImages = [];

    // Check for video content (Reddit API structure)
    // Video data can be in either 'reddit_video' or 'secure_media.reddit_video'
    Map<String, dynamic>? videoData;

    // First check direct reddit_video field (older API)
    if (data['reddit_video'] != null) {
      videoData = data['reddit_video'] as Map<String, dynamic>?;
    }

    // Then check secure_media.reddit_video (newer API structure)
    if (videoData == null && data['secure_media'] != null) {
      final secureMedia = data['secure_media'] as Map<String, dynamic>?;
      if (secureMedia != null && secureMedia['reddit_video'] != null) {
        videoData = secureMedia['reddit_video'] as Map<String, dynamic>?;
      }
    }

    if (data['is_video'] == true || videoData != null) {
      mediaType = MediaType.video;
      if (videoData != null) {
        // Try fallback_url first (MP4 with embedded audio - best for inline playback)
        videoUrl = videoData['fallback_url'] as String?;

        // If no fallback_url, try hls_url (HLS stream with audio)
        videoUrl ??= videoData['hls_url'] as String?;

        // If no fallback or HLS, try DASH url
        videoUrl ??= videoData['dash_url'] as String?;

        videoDuration = videoData['duration'] as int?;

        // Store dash_url for quality selection if available
        final dashUrl = videoData['dash_url'] as String?;
        if (dashUrl != null) videoFallbackUrl = dashUrl;

        // Also check for HLS URL
        final hlsUrl = videoData['hls_url'] as String?;
        if (hlsUrl != null && videoFallbackUrl == null) {
          videoFallbackUrl = hlsUrl;
        }
      }
    }

    // Check for gallery (media_metadata with multiple images)
    if (data['media_metadata'] != null) {
      final mediaMeta = data['media_metadata'] as Map<String, dynamic>;
      if (mediaMeta.isNotEmpty) {
        bool hasMultipleImages = mediaMeta.length > 1;
        bool allAreImages = mediaMeta.values.every((item) {
          final m = item as Map<String, dynamic>;
          return m['e'] == 'Image';
        });
        if (hasMultipleImages && allAreImages) {
          mediaType = MediaType.gallery;
          for (var item in mediaMeta.values) {
            final m = item as Map<String, dynamic>;
            final source = m['s'] as Map<String, dynamic>?;
            if (source != null) {
              String? imgUrl = source['u'] as String? ?? source['gif'] as String?;
              if (imgUrl != null) {
                imgUrl = imgUrl.replaceAll('&amp;', '&');
                galleryImages.add(imgUrl);
              }
            }
          }
        }
      }
    }

    // Check for preview images (single image posts)
    if (mediaType == MediaType.none && data['preview'] != null) {
      final preview = data['preview'] as Map<String, dynamic>;
      if (preview['images'] != null) {
        final images = preview['images'] as List;
        if (images.isNotEmpty) {
          final source = images[0]['source'] as Map<String, dynamic>?;
          if (source != null) {
            String? imgUrl = source['url'] as String?;
            if (imgUrl != null) {
              imgUrl = imgUrl.replaceAll('&amp;', '&');
              // Check if it's a gif
              if (imgUrl.contains('.gif') || (images[0]['variants'] != null &&
                  (images[0]['variants']['gif'] != null || images[0]['variants']['mp4'] != null))) {
                // It's a gif/video variant
                if (imgUrl.contains('gif')) {
                  mediaType = MediaType.image; // GIF treated as image for display
                }
              } else {
                mediaType = MediaType.image;
              }
            }
          }
        }
      }
    }

    // Check for audio (crosspost with audio or soundcloud)
    if (data['post_hint'] == 'hosted:video' || data['secure_media'] != null) {
      final secureMedia = data['secure_media'] as Map<String, dynamic>?;
      if (secureMedia != null) {
        if (secureMedia['type'] == 'gfycat.com' || secureMedia['type'] == 'redgifs.com') {
          mediaType = MediaType.video;
        }
        // Check for audio in oembed
        final oembed = secureMedia['oembed'] as Map<String, dynamic>?;
        if (oembed != null && oembed['type'] == 'audio') {
          mediaType = MediaType.audio;
          audioUrl = oembed['thumbnail_url'] as String?;
        }
      }
    }

    // Determine if it's a self/text post
    bool isSelf = data['is_self'] as bool? ?? false;
    if (isSelf || (data['selftext'] != null && (data['selftext'] as String).isNotEmpty)) {
      mediaType = MediaType.selftext;
    }

    // If URL is external link
    if (mediaType == MediaType.none && data['url'] != null) {
      final url = data['url'] as String;
      if (url.startsWith('http') && !url.contains('reddit.com') && !url.contains('i.redd.it') && !url.contains('v.redd.it')) {
        mediaType = MediaType.link;
      }
    }

    // Extract thumbnail URL
    String? thumbnail;
    if (data['thumbnail'] != null &&
        data['thumbnail'].toString().startsWith('http')) {
      thumbnail = data['thumbnail'] as String?;
    }

    // Extract preview image for single images
    String? previewImage;
    if (mediaType == MediaType.image || mediaType == MediaType.video) {
      if (data['preview'] != null) {
        final preview = data['preview'] as Map<String, dynamic>;
        if (preview['images'] != null) {
          final images = preview['images'] as List;
          if (images.isNotEmpty) {
            final source = images[0]['source'] as Map<String, dynamic>?;
            if (source != null) {
              previewImage = source['url'] as String?;
              if (previewImage != null) {
                previewImage = previewImage.replaceAll('&amp;', '&');
              }
            }
          }
        }
      }
      // Fallback to thumbnail
      previewImage ??= thumbnail;
    }

    // Extract permalink
    String? permalink = data['permalink'] as String?;
    if (permalink != null && !permalink.startsWith('http')) {
      permalink = 'https://reddit.com$permalink';
    }

    // Get crosspost parent info
    String? crossPostParent;
    if (data['crosspost_parent'] != null) {
      crossPostParent = data['crosspost_parent'] as String?;
    }

    return Post(
      id: data['id'] as String,
      title: _decodeHtmlEntities(data['title'] as String? ?? ''),
      author: data['author'] as String? ?? '[deleted]',
      subreddit: data['subreddit'] as String? ?? '',
      score: data['score'] as int? ?? 0,
      numComments: data['num_comments'] as int? ?? 0,
      createdUtc: DateTime.fromMillisecondsSinceEpoch(
        ((data['created_utc'] as num?)?.toInt() ?? 0) * 1000,
      ),
      thumbnail: thumbnail,
      selftext: data['selftext'] as String?,
      url: data['url'] as String? ?? '',
      permalink: permalink,
      previewImage: previewImage,
      isSelf: isSelf,
      mediaType: mediaType,
      videoUrl: videoUrl,
      videoFallbackUrl: videoFallbackUrl,
      videoDuration: videoDuration,
      audioUrl: audioUrl,
      galleryImages: galleryImages,
      crossPostParent: crossPostParent,
    );
  }

  /// Create a copy of the post with updated like status
  Post copyWith({
    bool? isLiked,
    MediaType? mediaType,
    String? videoUrl,
    String? videoFallbackUrl,
    int? videoDuration,
    String? audioUrl,
    List<String>? galleryImages,
  }) {
    return Post(
      id: id,
      title: title,
      author: author,
      subreddit: subreddit,
      score: score,
      numComments: numComments,
      createdUtc: createdUtc,
      thumbnail: thumbnail,
      selftext: selftext,
      url: url,
      permalink: permalink,
      previewImage: previewImage,
      isSelf: isSelf,
      isLiked: isLiked ?? this.isLiked,
      mediaType: mediaType ?? this.mediaType,
      videoUrl: videoUrl ?? this.videoUrl,
      videoFallbackUrl: videoFallbackUrl ?? this.videoFallbackUrl,
      videoDuration: videoDuration ?? this.videoDuration,
      audioUrl: audioUrl ?? this.audioUrl,
      galleryImages: galleryImages ?? this.galleryImages,
    );
  }

  /// Get display image (thumbnail or preview)
  String? get displayImage => previewImage ?? thumbnail;

  /// Check if post has video content
  bool get hasVideo => videoUrl != null || mediaType == MediaType.video;

  /// Get the best video URL for playback (with audio)
  String? get playableVideoUrl {
    // Prefer fallback_url as it has embedded audio
    if (videoUrl != null && videoUrl!.contains('v.redd.it')) {
      return videoUrl;
    }
    return videoUrl ?? videoFallbackUrl;
  }

  /// Check if post has gallery
  bool get hasGallery => galleryImages.isNotEmpty || mediaType == MediaType.gallery;

  /// Check if post has audio
  bool get hasAudio => audioUrl != null || mediaType == MediaType.audio;

  /// Get formatted video duration string
  String get formattedDuration {
    if (videoDuration == null) return '';
    final duration = videoDuration!;
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if post is a crosspost
  bool get isCrosspost => crossPostParent != null;

  /// Get media type display name
  String get mediaTypeDisplayName {
    switch (mediaType) {
      case MediaType.video:
        return 'Video';
      case MediaType.image:
        return 'Image';
      case MediaType.audio:
        return 'Audio';
      case MediaType.gallery:
        return 'Gallery (${galleryImages.length})';
      case MediaType.selftext:
        return 'Text Post';
      case MediaType.link:
        return 'Link';
      case MediaType.none:
        return '';
    }
  }

  /// Get the time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdUtc);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  /// Get formatted score string
  String get formattedScore {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}k';
    }
    return score.toString();
  }

  /// Decode HTML entities in text
  static String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Post && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
