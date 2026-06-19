import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import '../online_categories.dart';
import 'cloud_models.dart';
import 'push_notification_service.dart';
import 'store_countries.dart';
import 'supabase_config.dart';

enum CloudErrorKind {
  contentRejected,
  canonicalStoreRequired,
  storeCountryMismatch,
}

CloudErrorKind? classifyCloudPostgrestException(PostgrestException error) {
  const marker = 'CONTENT_NOT_ALLOWED';
  if (error.message.contains(marker) ||
      error.code?.contains(marker) == true ||
      error.details?.toString().contains(marker) == true ||
      error.hint?.contains(marker) == true) {
    return CloudErrorKind.contentRejected;
  }
  const canonicalStoreMarker = 'CANONICAL_STORE_REQUIRED';
  if (error.message.contains(canonicalStoreMarker) ||
      error.code?.contains(canonicalStoreMarker) == true ||
      error.details?.toString().contains(canonicalStoreMarker) == true ||
      error.hint?.contains(canonicalStoreMarker) == true) {
    return CloudErrorKind.canonicalStoreRequired;
  }
  const storeCountryMarker = 'STORE_COUNTRY_MISMATCH';
  if (error.message.contains(storeCountryMarker) ||
      error.code?.contains(storeCountryMarker) == true ||
      error.details?.toString().contains(storeCountryMarker) == true ||
      error.hint?.contains(storeCountryMarker) == true) {
    return CloudErrorKind.storeCountryMismatch;
  }
  return null;
}

class CloudController extends ChangeNotifier {
  CloudController(
    this._client, {
    PushNotificationService? pushNotificationService,
  }) : _pushNotificationService = pushNotificationService;

  static const redirectUrl = 'shopmaps://login-callback';

  final SupabaseClient? _client;
  final PushNotificationService? _pushNotificationService;
  StreamSubscription<AuthState>? _authSubscription;
  RealtimeChannel? _sharedDataChannel;
  Timer? _sharedRefreshTimer;
  Timer? _inviteRefreshTimer;
  Future<void>? _refreshFuture;
  bool _googleSignInInitialized = false;
  bool _hasLoadedSharedData = false;
  String? _googleSignInRawNonce;
  String? _registeredPushToken;
  String? _resolvedProfileUserId;
  String? _realtimeUserId;

  int _pendingOperations = 0;
  String? _errorMessage;
  CloudErrorKind? _errorKind;
  CloudProfile? _profile;
  List<CloudGroup> _groups = const [];
  List<CloudGroupInvite> _invites = const [];
  List<SharedGroceryList> _sharedLists = const [];
  List<SharedDepositVoucher> _sharedVouchers = const [];
  List<SharedMarketLayout> _publicMarketLayouts = const [];

  bool get isConfigured => _client != null;
  bool get isSignedIn => _client?.auth.currentUser != null;
  bool get isBusy => _pendingOperations > 0;
  bool get isProfileLoading {
    final userId = _client?.auth.currentUser?.id;
    return userId != null && _resolvedProfileUserId != userId;
  }

  String? get errorMessage => _errorMessage;
  CloudErrorKind? get errorKind => _errorKind;
  CloudProfile? get profile => _profile;
  List<CloudGroup> get groups => _groups;
  List<CloudGroupInvite> get invites => _invites;
  List<SharedGroceryList> get sharedLists => _sharedLists;
  List<SharedDepositVoucher> get sharedVouchers => _sharedVouchers;
  List<SharedMarketLayout> get publicMarketLayouts => _publicMarketLayouts;
  Set<String> get sharedSourceLocalIds =>
      sharedLists.map((list) => list.sourceLocalId).whereType<String>().toSet();
  bool get needsProfile =>
      isSignedIn &&
      !isProfileLoading &&
      (_profile == null || !_profile!.hasStoreCountry);

  SharedGroceryList? getSharedListById(String id) {
    for (final list in _sharedLists) {
      if (list.id == id) {
        return list;
      }
    }
    return null;
  }

