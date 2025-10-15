import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/core/equipment_model/vendor_map.dart';

void main() {
  group('vendor map', () {
    test('canonical family lookup resolves aliases', () {
      expect(canonicalFamilyForToken('lat'), 'Latitude');
      expect(canonicalFamilyForToken('LATITUDE'), 'Latitude');
      expect(canonicalFamilyForToken('think'), 'ThinkPad');
      expect(canonicalFamilyForToken('xps'), 'XPS');
      expect(canonicalFamilyForToken('unknown'), isNull);
    });

    test('vendor inference via tokens', () {
      expect(inferVendorFromTokens(['dell', 'latitude']), 'Dell');
      expect(inferVendorFromTokens(['lenovo', 'thinkpad']), 'Lenovo');
      expect(inferVendorFromTokens(['hp', 'probook']), 'HP');
      expect(inferVendorFromTokens(['unknown']), isNull);
    });

    test('vendor fallback via family', () {
      expect(vendorForFamily('Latitude'), 'Dell');
      expect(vendorForFamily('ThinkPad'), 'Lenovo');
      expect(vendorForFamily('ProBook'), 'HP');
      expect(vendorForFamily('Other'), isNull);
    });

    test('unknown vendor constant', () {
      expect(unknownVendor, 'Unknown');
    });
  });
}
