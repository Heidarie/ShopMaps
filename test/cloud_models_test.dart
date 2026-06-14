import 'package:flutter_test/flutter_test.dart';
import 'package:shopmaps/cloud/cloud_models.dart';

void main() {
  test('profile formats a public handle with a four-digit tag', () {
    final profile = CloudProfile.fromJson({
      'id': 'user-id',
      'display_name': 'Endriu',
      'discriminator': 42,
    });

    expect(profile.handle, 'Endriu#0042');
  });

  test('public handle requires a name and exactly four digits', () {
    expect(isValidPublicHandle('Endriu#1337'), isTrue);
    expect(isValidPublicHandle(' Endriu#1337 '), isTrue);
    expect(isValidPublicHandle('Endriu#123'), isFalse);
    expect(isValidPublicHandle('Endriu'), isFalse);
  });

  test('shared grocery list includes its group and converts to app model', () {
    final sharedList = SharedGroceryList.fromJson({
      'id': 'list-id',
      'space_id': 'group-id',
      'source_local_id': 'local-list-id',
      'name': 'Weekend',
      'spaces': {'name': 'Dom'},
      'shared_grocery_items': [
        {'id': 'item-id', 'name': 'Mleko', 'category': 'Nabiał', 'quantity': 2},
      ],
    });

    expect(sharedList.spaceId, 'group-id');
    expect(sharedList.groupName, 'Dom');
    expect(sharedList.sourceLocalId, 'local-list-id');
    expect(sharedList.toGroceryListModel().items.single.name, 'Mleko');
    expect(sharedList.toPrivateGroceryListModel().id, 'local-list-id');
  });

  test('shared voucher preserves data required by the main deposit tab', () {
    final sharedVoucher = SharedDepositVoucher.fromJson({
      'id': 'voucher-id',
      'space_id': 'group-id',
      'spaces': {'name': 'Dom'},
      'code': 'ABC123',
      'format': 'qrCode',
      'scanned_at': '2026-06-11T10:00:00Z',
      'amount': 12.5,
      'store_name': 'Market',
      'valid_until': '2026-07-01T00:00:00Z',
      'redeemed_at': null,
    });

    final voucher = sharedVoucher.toDepositVoucher();
    expect(sharedVoucher.groupName, 'Dom');
    expect(voucher.code, 'ABC123');
    expect(voucher.format, 'qrCode');
    expect(voucher.scannedAt.toUtc(), DateTime.utc(2026, 6, 11, 10));
  });

  test('public market layout includes a canonical store location', () {
    final sharedMap = SharedMarketLayout.fromJson({
      'id': 'shared-map-id',
      'created_by': 'user-id',
      'creator_handle_snapshot': 'Endriu#0042',
      'source_local_id': 'local-map-id',
      'category_order': ['Bakery', 'Dairy'],
      'download_count': 12,
      'updated_at': '2026-06-11T12:00:00Z',
      'store_locations': {
        'id': 'location-id',
        'provider_place_id': 'geoapify-place-id',
        'store_name': 'Market',
        'formatted_address': 'ul. Pułaskiego 10, Warszawa',
        'street': 'Pułaskiego',
        'house_number': '10',
        'postcode': '00-001',
        'city': 'Warszawa',
        'country_code': 'pl',
        'latitude': 52.2,
        'longitude': 21.0,
      },
    });

    expect(sharedMap.location.providerPlaceId, 'geoapify-place-id');
    expect(sharedMap.location.formattedAddress, contains('Pułaskiego'));
    expect(sharedMap.creatorInitial, 'E');
    expect(sharedMap.downloadCount, 12);
    expect(sharedMap.toLocalMarketLayout().categoryOrder, ['Bakery', 'Dairy']);
    expect(
      sharedMap.toLocalMarketLayout().sourceSharedMarketLayoutId,
      'shared-map-id',
    );
    expect(sharedMap.toLocalMarketLayout().id, isNot('local-map-id'));
  });

  test('Geoapify address suggestion creates publish payload', () {
    final suggestion = GeoapifyAddressSuggestion.fromJson({
      'provider_place_id': 'place-id',
      'formatted_address': 'Pułaskiego 10, Warszawa',
      'street': 'Pułaskiego',
      'house_number': '10',
      'postcode': '00-001',
      'city': 'Warszawa',
      'country_code': 'pl',
      'latitude': 52.2,
      'longitude': 21.0,
    });

    final payload = suggestion.toPublishJson(' Market ');
    expect(payload['provider'], 'geoapify');
    expect(payload['store_name'], 'Market');
    expect(payload['provider_place_id'], 'place-id');
  });

  test(
    'nearby store suggestion includes its distance and canonical address',
    () {
      final store = NearbyStoreSuggestion.fromJson({
        'provider_place_id': 'store-place-id',
        'name': 'Lidl',
        'formatted_address': 'Pułaskiego 12, Warszawa',
        'street': 'Pułaskiego',
        'house_number': '12',
        'postcode': '00-001',
        'city': 'Warszawa',
        'country_code': 'pl',
        'latitude': 52.2,
        'longitude': 21.0,
        'distance_meters': 87,
        'categories': ['commercial.supermarket'],
      });

      expect(store.name, 'Lidl');
      expect(store.distanceMeters, 87);
      expect(store.address.providerPlaceId, 'store-place-id');
      expect(store.categories, contains('commercial.supermarket'));
    },
  );
}