  SharedMarketLayout? publicMapForLocalId(String localId) {
    final userId = _client?.auth.currentUser?.id;
    for (final map in _publicMarketLayouts) {
      if (map.createdBy == userId && map.sourceLocalId == localId) {
        return map;
      }
    }
    return null;
  }

  bool isOwnPublicMap(SharedMarketLayout map) {
    return map.createdBy == _client?.auth.currentUser?.id;
  }

  List<SharedGroceryList> sharedListsForGroup(String groupId) {
    return sharedLists.where((list) => list.spaceId == groupId).toList();
  }

  List<SharedDepositVoucher> sharedVouchersForGroup(String groupId) {
    return sharedVouchers
        .where((voucher) => voucher.spaceId == groupId)
        .toList();
  }

  Future<List<CloudGroupMember>> loadGroupMembers(String groupId) async {
    final client = _client;
    if (client == null || !isSignedIn) {
      return const [];
    }

    return _runWithResult(() async {
      final rows = await client.rpc<List<dynamic>>(
        'list_group_members',
        params: {'target_space_id': groupId},
      );
      return rows
          .whereType<Map>()
          .map(
            (entry) =>
                CloudGroupMember.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList();
    }, fallback: const []);
  }

  Future<void> initialize() async {
    if (_client == null) {
      return;
    }

    _authSubscription = _client.auth.onAuthStateChange.listen((_) {
      unawaited(refresh());
    });
    await refresh();
  }

  Future<void> signInWithGoogle() {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      return _signInWithNativeGoogle();
    }
    return _signIn(OAuthProvider.google);
  }

  Future<void> signInWithApple() => _signIn(OAuthProvider.apple);

  Future<void> signInWithFacebook() => _signIn(
    OAuthProvider.facebook,
    mobileLaunchMode: LaunchMode.externalApplication,
  );

  Future<void> _signIn(
    OAuthProvider provider, {
    LaunchMode mobileLaunchMode = LaunchMode.inAppBrowserView,
  }) async {
    final client = _client;
    if (client == null) {
      return;
    }

    await _run(() async {
      await client.auth.signInWithOAuth(
        provider,
        redirectTo: kIsWeb ? null : redirectUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : mobileLaunchMode,
      );
    });
  }

