import 'package:flutter_test/flutter_test.dart';
import 'package:shopmaps/cloud/cloud_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
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
}
