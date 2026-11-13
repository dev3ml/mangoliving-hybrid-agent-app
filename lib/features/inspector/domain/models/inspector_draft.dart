const Object _unset = Object();

enum BusinessType {
  independent('Independent inspector', 'Work on your own as a solo inspector'),
  company('Inspection company', 'Represent an inspection company with a team.');

  const BusinessType(this.label, this.detail);
  final String label;
  final String detail;
}

enum HomeType {
  singleFamily('Single-family'),
  townhouse('Townhouse'),
  condo('Condo'),
  duplex('Duplex');

  const HomeType(this.label);
  final String label;
}

enum YearBuiltGroup {
  before1965('Before 1965'),
  from1965('1965 or later');

  const YearBuiltGroup(this.label);
  final String label;
}

enum PricingMethod { fixed, requestQuote }

enum BookingPreference {
  approveEach(
    'Approve each request',
    'Review the home, price, and time before accepting.',
  ),
  instant(
    'Allow instant bookings',
    'Requires a connected calendar.',
  );

  const BookingPreference(this.label, this.detail);
  final String label;
  final String detail;
}

enum ApplicationStatus { draft, underReview, live }

enum InspectorStep {
  join,
  business,
  qualifications,
  coverage,
  scopeStructure,
  scopeInterior,
  scopeSystems,
  scopeAppliances,
  pricingTypes,
  pricingBefore1965,
  pricingFrom1965,
  pricingSummary,
  addonsPest,
  addonsFoundation,
  addonsMold,
  quote,
  availability,
  review,
  submitted,
}

class ScopeItem {
  const ScopeItem({
    required this.id,
    required this.label,
    this.section,
  });

  final String id;
  final String label;
  final String? section;
}

class ScopeGroup {
  const ScopeGroup({
    required this.id,
    required this.title,
    required this.footnote,
    required this.items,
  });

  final String id;
  final String title;
  final String footnote;
  final List<ScopeItem> items;
}

class RateBand {
  const RateBand({
    required this.id,
    required this.label,
    required this.minSqFt,
    required this.maxSqFt,
    required this.method,
    this.priceUsd,
    this.hintPrice,
  });

  final String id;
  final String label;
  final int? minSqFt;
  final int? maxSqFt;
  final PricingMethod method;
  final int? priceUsd;
  final int? hintPrice;

  bool get isPriced =>
      method == PricingMethod.requestQuote || priceUsd != null;

  RateBand copyWith({
    String? id,
    String? label,
    PricingMethod? method,
    Object? priceUsd = _unset,
    Object? minSqFt = _unset,
    Object? maxSqFt = _unset,
    Object? hintPrice = _unset,
  }) {
    return RateBand(
      id: id ?? this.id,
      label: label ?? this.label,
      minSqFt: minSqFt == _unset ? this.minSqFt : minSqFt as int?,
      maxSqFt: maxSqFt == _unset ? this.maxSqFt : maxSqFt as int?,
      method: method ?? this.method,
      priceUsd: priceUsd == _unset ? this.priceUsd : priceUsd as int?,
      hintPrice: hintPrice == _unset ? this.hintPrice : hintPrice as int?,
    );
  }
}

class HomeRateCard {
  const HomeRateCard({
    required this.before1965,
    required this.from1965,
    required this.beforeSaved,
    required this.fromSaved,
  });

  final List<RateBand> before1965;
  final List<RateBand> from1965;
  final bool beforeSaved;
  final bool fromSaved;

  bool get isComplete => beforeSaved && fromSaved;

  List<RateBand> bandsFor(YearBuiltGroup group) {
    return group == YearBuiltGroup.before1965 ? before1965 : from1965;
  }

  HomeRateCard copyWith({
    List<RateBand>? before1965,
    List<RateBand>? from1965,
    bool? beforeSaved,
    bool? fromSaved,
  }) {
    return HomeRateCard(
      before1965: before1965 ?? this.before1965,
      from1965: from1965 ?? this.from1965,
      beforeSaved: beforeSaved ?? this.beforeSaved,
      fromSaved: fromSaved ?? this.fromSaved,
    );
  }

  HomeRateCard replace(
    YearBuiltGroup group,
    List<RateBand> bands, {
    bool? saved,
  }) {
    if (group == YearBuiltGroup.before1965) {
      return copyWith(before1965: bands, beforeSaved: saved ?? beforeSaved);
    }
    return copyWith(from1965: bands, fromSaved: saved ?? fromSaved);
  }
}

