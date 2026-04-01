import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/posts_provider.dart';
import '../constants/app_constants.dart';
import '../services/ad_service.dart';

/// Screen for app settings
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _customSubredditController =
      TextEditingController();

  @override
  void dispose() {
    _customSubredditController.dispose();
    super.dispose();
  }

  void _showSubredditPicker() {
    final settingsProvider = context.read<SettingsProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.cardBorderRadius),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        AppStrings.selectSubreddit,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showCustomSubredditDialog();
                        },
                        icon: const Icon(Icons.edit),
                        tooltip: AppStrings.customSubreddit,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Subreddit list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: settingsProvider.subreddits.length,
                    itemBuilder: (context, index) {
                      final subreddit = settingsProvider.subreddits[index];
                      final isSelected =
                          subreddit == settingsProvider.selectedSubreddit;

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              subreddit[0].toUpperCase(),
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          'r/$subreddit',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.accent,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _selectSubreddit(subreddit);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCustomSubredditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.customSubreddit),
          content: TextField(
            controller: _customSubredditController,
            decoration: const InputDecoration(
              hintText: AppStrings.enterSubredditName,
              prefixText: 'r/',
            ),
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              Navigator.pop(context);
              _selectSubreddit(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _selectSubreddit(_customSubredditController.text.trim());
              },
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }

  void _selectSubreddit(String subreddit) {
    if (subreddit.isEmpty) return;

    final normalizedSubreddit = subreddit.toLowerCase().replaceAll('r/', '');
    context.read<PostsProvider>().setSubreddit(normalizedSubreddit);
    context.read<SettingsProvider>().setSelectedSubreddit(normalizedSubreddit);
  }

  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.clearData),
          content: const Text(AppStrings.clearDataConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await context.read<SettingsProvider>().clearAllData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.dataCleared),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text(AppStrings.confirm),
            ),
          ],
        );
      },
    );
  }

  void _showResetTrainingConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.resetTraining),
          content: const Text(
            'This will reset your AI training data. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await context.read<SettingsProvider>().resetTrainingData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Training data reset'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text(AppStrings.confirm),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Banner Ad
          const AdBannerWidget(),

          // Settings content
          Expanded(
            child: Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                return ListView(
                  padding: const EdgeInsets.all(AppDimensions.spacing),
                  children: [
                    // Subreddit Selection
                    _SettingsSection(
                      title: AppStrings.selectSubreddit,
                      children: [
                        _SettingsTile(
                          icon: Icons.subdirectory_arrow_right,
                          title: 'Current Subreddit',
                          subtitle: 'r/${settingsProvider.selectedSubreddit}',
                          onTap: _showSubredditPicker,
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.spacing),

                    // AI Personalization
                    _SettingsSection(
                      title: AppStrings.aiPersonalization,
                      children: [
                        _SettingsSwitchTile(
                          icon: Icons.psychology,
                          title: AppStrings.enableAI,
                          subtitle: 'Use AI to personalize your feed',
                          value: settingsProvider.aiEnabled,
                          onChanged: (value) {
                            settingsProvider.setAiEnabled(value);
                          },
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.school,
                          title: AppStrings.trainedPosts,
                          subtitle:
                              '${settingsProvider.trainedPostsCount} posts trained',
                          trailing: IconButton(
                            onPressed: settingsProvider.trainedPostsCount > 0
                                ? _showResetTrainingConfirmation
                                : null,
                            icon: const Icon(Icons.refresh),
                            tooltip: AppStrings.resetTraining,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.spacing),

                    // Data Management
                    _SettingsSection(
                      title: 'Data Management',
                      children: [
                        _SettingsTile(
                          icon: Icons.favorite,
                          title: 'Liked Posts',
                          subtitle:
                              '${settingsProvider.likedPostsCount} posts liked',
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.delete_outline,
                          title: AppStrings.clearData,
                          subtitle: 'Clear all locally stored data',
                          onTap: _showClearDataConfirmation,
                          iconColor: AppColors.error,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.spacing),

                    // About
                    _SettingsSection(
                      title: AppStrings.about,
                      children: [
                        _SettingsTile(
                          icon: Icons.info_outline,
                          title: AppStrings.appName,
                          subtitle: AppStrings.version,
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.article_outlined,
                          title: AppStrings.attribution,
                          subtitle: 'Content powered by Reddit API',
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          title: AppStrings.privacyPolicy,
                          subtitle: 'Your data stays on your device',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header for settings groups
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            bottom: 8,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

/// Standard settings tile
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Switch settings tile
class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accent,
      ),
    );
  }
}
