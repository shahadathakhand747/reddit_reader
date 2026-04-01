import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'services/storage_service.dart';
import 'services/reddit_service.dart';
import 'services/ad_service.dart';
import 'providers/posts_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/posts_feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.primary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final redditService = RedditService();
  final adService = AdService.instance;
  await adService.init();

  runApp(
    RedditReaderApp(
      storageService: storageService,
      redditService: redditService,
      adService: adService,
    ),
  );
}

/// Main application widget
class RedditReaderApp extends StatelessWidget {
  final StorageService storageService;
  final RedditService redditService;
  final AdService adService;

  const RedditReaderApp({
    super.key,
    required this.storageService,
    required this.redditService,
    required this.adService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PostsProvider(
            redditService: redditService,
            storageService: storageService,
            adService: adService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService: storageService)
            ..initialize(),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const PostsFeedScreen(),
      ),
    );
  }
}
