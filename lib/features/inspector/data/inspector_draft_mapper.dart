import '../domain/models/inspector_draft.dart';

/// Maps the mobile onboarding draft to `POST /v1/inspection-provider/live-onboard`.
abstract final class InspectorDraftMapper {
  static Map<String, dynamic> toLiveOnboardJson(InspectorDraft draft) {
    return <String, dynamic>{
      'fullName': draft.fullName.trim(),
      'email': draft.email.trim(),
      'mobile': draft.mobile.trim(),
      'password': draft.password,
      'businessName': draft.businessName.trim(),
      'businessType': draft.businessType.name,
      'yearsOfExperience': draft.yearsOfExperience,
      'bio': draft.bio.trim(),
      'licensingState': draft.licensingState,
      'licenseNumber': draft.licenseNumber.trim(),
      'licenseFileName': draft.licenseFileName,
      'insuranceFileName': draft.insuranceFileName,
      'sampleReportFileName': draft.sampleReportFileName,
      'serviceAreas': draft.serviceAreas,
      'homeTypes': draft.homeTypes.map((HomeType type) => type.name).toList(),
      'includedScopeIds': draft.includedScopeIds.toList(),
      'coreCategoryIds': draft.coreCategoryIds.toList(),
      'rateCards': <String, dynamic>{
        for (final MapEntry<HomeType, HomeRateCard> entry in draft.rateCards.entries)
          entry.key.name: <String, dynamic>{
            'from1965': _bands(entry.value.from1965),
            'before1965': _bands(entry.value.before1965),
          },
      },
      'addOns': <Map<String, dynamic>>[
        for (final AddOnOffer addOn in draft.addOns)
          <String, dynamic>{
            'id': addOn.id,
            'name': addOn.name,
            'enabled': addOn.enabled,
            'method': addOn.method.name,
            'priceUsd': addOn.priceUsd,
            'additionalMinutes': addOn.additionalMinutes,
          },
      ],
      'availableDays': draft.availableDays.toList(),
      'startTime': draft.startTime,
      'endTime': draft.endTime,
      'minimumNotice': draft.minimumNotice,
      'bookingPreference': draft.bookingPreference.name,
      'acceptedTerms': draft.acceptedTerms,
      'confirmedAccurate': draft.confirmedAccurate,
    };
  }

  static List<Map<String, dynamic>> _bands(List<RateBand> bands) {
    return <Map<String, dynamic>>[
      for (final RateBand band in bands)
        <String, dynamic>{
          'id': band.id,
          'label': band.label,
          'minSqFt': band.minSqFt,
          'maxSqFt': band.maxSqFt,
          'method': band.method.name,
          'priceUsd': band.priceUsd,
        },
    ];
  }
}
