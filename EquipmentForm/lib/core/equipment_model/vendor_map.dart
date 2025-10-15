const Map<String, String> _vendorTokens = {
  'dell': 'Dell',
  'lenovo': 'Lenovo',
  'hp': 'HP',
  'hewlett': 'HP',
};

const Map<String, String> _familyCanonical = {
  'lat': 'Latitude',
  'latitude': 'Latitude',
  'precision': 'Precision',
  'xps': 'XPS',
  'thinkpad': 'ThinkPad',
  'think': 'ThinkPad',
  'ideapad': 'IdeaPad',
  'elitebook': 'EliteBook',
  'elite': 'EliteBook',
  'probook': 'ProBook',
};

const Map<String, String> _familyToVendor = {
  'Latitude': 'Dell',
  'Precision': 'Dell',
  'XPS': 'Dell',
  'ThinkPad': 'Lenovo',
  'IdeaPad': 'Lenovo',
  'EliteBook': 'HP',
  'ProBook': 'HP',
};

String? canonicalFamilyForToken(String token) {
  final lower = token.toLowerCase();
  return _familyCanonical[lower];
}

String? inferVendorFromTokens(List<String> tokens) {
  for (final token in tokens) {
    final lower = token.toLowerCase();
    final vendor = _vendorTokens[lower];
    if (vendor != null) {
      return vendor;
    }
  }
  return null;
}

String? vendorForFamily(String? family) {
  if (family == null) return null;
  return _familyToVendor[family];
}

String get unknownVendor => 'Unknown';

Iterable<String> get supportedFamilies => _familyToVendor.keys;
