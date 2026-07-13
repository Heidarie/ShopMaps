import 'package:flutter_test/flutter_test.dart';
import 'package:shopmaps/cloud/cloud_controller.dart';
import 'package:shopmaps/cloud/cloud_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ErroredCloudController extends CloudController {
  _ErroredCloudController({required this.message, this.kind}) : super(null);

  final String? message;
  final CloudErrorKind? kind;

  @override
  String? get errorMessage => message;

  @override
  CloudErrorKind? get errorKind => kind;
}

void main() {
  test('blocks Facebook sign-in when the SSO flag is disabled', () async {
    final controller = CloudController(null);
    await controller.signInWithFacebook();

    expect(
      controller.errorMessage,
      'Facebook sign-in is disabled in this build.',
    );

    controller.dispose();
  });

  test('classifies the stable content filter database error', () {
    const error = PostgrestException(
      message: 'CONTENT_NOT_ALLOWED',
      code: 'P0001',
      details: 'CONTENT_NOT_ALLOWED',
    );

    expect(
      classifyCloudPostgrestException(error),
      CloudErrorKind.contentRejected,
    );
  });

  test('leaves unrelated database errors unclassified', () {
    const error = PostgrestException(
      message: 'Group membership required',
      code: 'P0001',
    );

    expect(classifyCloudPostgrestException(error), isNull);
  });

  test('classifies the canonical store database error', () {
    const error = PostgrestException(
      message: 'CANONICAL_STORE_REQUIRED',
      code: 'P0001',
      details: 'CANONICAL_STORE_REQUIRED',
    );

    expect(
      classifyCloudPostgrestException(error),
      CloudErrorKind.canonicalStoreRequired,
    );
  });

  test('classifies the store country mismatch database error', () {
    const error = PostgrestException(
      message: 'STORE_COUNTRY_MISMATCH',
      code: 'P0001',
      details: 'STORE_COUNTRY_MISMATCH',
    );

    expect(
      classifyCloudPostgrestException(error),
      CloudErrorKind.storeCountryMismatch,
    );
  });

  test('shows raw fallback errors when raw details are enabled', () {
    final controller = _ErroredCloudController(
      message: 'PostgrestException: secret details',
    );

    expect(
      CloudLocalizations('pl').errorMessage(controller, showRawDetails: true),
      'PostgrestException: secret details',
    );

    controller.dispose();
  });

  test('hides raw fallback errors when raw details are disabled', () {
    final controller = _ErroredCloudController(
      message: 'PostgrestException: secret details',
    );

    expect(
      CloudLocalizations('pl').errorMessage(controller, showRawDetails: false),
      'Coś poszło nie tak. Spróbuj ponownie.',
    );

    controller.dispose();
  });

  test('keeps classified errors specific when raw details are disabled', () {
    final controller = _ErroredCloudController(
      message: 'CONTENT_NOT_ALLOWED',
      kind: CloudErrorKind.contentRejected,
    );

    expect(
      CloudLocalizations('pl').errorMessage(controller, showRawDetails: false),
      'Treść zawiera niedozwolone lub obraźliwe słowa. Zmień ją i spróbuj ponownie.',
    );

    controller.dispose();
  });
}
