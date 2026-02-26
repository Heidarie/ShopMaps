import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'app_controller.dart';
import 'l10n/app_localizations.dart';
import 'local_store.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const ShoppingGuideApp());
}

class ShoppingGuideApp extends StatefulWidget {
  const ShoppingGuideApp({super.key});

  @override
  State<ShoppingGuideApp> createState() => _ShoppingGuideAppState();
}

class _ShoppingGuideAppState extends State<ShoppingGuideApp> {
  late final AppController _controller;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _controller = AppController(LocalStore());
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleThemeMode() {
    final effectiveBrightness = switch (_themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness,
    };

    setState(() {
      _themeMode =
          effectiveBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF168D82);
    const lightScaffold = Color(0xFFF2F2F7);
    const darkScaffold = Color(0xFF111315);
    const darkBar = Color(0xFF17191B);
    const darkCard = Color(0xFF1C1C1E);

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: brandColor,
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: brandColor,
      brightness: Brightness.dark,
    );
    final cupertinoTransitions = PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: const CupertinoPageTransitionsBuilder(),
      },
    );

    return MaterialApp(
      title: 'ShopMaps',
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale == null) {
          return const Locale('en');
        }

        for (final supported in supportedLocales) {
          if (supported.languageCode == deviceLocale.languageCode) {
            return supported;
          }
        }

        return const Locale('en');
      },
      theme: ThemeData(
        platform: TargetPlatform.iOS,
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor: lightScaffold,
        canvasColor: lightScaffold,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        pageTransitionsTheme: cupertinoTransitions,
        cupertinoOverrideTheme: const CupertinoThemeData(
          primaryColor: brandColor,
          scaffoldBackgroundColor: lightScaffold,
          barBackgroundColor: Color(0xCCF2F2F7),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: lightScaffold,
          foregroundColor: lightColorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          centerTitle: true,
        ),
        cardColor: Colors.white,
        dividerColor: const Color(0x1F3C3C43),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            backgroundColor: brandColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: BorderSide(color: lightColorScheme.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: brandColor, width: 1.4),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        platform: TargetPlatform.iOS,
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: darkScaffold,
        canvasColor: darkScaffold,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        pageTransitionsTheme: cupertinoTransitions,
        cupertinoOverrideTheme: const CupertinoThemeData(
          primaryColor: brandColor,
          scaffoldBackgroundColor: darkScaffold,
          barBackgroundColor: Color(0xCC17191B),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: darkBar,
          foregroundColor: darkColorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          centerTitle: true,
        ),
        cardColor: darkCard,
        dividerColor: const Color(0x4D545458),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            backgroundColor: brandColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: BorderSide(color: darkColorScheme.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2E),
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.58),
          ),
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: brandColor, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: darkColorScheme.error,
              width: 1.2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: darkColorScheme.error,
              width: 1.4,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: HomeScreen(
        controller: _controller,
        onToggleThemeMode: _toggleThemeMode,
      ),
    );
  }
}