  Future<void> _signInWithNativeGoogle() async {
    final client = _client;
    if (client == null) {
      return;
    }

    await _run(() async {
      if (SupabaseConfig.googleWebClientId.isEmpty) {
        throw const AuthException(
          'Missing GOOGLE_WEB_CLIENT_ID in the app configuration.',
        );
      }
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          SupabaseConfig.googleIosClientId.isEmpty) {
        throw const AuthException(
          'Missing GOOGLE_IOS_CLIENT_ID in the app configuration.',
        );
      }

      final googleSignIn = GoogleSignIn.instance;
      if (!_googleSignInInitialized) {
        final rawNonce = client.auth.generateRawNonce();
        await googleSignIn.initialize(
          clientId: defaultTargetPlatform == TargetPlatform.iOS
              ? SupabaseConfig.googleIosClientId
              : null,
          serverClientId: SupabaseConfig.googleWebClientId,
          nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
        );
        _googleSignInRawNonce = rawNonce;
        _googleSignInInitialized = true;
      }

      final googleUser = await googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Google did not return an ID token.');
      }

      await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        nonce: _googleSignInRawNonce,
      );
    });
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) {
      return;
    }

    await _run(() async {
      await _stopPushNotifications(unregister: true);
      await client.auth.signOut();
      if (_googleSignInInitialized) {
        await GoogleSignIn.instance.signOut();
      }
      _clearAccountState();
    });
  }

  Future<bool> deleteAccount() async {
    final client = _client;
    if (client == null || !isSignedIn) {
      return false;
    }

    return _runWithResult(() async {
      await _stopPushNotifications(unregister: true);
      await client.rpc<Object?>('delete_account');
      await client.auth.signOut(scope: SignOutScope.global);
      if (_googleSignInInitialized) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {
          // The cloud account is already deleted; provider cleanup is best effort.
        }
      }
      _clearAccountState();
      return true;
    }, fallback: false);
  }

  Future<void> refresh() {
    final pendingRefresh = _refreshFuture;
    if (pendingRefresh != null) {
      return pendingRefresh;
    }

    final refreshFuture = _refresh();
    _refreshFuture = refreshFuture;
    return refreshFuture.whenComplete(() {
      if (identical(_refreshFuture, refreshFuture)) {
        _refreshFuture = null;
      }
    });
  }

  Future<void> _refresh() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      await _removeRealtimeSubscription();
      await _stopPushNotifications();
      _resolvedProfileUserId = null;
      _profile = null;
      _groups = const [];
      _invites = const [];
      _sharedLists = const [];
      _sharedVouchers = const [];
      _publicMarketLayouts = const [];
      _hasLoadedSharedData = false;
      notifyListeners();
      return;
    }

    await _run(() async {
      final profileJson = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      _profile = profileJson == null
          ? null
          : CloudProfile.fromJson(profileJson);
      _resolvedProfileUserId = user.id;

      if (_profile == null || !_profile!.hasStoreCountry) {
        _groups = const [];
        _invites = const [];
        _sharedLists = const [];
        _sharedVouchers = const [];
        _publicMarketLayouts = const [];
        _hasLoadedSharedData = false;
        await _removeRealtimeSubscription();
        return;
      }

      unawaited(_startPushNotifications());

      final groupRows = await client
          .from('spaces')
          .select('id,name,space_members!inner(role)')
          .eq('kind', 'group')
          .eq('space_members.user_id', user.id)
          .order('name');
      _groups = groupRows
          .whereType<Map>()
          .map((entry) => CloudGroup.fromJson(Map<String, dynamic>.from(entry)))
          .toList();

      await _loadInvites(user.id);

      await _loadAllSharedData();
      await _ensureRealtimeSubscription(user.id);
    });
  }

  Future<bool> completeProfile({
    required String displayName,
    required String countryCode,
  }) async {
    final client = _client;
    if (client == null) {
      return false;
    }

    return _runWithResult(() async {
      await client.rpc<Object?>(
        'complete_profile',
        params: {
          'display_name': displayName.trim(),
          'country_code': countryCode.toLowerCase(),
        },
      );
      await refresh();
      return _profile?.hasStoreCountry == true;
    }, fallback: false);
  }

  Future<bool> updateProfileCountry(String countryCode) async {
    final client = _client;
    if (client == null || !isSignedIn) {
      return false;
    }

    return _runWithResult(() async {
      await client.rpc<Object?>(
        'update_profile_country',
        params: {'country_code': countryCode.toLowerCase()},
      );
      await refresh();
      return _profile?.hasStoreCountry == true;
    }, fallback: false);
  }

  Future<bool> createGroup(String name) async {
    final client = _client;
    if (client == null || _profile?.hasStoreCountry != true) {
      return false;
    }

    return _runWithResult(() async {
      await client.rpc<Object?>(
        'create_group',
        params: {'group_name': name.trim()},
      );
      await refresh();
      return true;
    }, fallback: false);
  }

  Future<bool> inviteUser({
    required String groupId,
    required String handle,
  }) async {
    final client = _client;
    if (client == null || !isValidPublicHandle(handle)) {
      _errorKind = null;
      _errorMessage = 'Use the Name#1234 format.';
      notifyListeners();
      return false;
    }

    return _runWithResult(() async {
      await client.rpc<Object?>(
        'invite_user_by_handle',
        params: {'space_id': groupId, 'handle': handle.trim()},
      );
      return true;
    }, fallback: false);
  }

  Future<bool> respondToInvite({
    required String inviteId,
    required bool accept,
  }) async {
    final client = _client;
    if (client == null) {
      return false;
    }

    return _runWithResult(() async {
      await client.rpc<Object?>(
        'respond_to_group_invite',
        params: {'invite_id': inviteId, 'accept_invite': accept},
      );
      await refresh();
      return true;
    }, fallback: false);
  }

  Future<bool> leaveGroup(String groupId) async {
    final client = _client;
    if (client == null || !isSignedIn) {
      return false;
    }

    return _runWithResult(() async {
      await client.rpc<Object?>(
        'leave_group',
        params: {'target_space_id': groupId},
      );
      await refresh();
      return true;
    }, fallback: false);
  }

  Future<List<SharedGroceryList>> loadSharedLists(String groupId) async {
    if (_client == null) {
      return const [];
    }
    if (!_hasLoadedSharedData && isSignedIn) {
      await refreshSharedData();
    }
    return sharedListsForGroup(groupId);
  }

  Future<List<SharedDepositVoucher>> loadSharedVouchers(String groupId) async {
    if (_client == null) {
      return const [];
    }
    if (!_hasLoadedSharedData && isSignedIn) {
      await refreshSharedData();
    }
    return sharedVouchersForGroup(groupId);
  }

  Future<bool> shareListWithGroup({
    required String groupId,
    required GroceryListModel list,
  }) async {
    final client = _client;
    if (client == null) {
      return false;
    }

    return _runWithResult(() async {
      await client.rpc<Object?>(
        'copy_grocery_list_to_group',
        params: {
          'space_id': groupId,
          'source_local_id': list.id,
          'list_name': list.name,
          'items': list.items.map((item) => item.toJson()).toList(),
        },
      );
      await _loadAllSharedData();
      return true;
    }, fallback: false);
  }

  Future<bool> copyListToGroup({
    required String groupId,
    required GroceryListModel list,
  }) {
    return shareListWithGroup(groupId: groupId, list: list);
  }

  Future<SharedGroceryList?> fetchSharedList(String listId) async {
    final client = _client;
    if (client == null) {
      return null;
    }

    return _runWithResult(() async {
      final row = await client
          .from('shared_grocery_lists')
          .select(
            'id,space_id,source_local_id,name,spaces(name),'
            'shared_grocery_items(id,name,category,quantity)',
          )
          .eq('id', listId)
          .maybeSingle();
      return row == null ? null : SharedGroceryList.fromJson(row);
    }, fallback: null);
  }

  Future<bool> moveVoucherToGroup({
    required String groupId,
    required DepositVoucher voucher,
    required NearbyStoreSuggestion store,
  }) async {
    final client = _client;
    if (client == null || !_ensureStoreMatchesProfileCountry(store)) {
      return false;
    }

    return _runWithResult(() async {
      await client.rpc<Object?>(
        'move_deposit_voucher_to_group',
        params: {
          'space_id': groupId,
          'voucher': voucher.toJson(),
          'store_location_id': store.storeLocationId,
        },
      );
      await _loadAllSharedData();
      return true;
    }, fallback: false);
  }

  Future<bool> renameSharedList({
    required String listId,
    required String newName,
  }) async {
    final client = _client;
    final cleanedName = newName.trim();
    if (client == null || cleanedName.isEmpty) {
      return false;
    }

    return _runWithResult(() async {
      await client
          .from('shared_grocery_lists')
          .update({'name': cleanedName})
          .eq('id', listId);
      await _loadAllSharedData();
      return true;
    }, fallback: false);
  }

  Future<bool> deleteSharedList(String listId) async {
    final client = _client;
    if (client == null) {
      return false;
    }

    return _runWithResult(() async {
      final deleted = await client
          .from('shared_grocery_lists')
          .delete()
          .eq('id', listId)
          .select('id')
          .maybeSingle();
      if (deleted == null) {
        throw const PostgrestException(
          message: 'The shared list could not be removed.',
        );
      }
      await _loadAllSharedData();
      return true;
    }, fallback: false);
  }

  Future<bool> addItemToSharedList({
    required String listId,
    required String itemName,
    required String category,
    required int quantity,
  }) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    final cleanedName = itemName.trim();
    final cleanedCategory = category.trim();
    if (client == null ||
        userId == null ||
        cleanedName.isEmpty ||
        cleanedCategory.isEmpty) {
      return false;
    }

    return _runWithResult(() async {
      await client.from('shared_grocery_items').insert({
        'list_id': listId,
        'name': cleanedName,
        'category': cleanedCategory,
        'quantity': quantity < 1 ? 1 : quantity,
        'created_by': userId,
      });
      await _loadAllSharedData();
      return true;
    }, fallback: false);
  }

  Future<bool> updateSharedItem({
    required String listId,
    required String itemId,
    required String itemName,
    required String category,
    required int quantity,
  }) async {
    final client = _client;
    final cleanedName = itemName.trim();
    final cleanedCategory = category.trim();
    if (client == null || cleanedName.isEmpty || cleanedCategory.isEmpty) {
      return false;
    }

    return _runWithResult(() async {
      await client
          .from('shared_grocery_items')
          .update({
            'name': cleanedName,
            'category': cleanedCategory,
            'quantity': quantity < 1 ? 1 : quantity,
          })
          .eq('list_id', listId)
          .eq('id', itemId);
      await _loadAllSharedData();
      return true;
    }, fallback: false);
  }

  Future<bool> removeItemFromSharedList({
    required String listId,
    required String itemId,
  }) async {
    return removeItemsFromSharedList(listId: listId, itemIds: [itemId]);
  }

  Future<bool> removeItemsFromSharedList({
    required String listId,
    required Iterable<String> itemIds,
  }) async {
    final client = _client;
    final ids = itemIds.toSet().toList();
    if (client == null || ids.isEmpty) {
      return false;
    }

    return _runWithResult(() async {
      await client
          .from('shared_grocery_items')
          .delete()
          .eq('list_id', listId)
          .inFilter('id', ids);
      await _loadAllSharedData();
      return true;
    }, fallback: false);
  }

  Future<bool> notifySharedListAdditionsCompleted(String listId) async {
    final client = _client;
    if (client == null || !isSignedIn) {
      return false;
    }

    try {
      final response = await client.functions.invoke(
        'notify-shared-list-additions',
        body: {'list_id': listId},
      );
      final data = response.data;
      debugPrint('Shared-list push notification result: $data');
      return data is Map && data['accepted'] == true;
    } catch (error) {
      debugPrint('Failed to send shared-list push notification: $error');
      return false;
    }
  }

  Future<bool> hideSharedVoucher(String voucherId) async {
    final client = _client;
    if (client == null) {
      return false;
    }

    return _runWithResult(() async {
      await client.rpc<Object?>(
        'hide_shared_deposit_voucher',
        params: {'target_voucher_id': voucherId},
      );
      await _loadAllSharedData();
      return true;
    }, fallback: false);
  }

  Future<bool> useSharedVoucher(String voucherId) async {
    final client = _client;
    if (client == null) {
      return false;
    }

    return _runWithResult(() async {
      await client.rpc<Object?>(
        'use_shared_deposit_voucher',
        params: {'target_voucher_id': voucherId},
      );
      await _loadAllSharedData();
      return true;
    }, fallback: false);
  }

  Future<bool> deleteSharedVoucher(String voucherId) {
    return hideSharedVoucher(voucherId);
  }

  Future<List<GeoapifyAddressSuggestion>> searchStoreAddresses({
    required String query,
    required String languageCode,
  }) async {
    final client = _client;
    final cleanedQuery = query.trim();
    if (client == null ||
        !isSignedIn ||
        _profile?.hasStoreCountry != true ||
        cleanedQuery.length < 3) {
      return const [];
    }

    return _runWithResult(() async {
      final response = await client.functions.invoke(
        'geoapify-address-search',
        body: {'query': cleanedQuery, 'language': languageCode},
      );
      final data = response.data;
      if (data is! Map) {
        return const <GeoapifyAddressSuggestion>[];
      }
      final rows = data['suggestions'];
      if (rows is! List) {
        return const <GeoapifyAddressSuggestion>[];
      }
      return rows
          .whereType<Map>()
          .map(
            (entry) => GeoapifyAddressSuggestion.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList();
    }, fallback: const []);
  }

  Future<List<NearbyStoreSuggestion>> searchNearbyStores({
    required GeoapifyAddressSuggestion address,
    required String languageCode,
  }) async {
    final client = _client;
    if (client == null || !isSignedIn || _profile?.hasStoreCountry != true) {
      return const [];
    }

    return _runWithResult(() async {
      final response = await client.functions.invoke(
        'geoapify-address-search',
        body: {
          'mode': 'nearby_stores',
          'latitude': address.latitude,
          'longitude': address.longitude,
          'language': languageCode,
        },
      );
      final data = response.data;
      if (data is! Map) {
        return const <NearbyStoreSuggestion>[];
      }
      final rows = data['stores'];
      if (rows is! List) {
        return const <NearbyStoreSuggestion>[];
      }
      return rows
          .whereType<Map>()
          .map(
            (entry) => NearbyStoreSuggestion.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList();
    }, fallback: const []);
  }

  Future<PublishMarketLayoutResult> publishMarketLayout({
    required MarketLayout layout,
    required NearbyStoreSuggestion store,
    required List<String> onlineCategoryOrder,
  }) async {
    if (onlineCategoryOrder.any((id) => !OnlineCategories.isId(id))) {
      return PublishMarketLayoutResult.failed;
    }
    final canonicalCategoryOrder = OnlineCategories.canonicalizeOrder(
      onlineCategoryOrder,
    );
    final client = _client;
    if (client == null ||
        !isSignedIn ||
        store.storeLocationId.isEmpty ||
        !_ensureStoreMatchesProfileCountry(store)) {
      return PublishMarketLayoutResult.failed;
    }

    return _runWithResult(() async {
      final result = await client.rpc<Object?>(
        'publish_market_layout',
        params: {
          'store_location_id': store.storeLocationId,
          'source_local_id': layout.id,
          'category_order': canonicalCategoryOrder,
        },
      );
      if (result == 'duplicate') {
        return PublishMarketLayoutResult.duplicate;
      }
      if (result != 'published') {
        throw const PostgrestException(
          message: 'The store map could not be published.',
        );
      }
      await _loadAllSharedData();
      return PublishMarketLayoutResult.published;
    }, fallback: PublishMarketLayoutResult.failed);
  }

  Future<bool> unpublishMarketLayout(String publicMapId) async {
    final client = _client;
    if (client == null || !isSignedIn) {
      return false;
    }

    return _runWithResult(() async {
      final deleted = await client
          .from('shared_market_layouts')
          .delete()
          .eq('id', publicMapId)
          .select('id')
          .maybeSingle();
      if (deleted == null) {
        throw const PostgrestException(
          message: 'The public store map could not be removed.',
        );
      }
      await _loadAllSharedData();
      return true;
    }, fallback: false);
  }

  Future<bool> recordMarketLayoutDownload(String publicMapId) async {
    final client = _client;
    if (client == null || !isSignedIn) {
      return false;
    }

    return _runWithResult(() async {
      await client.rpc<Object?>(
        'record_market_layout_download',
        params: {'target_shared_layout_id': publicMapId},
      );
      await _loadAllSharedData();
      return true;
    }, fallback: false);
  }

  Future<bool> reportMarketLayout({
    required String publicMapId,
    required String reason,
  }) async {
    final client = _client;
    if (client == null || !isSignedIn) {
      return false;
    }

    return _runWithResult(() async {
      await client.rpc<Object?>(
        'report_public_market_layout',
        params: {
          'target_shared_layout_id': publicMapId,
          'report_reason': reason,
        },
      );
      return true;
    }, fallback: false);
  }

  Future<void> refreshSharedData() async {
    if (_client == null || !isSignedIn || _profile?.hasStoreCountry != true) {
      return;
    }
    await _run(_loadAllSharedData);
  }

  Future<void> _loadAllSharedData() async {
    final client = _client;
    if (client == null || !isSignedIn || _profile?.hasStoreCountry != true) {
      _sharedLists = const [];
      _sharedVouchers = const [];
      _publicMarketLayouts = const [];
      _hasLoadedSharedData = false;
      return;
    }

    final listRows = await client
        .from('shared_grocery_lists')
        .select(
          'id,space_id,source_local_id,name,spaces(name),'
          'shared_grocery_items(id,name,category,quantity)',
        )
        .order('created_at', ascending: false);
    final voucherRows = await client
        .from('shared_deposit_vouchers')
        .select(
          'id,space_id,code,format,scanned_at,amount,store_name,'
          'valid_until,redeemed_at,spaces(name)',
        )
        .order('created_at', ascending: false);
    final hiddenVoucherRows = await client
        .from('hidden_shared_deposit_vouchers')
        .select('voucher_id');
    final marketLayoutRows = await client
        .from('shared_market_layouts')
        .select(
          'id,created_by,creator_handle_snapshot,source_local_id,'
          'category_order,download_count,updated_at,store_locations('
          'id,provider_place_id,store_name,formatted_address,street,'
          'house_number,postcode,city,country_code,latitude,longitude)',
        )
        .order('download_count', ascending: false)
        .order('updated_at', ascending: false);

    _sharedLists = listRows
        .whereType<Map>()
        .map(
          (entry) =>
              SharedGroceryList.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList();
    final hiddenVoucherIds = hiddenVoucherRows
        .whereType<Map>()
        .map((entry) => entry['voucher_id']?.toString())
        .whereType<String>()
        .toSet();
    _sharedVouchers = voucherRows
        .whereType<Map>()
        .map(
          (entry) =>
              SharedDepositVoucher.fromJson(Map<String, dynamic>.from(entry)),
        )
        .where((voucher) => !hiddenVoucherIds.contains(voucher.id))
        .toList();
    _publicMarketLayouts = marketLayoutRows
        .whereType<Map>()
        .map(
          (entry) =>
              SharedMarketLayout.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList();
    _hasLoadedSharedData = true;
    notifyListeners();
  }

  bool _ensureStoreMatchesProfileCountry(NearbyStoreSuggestion store) {
    final countryCode = _profile?.countryCode?.toLowerCase();
    if (!StoreCountries.isSupported(countryCode)) {
      return false;
    }
    if (store.address.countryCode.toLowerCase() == countryCode) {
      return true;
    }

    _errorKind = CloudErrorKind.storeCountryMismatch;
    _errorMessage = 'STORE_COUNTRY_MISMATCH';
    notifyListeners();
    return false;
  }

  Future<void> _ensureRealtimeSubscription(String userId) async {
    final client = _client;
    if (client == null ||
        (_sharedDataChannel != null && _realtimeUserId == userId)) {
      return;
    }

    await _removeRealtimeSubscription();
    _realtimeUserId = userId;
    _sharedDataChannel = client
        .channel('shared-data-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shared_grocery_lists',
          callback: (_) => _scheduleSharedDataRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shared_grocery_items',
          callback: (_) => _scheduleSharedDataRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shared_deposit_vouchers',
          callback: (_) => _scheduleSharedDataRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'hidden_shared_deposit_vouchers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _scheduleSharedDataRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shared_market_layouts',
          callback: (_) => _scheduleSharedDataRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_invites',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'invited_user_id',
            value: userId,
          ),
          callback: (_) => _scheduleInvitesRefresh(userId),
        )
        .subscribe();
  }

  Future<void> _loadInvites(String userId) async {
    final client = _client;
    if (client == null || client.auth.currentUser?.id != userId) {
      return;
    }

    final inviteRows = await client
        .from('group_invites')
        .select()
        .eq('invited_user_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    _invites = inviteRows
        .whereType<Map>()
        .map(
          (entry) =>
              CloudGroupInvite.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList();
  }

  void _scheduleInvitesRefresh(String userId) {
    _inviteRefreshTimer?.cancel();
    _inviteRefreshTimer = Timer(const Duration(milliseconds: 180), () async {
      try {
        await _loadInvites(userId);
        notifyListeners();
      } catch (error) {
        debugPrint(
          'Failed to refresh invitations after Realtime event: $error',
        );
      }
    });
  }

  void _scheduleSharedDataRefresh() {
    _sharedRefreshTimer?.cancel();
    _sharedRefreshTimer = Timer(const Duration(milliseconds: 180), () async {
      try {
        await _loadAllSharedData();
      } catch (error) {
        debugPrint(
          'Failed to refresh shared data after Realtime event: $error',
        );
      }
    });
  }

  Future<void> _removeRealtimeSubscription() async {
    _sharedRefreshTimer?.cancel();
    _sharedRefreshTimer = null;
    _inviteRefreshTimer?.cancel();
    _inviteRefreshTimer = null;
    final client = _client;
    final channel = _sharedDataChannel;
    _sharedDataChannel = null;
    _realtimeUserId = null;
    if (client != null && channel != null) {
      await client.removeChannel(channel);
    }
  }

  Future<void> _startPushNotifications() async {
    final service = _pushNotificationService;
    if (service == null || !isSignedIn || _profile == null) {
      return;
    }
    await service.start(onToken: _registerPushToken);
  }

  Future<void> _registerPushToken(String token) async {
    final client = _client;
    final service = _pushNotificationService;
    if (client == null || service == null || !isSignedIn) {
      return;
    }

    try {
      await client.rpc<Object?>(
        'register_push_device',
        params: {'device_token': token, 'device_platform': service.platform},
      );
      _registeredPushToken = token;
      debugPrint('Push notifications: device registered in Supabase.');
    } catch (error, stackTrace) {
      debugPrint('Failed to register push token: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _stopPushNotifications({bool unregister = false}) async {
    final client = _client;
    final service = _pushNotificationService;
    if (service == null) {
      return;
    }

    final token = _registeredPushToken ?? service.currentToken;
    if (unregister && client != null && isSignedIn && token != null) {
      try {
        await client.rpc<Object?>(
          'unregister_push_device',
          params: {'device_token': token},
        );
      } catch (error) {
        debugPrint('Failed to unregister push token: $error');
      }
    }

    _registeredPushToken = null;
    await service.stop(deleteToken: true);
  }

  Future<void> _run(Future<void> Function() action) async {
    _pendingOperations++;
    _errorMessage = null;
    _errorKind = null;
    notifyListeners();

    try {
      await action();
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled) {
        _errorMessage =
            error.description ?? 'Google sign-in failed (${error.code.name}).';
      }
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } on PostgrestException catch (error) {
      _errorKind = classifyCloudPostgrestException(error);
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _pendingOperations--;
      notifyListeners();
    }
  }

  Future<T> _runWithResult<T>(
    Future<T> Function() action, {
    required T fallback,
  }) async {
    var result = fallback;
    await _run(() async {
      result = await action();
    });
    return result;
  }

  void clearError() {
    _errorMessage = null;
    _errorKind = null;
    notifyListeners();
  }

  void _clearAccountState() {
    _resolvedProfileUserId = null;
    _profile = null;
    _groups = const [];
    _invites = const [];
    _sharedLists = const [];
    _sharedVouchers = const [];
    _publicMarketLayouts = const [];
    _hasLoadedSharedData = false;
    unawaited(_removeRealtimeSubscription());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _sharedRefreshTimer?.cancel();
    _inviteRefreshTimer?.cancel();
    final channel = _sharedDataChannel;
    if (channel != null) {
      unawaited(_client?.removeChannel(channel));
    }
    _pushNotificationService?.dispose();
    super.dispose();
  }
}
