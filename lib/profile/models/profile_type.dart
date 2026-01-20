enum ProfileType {
  normal,
  expert,
  entrepreneur,
  investor;

  /// Convert API string → enum
  static ProfileType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'expert':
        return ProfileType.expert;
      case 'entrepreneur':
        return ProfileType.entrepreneur;
      case 'investor':
        return ProfileType.investor;
      case 'normal':
      default:
        return ProfileType.normal;
    }
  }
}
