enum DeviceKind {
  laptop,
  phone,
  tablet,
  desktop,
  other,
}

extension DeviceKindDisplay on DeviceKind {
  String get label {
    switch (this) {
      case DeviceKind.laptop:
        return 'Laptop';
      case DeviceKind.phone:
        return 'Phone';
      case DeviceKind.tablet:
        return 'Tablet';
      case DeviceKind.desktop:
        return 'Desktop';
      case DeviceKind.other:
        return 'Other';
    }
  }
}