class AddOnOffer {
  const AddOnOffer({
    required this.id,
    required this.name,
    required this.summary,
    required this.scopeText,
    required this.accessText,
    required this.hintPrice,
    this.hintMinutes,
    this.enabled = true,
    this.method = PricingMethod.fixed,
    this.priceUsd,
    this.additionalMinutes,
  });

  final String id;
  final String name;
  final String summary;
  final String scopeText;
  final String accessText;
  final int hintPrice;
  final int? hintMinutes;
  final bool enabled;
  final PricingMethod method;
  final int? priceUsd;
  final int? additionalMinutes;

  AddOnOffer copyWith({
    String? name,
    String? summary,
    String? scopeText,
    String? accessText,
    bool? enabled,
    PricingMethod? method,
    Object? priceUsd = _unset,
    Object? additionalMinutes = _unset,
  }) {
    return AddOnOffer(
      id: id,
      name: name ?? this.name,
      summary: summary ?? this.summary,
      scopeText: scopeText ?? this.scopeText,
      accessText: accessText ?? this.accessText,
      hintPrice: hintPrice,
      hintMinutes: hintMinutes,
      enabled: enabled ?? this.enabled,
      method: method ?? this.method,
      priceUsd: priceUsd == _unset ? this.priceUsd : priceUsd as int?,
      additionalMinutes: additionalMinutes == _unset
          ? this.additionalMinutes
          : additionalMinutes as int?,
    );
  }
}

class InspectorDraft {
  const InspectorDraft({
    required this.step,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.password,
    required this.acceptedTerms,
    required this.businessType,
    required this.businessName,
    required this.yearsOfExperience,
    required this.bio,
    required this.licensingState,
    required this.licenseNumber,
    required this.coreCategoryIds,
    required this.serviceAreas,
    required this.homeTypes,
    required this.includedScopeIds,
    required this.rateCards,
    required this.activeHomeType,
    required this.addOns,
    required this.availableDays,
    required this.startTime,
    required this.endTime,
    required this.minimumNotice,
    required this.bookingPreference,
    required this.calendarConnected,
    required this.previewHomeType,
    required this.previewYear,
    required this.previewSqFt,
    required this.previewAddOnIds,
    required this.confirmedAccurate,
    required this.status,
    this.editingAddOnId,
    this.photoFileName,
    this.photoPath,
    this.licenseFileName,
    this.insuranceFileName,
    this.sampleReportFileName,
    this.returnTo,
    this.returnAnchor,
    this.submittedAt,
  });

  final InspectorStep step;
  final String? editingAddOnId;
  final String fullName;
  final String email;
  final String mobile;
  final String password;
  final bool acceptedTerms;
  final BusinessType businessType;
  final String businessName;
  final String yearsOfExperience;
  final String bio;
  final String? photoFileName;
  /// Local file chosen in onboarding. Uploaded when the inspector is created.
  final String? photoPath;
  final String licensingState;
  final String licenseNumber;
  final String? licenseFileName;
  final String? insuranceFileName;
  final String? sampleReportFileName;
  final Set<String> coreCategoryIds;
  final List<String> serviceAreas;
  final Set<HomeType> homeTypes;
  final Set<String> includedScopeIds;
  final Map<HomeType, HomeRateCard> rateCards;
  final HomeType activeHomeType;
  final List<AddOnOffer> addOns;
  final Set<int> availableDays;
  final String startTime;
  final String endTime;
  final String minimumNotice;
  final BookingPreference bookingPreference;
  final bool calendarConnected;
  final HomeType previewHomeType;
  final String previewYear;
  final String previewSqFt;
  final Set<String> previewAddOnIds;
  final bool confirmedAccurate;
  final ApplicationStatus status;
  final InspectorStep? returnTo;
  final InspectorStep? returnAnchor;
  final DateTime? submittedAt;

  List<HomeType> get selectedHomeTypes {
    return HomeType.values.where(homeTypes.contains).toList();
  }

  HomeRateCard cardFor(HomeType type) {
    return rateCards[type] ??
        const HomeRateCard(
          before1965: <RateBand>[],
          from1965: <RateBand>[],
          beforeSaved: false,
          fromSaved: false,
        );
  }

  bool get pricingComplete {
    final List<HomeType> selected = selectedHomeTypes;
    if (selected.isEmpty) return false;
    return selected.every((HomeType type) => cardFor(type).isComplete);
  }

