import '../models.dart';

class CloudProfile {
  const CloudProfile({
    required this.id,
    required this.displayName,
    required this.discriminator,
  });

  factory CloudProfile.fromJson(Map<String, dynamic> json) {
    return CloudProfile(
      id: json['id'].toString(),
      displayName: json['display_name'].toString(),
      discriminator: json['discriminator'] as int,
    );
  }

  final String id;
  final String displayName;
  final int discriminator;

  String get handle =>
      '$displayName#${discriminator.toString().padLeft(4, '0')}';
}

class CloudGroup {
  const CloudGroup({required this.id, required this.name, required this.role});

  factory CloudGroup.fromJson(Map<String, dynamic> json) {
    final memberships = (json['space_members'] as List<dynamic>? ?? const []);
    final typedMemberships = memberships.whereType<Map>();
    final membership = typedMemberships.isEmpty ? null : typedMemberships.first;

    return CloudGroup(
      id: json['id'].toString(),
      name: json['name'].toString(),
      role: membership?['role']?.toString() ?? 'member',
    );
  }

  final String id;
  final String name;
  final String role;

  bool get canInvite => role == 'owner' || role == 'admin';
}

class CloudGroupMember {
  const CloudGroupMember({
    required this.userId,
    required this.displayName,
    required this.role,
  });

  factory CloudGroupMember.fromJson(Map<String, dynamic> json) {
    return CloudGroupMember(
      userId: json['member_user_id'].toString(),
      displayName: json['display_name'].toString(),
      role: json['member_role'].toString(),
    );
  }

  final String userId;
  final String displayName;
  final String role;
}

class CloudGroupInvite {
  const CloudGroupInvite({
    required this.id,
    required this.spaceId,
    required this.groupName,
    required this.inviterHandle,
  });

  factory CloudGroupInvite.fromJson(Map<String, dynamic> json) {
    return CloudGroupInvite(
      id: json['id'].toString(),
      spaceId: json['space_id'].toString(),
      groupName: json['space_name_snapshot'].toString(),
      inviterHandle: json['inviter_handle_snapshot'].toString(),
    );
  }

  final String id;
  final String spaceId;
  final String groupName;
  final String inviterHandle;
}

class SharedGroceryList {
  const SharedGroceryList({
    required this.id,
    required this.spaceId,
    required this.groupName,
    required this.name,
    required this.items,
    this.sourceLocalId,
  });

  factory SharedGroceryList.fromJson(Map<String, dynamic> json) {
    return SharedGroceryList(
      id: json['id'].toString(),
      spaceId: json['space_id'].toString(),
      groupName: _relatedSpaceName(json),
      name: json['name'].toString(),
      sourceLocalId: json['source_local_id']?.toString(),
      items: (json['shared_grocery_items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (entry) => GroceryItem(
              id: entry['id'].toString(),
              name: entry['name'].toString(),
              category: entry['category'].toString(),
              quantity: entry['quantity'] as int? ?? 1,
            ),
          )
          .toList(),
    );
  }

  final String id;
  final String spaceId;
  final String groupName;
  final String name;
  final List<GroceryItem> items;
  final String? sourceLocalId;

  GroceryListModel toGroceryListModel() {
    return GroceryListModel(id: id, name: name, items: items);
  }

  GroceryListModel toPrivateGroceryListModel() {
    return GroceryListModel(id: sourceLocalId ?? id, name: name, items: items);
  }
}

class SharedDepositVoucher {
  const SharedDepositVoucher({
    required this.id,
    required this.spaceId,
    required this.groupName,
    required this.code,
    required this.format,
    required this.scannedAt,
    required this.amount,
    required this.storeName,
    required this.validUntil,
    required this.redeemedAt,
  });

