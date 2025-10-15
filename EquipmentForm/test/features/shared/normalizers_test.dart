import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/features/shared/domain/device_kind.dart';
import 'package:equipment_form_app/features/shared/domain/normalizers.dart';
import 'package:equipment_form_app/features/shared/domain/validation.dart';

void main() {
  group('Asset tag parsing', () {
    test('normalizes valid asset tag', () {
      expect(normalizeAssetTag('acc-lt-12345'), 'ACC-LT-12345');
      expect(normalizeAssetTag('TAK - mb - 99999'), 'TAK-MB-99999');
    });

    test('returns null for invalid asset tag', () {
      expect(normalizeAssetTag('XYZ-123'), isNull);
      expect(normalizeAssetTag('ACC-LT-1A345'), isNull);
    });
  });

  group('IMEI normalization', () {
    test('strips non digits and validates length', () {
      expect(normalizeImei(' 35 209900 176148 7 '), '352099001761487');
    });

    test('validation enforces 15 digits', () {
      expect(validateImei('12345'), 'IMEI must contain 15 digits');
      expect(validateImei('352099001761487'), isNull);
    });
  });

  group('Warranty expiry normalization', () {
    test('accepts multiple input formats', () {
      expect(normalizeWarrantyExpiry('01/02/2026'), '2026-02-01');
      expect(normalizeWarrantyExpiry('2026-02-01'), '2026-02-01');
      expect(normalizeWarrantyExpiry('invalid'), isNull);
    });
  });

  group('Dell Latitude model normalization', () {
    test('strips dell latitude prefix and uppercases remainder', () {
      expect(normalizeDellLatitudeModel('Dell Latitude 7440'), '7440');
      expect(normalizeDellLatitudeModel('latitude 5430'), '5430');
      expect(normalizeDellLatitudeModel('Dell LATITUDE 7320 2-in-1'),
          '7320 2-IN-1');
    });

    test('handles empty and null', () {
      expect(normalizeDellLatitudeModel(null), isNull);
      expect(normalizeDellLatitudeModel('   '), '');
      expect(normalizeDellLatitudeModel('iPhone 14 Pro'), 'iPhone 14 Pro');
    });
  });

  group('Equipment validation', () {
    test('requires asset/service for laptops', () {
      final errors = validateEquipmentFields(
        deviceKind: DeviceKind.laptop,
        makeModel: 'Dell',
        assetTag: 'ACC-LT-12345',
        serviceTag: '',
        serial: null,
        imei: null,
        warrantyExpiry: null,
      );
      expect(errors.map((e) => e.field), contains('serviceTag'));
    });

    test('requires imei for phones', () {
      final errors = validateEquipmentFields(
        deviceKind: DeviceKind.phone,
        makeModel: 'iPhone',
        assetTag: 'TAK-MB-54321',
        serviceTag: null,
        serial: '',
        imei: '123',
        warrantyExpiry: null,
      );
      final fields = errors.map((e) => e.field).toList();
      expect(fields, contains('imei'));
      expect(fields, isNot(contains('serial')));
    });
  });
}
