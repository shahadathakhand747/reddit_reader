import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/posts_provider.dart';
import '../models/post_model.dart';
import '../constants/app_constants.dart';
import '../widgets/empty_state.dart';
import '../services/ad_service.dart';

/// Screen for displaying full post details
class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen>
    with SingleTickerProviderStateMixin {
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
    context.read<PostsProvider>().toggleLike(widget.postId);
  }

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.postDetail),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<PostsProvider>(
        builder: (context, provider, child) {
          final post = provider.getPostById(widget.postId);

          if (post == null) {
            return const EmptyState(
              title: 'Post not found',
              subtitle: 'The post may have been removed',
              icon: Icons.article_outlined,
            );
          }

          return Column(
            children: [
              // Banner Ad
              const AdBannerWidget(),

              // Post Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Padding(
                        padding: const EdgeInsets.all(AppDimensions.spacing),
                        child: Text(
                          post.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),

                      // Metadata row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacing,
                        ),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _MetadataChip(
                              icon: Icons.person_outline,
                              label: post.author,
                            ),
                            _MetadataChip(
                              icon: Icons.forum_outlined,
                              label: 'r/${post.subreddit}',
                              color: AppColors.accent,
                            ),
                            _MetadataChip(
                              icon: Icons.arrow_upward,
                              label: post.formattedScore,
                            ),
                            _MetadataChip(
                              icon: Icons.schedule,
                              label: post.timeAgo,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppDimensions.spacing),

                      // Self text content
                      if (post.selftext != null &&
                          post.selftext!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacing,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppDimensions.spacing),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.cardBorderRadius,
                              ),
                            ),
                            child: SelectableText(
                              post.selftext!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ],

                      // Image preview
                      if (post.displayImage != null) ...[
                        const SizedBox(height: AppDimensions.spacing),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacing,
                          ),
                          child: GestureDetector(
                            onTap: () => _openInBrowser(post.displayImage!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.cardBorderRadius,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: post.displayImage!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 200,
                                  color: AppColors.surface,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: AppDimensions.spacing),

                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacing,
                        ),
                        child: Row(
                          children: [
                            // Like button
                            ScaleTransition(
                              scale: _likeScaleAnimation,
                              child: ElevatedButton.icon(
                                onPressed: _handleLikeTap,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: post.isLiked
                                      ? AppColors.likeColor
                                      : AppColors.surface,
                                ),
                                icon: Icon(
                                  post.isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: post.isLiked
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                                label: Text(
                                  post.isLiked ? 'Liked' : 'Like',
                                  style: TextStyle(
                                    color: post.isLiked
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // View on Reddit button
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _openInBrowser(post.permalink ?? post.url),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text(AppStrings.viewOnReddit),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppDimensions.largeSpacing),

                      // Comments placeholder
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacing,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppDimensions.spacing),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.cardBorderRadius,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.comment_outlined,
                                size: 40,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${post.numComments} ${AppStrings.comments}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Comments feature coming soon',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppDimensions.largeSpacing),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Helper widget for metadata chips
class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetadataChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: effectiveColor,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: effectiveColor,
                fontWeight: color != null ? FontWeight.w600 : null,
              ),
        ),
      ],
    );
  }
}