  factory SharedDepositVoucher.fromJson(Map<String, dynamic> json) {
    return SharedDepositVoucher(
      id: json['id'].toString(),
      spaceId: json['space_id'].toString(),
      groupName: _relatedSpaceName(json),
      code: json['code'].toString(),
      format: json['format']?.toString() ?? 'unknown',
      scannedAt:
          DateTime.tryParse(json['scanned_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      storeName: json['store_name'].toString(),
      validUntil: DateTime.tryParse(json['valid_until']?.toString() ?? ''),
      redeemedAt: DateTime.tryParse(json['redeemed_at']?.toString() ?? ''),
    );
  }

  final String id;
  final String spaceId;
  final String groupName;
  final String code;
  final String format;
  final DateTime scannedAt;
  final double amount;
  final String storeName;
  final DateTime? validUntil;
  final DateTime? redeemedAt;

  DepositVoucher toDepositVoucher() {
    return DepositVoucher(
      id: id,
      code: code,
      format: format,
      scannedAt: scannedAt,
      amount: amount,
      storeName: storeName,
      validUntil: validUntil,
    );
  }
}

class GeoapifyAddressSuggestion {
  const GeoapifyAddressSuggestion({
    required this.providerPlaceId,
    required this.formattedAddress,
    required this.street,
    required this.houseNumber,
    required this.postcode,
    required this.city,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
  });

  factory GeoapifyAddressSuggestion.fromJson(Map<String, dynamic> json) {
    return GeoapifyAddressSuggestion(
      providerPlaceId: json['provider_place_id'].toString(),
      formattedAddress: json['formatted_address'].toString(),
      street: json['street']?.toString(),
      houseNumber: json['house_number']?.toString(),
      postcode: json['postcode']?.toString(),
      city: json['city']?.toString(),
      countryCode: json['country_code'].toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  final String providerPlaceId;
  final String formattedAddress;
  final String? street;
  final String? houseNumber;
  final String? postcode;
  final String? city;
  final String countryCode;
  final double latitude;
  final double longitude;

  Map<String, dynamic> toPublishJson(String storeName) {
    return {
      'provider': 'geoapify',
      'provider_place_id': providerPlaceId,
      'store_name': storeName.trim(),
      'formatted_address': formattedAddress,
      'street': street,
      'house_number': houseNumber,
      'postcode': postcode,
      'city': city,
      'country_code': countryCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class NearbyStoreSuggestion {
  const NearbyStoreSuggestion({
    required this.name,
    required this.distanceMeters,
    required this.categories,
    required this.address,
  });

  factory NearbyStoreSuggestion.fromJson(Map<String, dynamic> json) {
    return NearbyStoreSuggestion(
      name: json['name'].toString(),
      distanceMeters: (json['distance_meters'] as num?)?.round() ?? 0,
      categories: (json['categories'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(),
      address: GeoapifyAddressSuggestion.fromJson(json),
    );
  }

  final String name;
  final int distanceMeters;
  final List<String> categories;
  final GeoapifyAddressSuggestion address;
}

class CloudStoreLocation {
  const CloudStoreLocation({
    required this.id,
    required this.providerPlaceId,
    required this.storeName,
    required this.formattedAddress,
    required this.street,
    required this.houseNumber,
    required this.postcode,
    required this.city,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
  });

  factory CloudStoreLocation.fromJson(Map<String, dynamic> json) {
    return CloudStoreLocation(
      id: json['id'].toString(),
      providerPlaceId: json['provider_place_id'].toString(),
      storeName: json['store_name'].toString(),
      formattedAddress: json['formatted_address'].toString(),
      street: json['street']?.toString(),
      houseNumber: json['house_number']?.toString(),
      postcode: json['postcode']?.toString(),
      city: json['city']?.toString(),
      countryCode: json['country_code'].toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  final String id;
  final String providerPlaceId;
  final String storeName;
  final String formattedAddress;
  final String? street;
  final String? houseNumber;
  final String? postcode;
  final String? city;
  final String countryCode;
  final double latitude;
  final double longitude;

  GeoapifyAddressSuggestion toAddressSuggestion() {
    return GeoapifyAddressSuggestion(
      providerPlaceId: providerPlaceId,
      formattedAddress: formattedAddress,
      street: street,
      houseNumber: houseNumber,
      postcode: postcode,
      city: city,
      countryCode: countryCode,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class SharedMarketLayout {
  const SharedMarketLayout({
    required this.id,
    required this.createdBy,
    required this.creatorHandle,
    required this.sourceLocalId,
    required this.categoryOrder,
    required this.location,
    required this.downloadCount,
    required this.updatedAt,
  });

  factory SharedMarketLayout.fromJson(Map<String, dynamic> json) {
    final rawLocation = json['store_locations'];
    if (rawLocation is! Map) {
      throw const FormatException('Shared map has no store location.');
    }

    return SharedMarketLayout(
      id: json['id'].toString(),
      createdBy: json['created_by'].toString(),
      creatorHandle: json['creator_handle_snapshot'].toString(),
      sourceLocalId: json['source_local_id'].toString(),
      categoryOrder: (json['category_order'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(),
      location: CloudStoreLocation.fromJson(
        Map<String, dynamic>.from(rawLocation),
      ),
      downloadCount: json['download_count'] as int? ?? 0,
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String id;
  final String createdBy;
  final String creatorHandle;
  final String sourceLocalId;
  final List<String> categoryOrder;
  final CloudStoreLocation location;
  final int downloadCount;
  final DateTime updatedAt;

  String get creatorInitial {
    final nickname = creatorHandle.split('#').first.trim();
    return nickname.isEmpty
        ? '?'
        : String.fromCharCode(nickname.runes.first).toUpperCase();
  }

  MarketLayout toLocalMarketLayout() {
    return MarketLayout(
      id: createId(),
      name: location.storeName,
      categoryOrder: categoryOrder,
      sourceSharedMarketLayoutId: id,
    );
  }
}

enum PublishMarketLayoutResult { published, duplicate, failed }

bool isValidPublicHandle(String value) {
  return RegExp(r'^.+#[0-9]{4}$').hasMatch(value.trim());
}

String _relatedSpaceName(Map<String, dynamic> json) {
  final relatedSpace = json['spaces'];
  if (relatedSpace is Map) {
    return relatedSpace['name']?.toString() ?? '';
  }
  return json['group_name']?.toString() ?? '';
}
