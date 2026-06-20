/// The seller's own business details. [homeState] is the place of supply for
/// your GST registration; comparing it to the buyer's state decides whether a
/// sale is intra-state (CGST + SGST) or inter-state (IGST).
class BusinessProfile {
  final String businessName;
  final String gstin;
  final String homeState;
  final double defaultGstRate;

  const BusinessProfile({
    this.businessName = '',
    this.gstin = '',
    this.homeState = '',
    this.defaultGstRate = 18,
  });

  bool get isConfigured => homeState.isNotEmpty;

  /// Whether a sale to [buyerState] is inter-state given this profile.
  /// Falls back to [fallback] when either state is unknown.
  bool isInterStateFor(String? buyerState, {bool fallback = false}) {
    if (homeState.isEmpty || buyerState == null || buyerState.isEmpty) {
      return fallback;
    }
    return buyerState.trim().toLowerCase() != homeState.trim().toLowerCase();
  }

  Map<String, String> toMap() => {
        'businessName': businessName,
        'gstin': gstin,
        'homeState': homeState,
        'defaultGstRate': defaultGstRate.toString(),
      };

  factory BusinessProfile.fromMap(Map<String, String> map) {
    return BusinessProfile(
      businessName: map['businessName'] ?? '',
      gstin: map['gstin'] ?? '',
      homeState: map['homeState'] ?? '',
      defaultGstRate: double.tryParse(map['defaultGstRate'] ?? '') ?? 18,
    );
  }

  BusinessProfile copyWith({
    String? businessName,
    String? gstin,
    String? homeState,
    double? defaultGstRate,
  }) {
    return BusinessProfile(
      businessName: businessName ?? this.businessName,
      gstin: gstin ?? this.gstin,
      homeState: homeState ?? this.homeState,
      defaultGstRate: defaultGstRate ?? this.defaultGstRate,
    );
  }
}
