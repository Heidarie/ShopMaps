import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class PushNotificationService {
  PushNotificationService({required this.enabled});

  final bool enabled;

  StreamSubscription<String>? _tokenSubscription;
  Timer? _tokenRetryTimer;
  Future<void>? _startFuture;
  Future<void> Function(String token)? _onToken;
  String? _currentToken;
  bool _started = false;
  bool _permissionGranted = false;
  bool _loggedWaitingForApns = false;

  String? get currentToken => _currentToken;

  String get platform => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => 'unsupported',
  };

  bool get _supportsPush =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> start({
    required Future<void> Function(String token) onToken,
  }) async {
    if (!enabled || !_supportsPush) {
      return;
    }

    _onToken = onToken;
    if (_started) {
      _scheduleTokenRetry();
      return;
    }

    final pendingStart = _startFuture;
    if (pendingStart != null) {
      try {
        await pendingStart;
      } catch (_) {
        // The first caller logs initialization failures.
      }
      return;
    }

    final startFuture = _start();
    _startFuture = startFuture;
    try {
      await startFuture;
    } catch (error) {
      _started = false;
      debugPrint('Push notifications could not be initialized: $error');
    } finally {
      if (identical(_startFuture, startFuture)) {
        _startFuture = null;
      }
    }
  }

  Future<void> _start() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      debugPrint(
        'Push notifications: notification permission was not granted.',
      );
      _started = true;
      return;
    }
    _permissionGranted = true;
    await messaging.setAutoInitEnabled(true);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    _started = true;
    _tokenSubscription = messaging.onTokenRefresh.listen(
      (token) => unawaited(_handleToken(token)),
      onError: (Object error) {
        debugPrint('Push notifications: token refresh failed: $error');
      },
    );
    await _loadTokenWhenAvailable();
  }

  Future<void> stop({bool deleteToken = false}) async {
    _tokenRetryTimer?.cancel();
    _tokenRetryTimer = null;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _onToken = null;
    _started = false;
    _permissionGranted = false;
    _loggedWaitingForApns = false;

    if (deleteToken && enabled && _supportsPush && Firebase.apps.isNotEmpty) {
      try {
        final messaging = FirebaseMessaging.instance;
        await messaging.deleteToken();
        await messaging.setAutoInitEnabled(false);
      } catch (error) {
        debugPrint('Push notifications: token deletion failed: $error');
      }
    }
    _currentToken = null;
  }

  Future<void> _handleToken(String token) async {
    _tokenRetryTimer?.cancel();
    _tokenRetryTimer = null;
    _loggedWaitingForApns = false;
    if (_currentToken == token) {
      return;
    }

    debugPrint('Push notifications: FCM token obtained.');
    try {
      await _onToken?.call(token);
      _currentToken = token;
    } catch (error) {
      debugPrint(
        'Push notifications: token registration failed; will retry: $error',
      );
      _scheduleTokenRetry();
    }
  }

  Future<void> _loadTokenWhenAvailable() async {
    if (!_started) {
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await messaging.getAPNSToken();
        if (apnsToken == null) {
          if (!_loggedWaitingForApns) {
            _loggedWaitingForApns = true;
            debugPrint(
              'Push notifications: waiting for an APNs token. '
              'This is expected on an iOS Simulator; on a physical device, '
              'verify notification permission and Push Notifications signing.',
            );
          }
          _scheduleTokenRetry();
          return;
        }
        debugPrint('Push notifications: APNs token obtained.');
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        _scheduleTokenRetry();
        return;
      }
      await _handleToken(token);
    } catch (error) {
      debugPrint('Push notifications: token lookup failed; will retry: $error');
      _scheduleTokenRetry();
    }
  }

  void _scheduleTokenRetry() {
    if (!_started ||
        !_permissionGranted ||
        _currentToken != null ||
        (_tokenRetryTimer?.isActive ?? false)) {
      return;
    }
    _tokenRetryTimer = Timer(
      const Duration(seconds: 5),
      () => unawaited(_loadTokenWhenAvailable()),
    );
  }

  void dispose() {
    unawaited(stop());
  }
}