  int get enabledAddOnCount =>
      addOns.where((AddOnOffer addOn) => addOn.enabled).length;

  AddOnOffer? addOnById(String id) {
    for (final AddOnOffer addOn in addOns) {
      if (addOn.id == id) return addOn;
    }
    return null;
  }

  InspectorDraft updateCard(HomeType type, HomeRateCard card) {
    return copyWith(rateCards: <HomeType, HomeRateCard>{...rateCards, type: card});
  }

  InspectorDraft updateAddOn(String id, AddOnOffer addOn) {
    return copyWith(
      addOns: <AddOnOffer>[
        for (final AddOnOffer current in addOns)
          if (current.id == id) addOn else current,
      ],
    );
  }

  InspectorDraft copyWith({
    InspectorStep? step,
    bool clearEditingAddOn = false,
    String? editingAddOnId,
    String? fullName,
    String? email,
    String? mobile,
    String? password,
    bool? acceptedTerms,
    BusinessType? businessType,
    String? businessName,
    String? yearsOfExperience,
    String? bio,
    Object? photoFileName = _unset,
    Object? photoPath = _unset,
    String? licensingState,
    String? licenseNumber,
    Object? licenseFileName = _unset,
    Object? insuranceFileName = _unset,
    Object? sampleReportFileName = _unset,
    Set<String>? coreCategoryIds,
    List<String>? serviceAreas,
    Set<HomeType>? homeTypes,
    Set<String>? includedScopeIds,
    Map<HomeType, HomeRateCard>? rateCards,
    HomeType? activeHomeType,
    List<AddOnOffer>? addOns,
    Set<int>? availableDays,
    String? startTime,
    String? endTime,
    String? minimumNotice,
    BookingPreference? bookingPreference,
    bool? calendarConnected,
    HomeType? previewHomeType,
    String? previewYear,
    String? previewSqFt,
    Set<String>? previewAddOnIds,
    bool? confirmedAccurate,
    ApplicationStatus? status,
    bool clearReturnTo = false,
    InspectorStep? returnTo,
    InspectorStep? returnAnchor,
    Object? submittedAt = _unset,
  }) {
    return InspectorDraft(
      step: step ?? this.step,
      editingAddOnId:
          clearEditingAddOn ? null : (editingAddOnId ?? this.editingAddOnId),
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      password: password ?? this.password,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      businessType: businessType ?? this.businessType,
      businessName: businessName ?? this.businessName,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      bio: bio ?? this.bio,
      photoFileName:
          photoFileName == _unset ? this.photoFileName : photoFileName as String?,
      photoPath: photoPath == _unset ? this.photoPath : photoPath as String?,
      licensingState: licensingState ?? this.licensingState,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseFileName: licenseFileName == _unset
          ? this.licenseFileName
          : licenseFileName as String?,
      insuranceFileName: insuranceFileName == _unset
          ? this.insuranceFileName
          : insuranceFileName as String?,
      sampleReportFileName: sampleReportFileName == _unset
          ? this.sampleReportFileName
          : sampleReportFileName as String?,
      coreCategoryIds: coreCategoryIds ?? this.coreCategoryIds,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      homeTypes: homeTypes ?? this.homeTypes,
      includedScopeIds: includedScopeIds ?? this.includedScopeIds,
      rateCards: rateCards ?? this.rateCards,
      activeHomeType: activeHomeType ?? this.activeHomeType,
      addOns: addOns ?? this.addOns,
      availableDays: availableDays ?? this.availableDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      minimumNotice: minimumNotice ?? this.minimumNotice,
      bookingPreference: bookingPreference ?? this.bookingPreference,
      calendarConnected: calendarConnected ?? this.calendarConnected,
      previewHomeType: previewHomeType ?? this.previewHomeType,
      previewYear: previewYear ?? this.previewYear,
      previewSqFt: previewSqFt ?? this.previewSqFt,
      previewAddOnIds: previewAddOnIds ?? this.previewAddOnIds,
      confirmedAccurate: confirmedAccurate ?? this.confirmedAccurate,
      status: status ?? this.status,
      returnTo: clearReturnTo ? null : (returnTo ?? this.returnTo),
      returnAnchor: clearReturnTo ? null : (returnAnchor ?? this.returnAnchor),
      submittedAt:
          submittedAt == _unset ? this.submittedAt : submittedAt as DateTime?,
    );
  }
}
