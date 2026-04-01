import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../constants/app_constants.dart';

/// Widget for displaying a post card in the feed with full media support
class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onTap;
  final VoidCallback onLikeTap;
  final int index;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onLikeTap,
    required this.index,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: AnimationDurations.short,
      vsync: this,
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _handleLikeTap() {
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });
    widget.onLikeTap();
  }

  /// Build media indicator badge
  Widget _buildMediaIndicator() {
    IconData icon;
    Color color;
    String label;

    switch (widget.post.mediaType) {
      case MediaType.video:
        icon = Icons.play_circle_filled;
        color = Colors.red;
        label = widget.post.formattedDuration.isNotEmpty
            ? widget.post.formattedDuration
            : 'Video';
        break;
      case MediaType.audio:
        icon = Icons.audiotrack;
        color = Colors.purple;
        label = 'Audio';
        break;
      case MediaType.gallery:
        icon = Icons.photo_library;
        color = Colors.blue;
        label = '${widget.post.galleryImages.length}';
        break;
      case MediaType.image:
        icon = Icons.image;
        color = Colors.green;
        label = 'Image';
        break;
      case MediaType.selftext:
        icon = Icons.article;
        color = Colors.orange;
        label = 'Text';
        break;
      case MediaType.link:
        icon = Icons.link;
        color = Colors.teal;
        label = 'Link';
        break;
      case MediaType.none:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build media display based on type
  Widget _buildMediaContent() {
    final post = widget.post;

    switch (post.mediaType) {
      case MediaType.video:
        return _buildVideoThumbnail();
      case MediaType.gallery:
        return _buildGalleryThumbnail();
      case MediaType.image:
        return _buildImageThumbnail();
      case MediaType.audio:
        return _buildAudioThumbnail();
      default:
        return _buildImageThumbnail();
    }
  }

  /// Video thumbnail with play indicator
  Widget _buildVideoThumbnail() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildImageThumbnail(),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 36,
          ),
        ),
        // Duration badge
        if (widget.post.formattedDuration.isNotEmpty)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.post.formattedDuration,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Gallery thumbnail with count indicator
  Widget _buildGalleryThumbnail() {
    if (widget.post.galleryImages.isEmpty) {
      return _buildImageThumbnail();
    }

    return Stack(
      children: [
        _buildImageThumbnail(),
        // Gallery indicator
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Gallery',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Multiple images indicator
        if (widget.post.galleryImages.length > 1)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${widget.post.galleryImages.length} images',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Audio thumbnail
  Widget _buildAudioThumbnail() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.3),
            Colors.purple.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.audiotrack,
            color: Colors.purple,
            size: 36,
          ),
          SizedBox(height: 4),
          Text(
            'Audio Content',
            style: TextStyle(
              color: Colors.purple,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Standard image thumbnail
  Widget _buildImageThumbnail() {
    final imageUrl = widget.post.displayImage;
    if (imageUrl == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 180,
          color: AppColors.surface,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 180,
          color: AppColors.surface,
          child: const Center(
            child: Icon(Icons.broken_image, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: AnimationDurations.medium,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Subreddit, Author, Time, and Media Type
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'r/${widget.post.subreddit}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'u/${widget.post.author}',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      widget.post.timeAgo,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.smallSpacing),

                // Title
                Text(
                  widget.post.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // Self text (if available and not showing media)
                if (widget.post.selftext != null &&
                    widget.post.selftext!.isNotEmpty &&
                    widget.post.mediaType == MediaType.selftext) ...[
                  const SizedBox(height: AppDimensions.smallSpacing),
                  Text(
                    widget.post.selftext!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Media content (if available)
                if (widget.post.mediaType != MediaType.selftext &&
                    widget.post.mediaType != MediaType.none &&
                    widget.post.mediaType != MediaType.link) ...[
                  const SizedBox(height: AppDimensions.smallSpacing),
                  Stack(
                    children: [
                      _buildMediaContent(),
                      // Media type indicator
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _buildMediaIndicator(),
                      ),
                    ],
                  ),
                ],

                // External link indicator for link posts
                if (widget.post.mediaType == MediaType.link) ...[
                  const SizedBox(height: AppDimensions.smallSpacing),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.link,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.post.url,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.open_in_new,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],

                // Crosspost indicator
                if (widget.post.isCrosspost) ...[
                  const SizedBox(height: AppDimensions.smallSpacing),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz, color: Colors.blue, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Crosspost',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppDimensions.smallSpacing),

                // Footer row: Score, Comments, Like button
                Row(
                  children: [
                    // Score
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_upward,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.post.formattedScore,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Comments
                    Row(
                      children: [
                        const Icon(
                          Icons.comment_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.post.numComments}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Like button with animation
                    ScaleTransition(
                      scale: _likeScaleAnimation,
                      child: IconButton(
                        onPressed: _handleLikeTap,
                        icon: Icon(
                          widget.post.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.post.isLiked
                              ? AppColors.likeColor
                              : AppColors.textSecondary,
                        ),
                        splashRadius: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
