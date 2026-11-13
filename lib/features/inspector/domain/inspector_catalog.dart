import 'models/inspector_draft.dart';

const int inspectorYearSplit = 1965;

const List<String> usStates = <String>[
  'Alabama',
  'Alaska',
  'Arizona',
  'Arkansas',
  'California',
  'Colorado',
  'Connecticut',
  'Delaware',
  'Florida',
  'Georgia',
  'Hawaii',
  'Idaho',
  'Illinois',
  'Indiana',
  'Iowa',
  'Kansas',
  'Kentucky',
  'Louisiana',
  'Maine',
  'Maryland',
  'Massachusetts',
  'Michigan',
  'Minnesota',
  'Mississippi',
  'Missouri',
  'Montana',
  'Nebraska',
  'Nevada',
  'New Hampshire',
  'New Jersey',
  'New Mexico',
  'New York',
  'North Carolina',
  'North Dakota',
  'Ohio',
  'Oklahoma',
  'Oregon',
  'Pennsylvania',
  'Rhode Island',
  'South Carolina',
  'South Dakota',
  'Tennessee',
  'Texas',
  'Utah',
  'Vermont',
  'Virginia',
  'Washington',
  'West Virginia',
  'Wisconsin',
  'Wyoming',
];

const List<String> experienceOptions = <String>[
  'Less than 1 year',
  '1 year',
  '2 years',
  '3 years',
  '4 years',
  '5 years',
  '6 years',
  '7 years',
  '8 years',
  '9 years',
  '10 years',
  '15 years',
  '20+ years',
];

const List<String> inspectionTimes = <String>[
  '6:00 AM',
  '7:00 AM',
  '8:00 AM',
  '9:00 AM',
  '10:00 AM',
  '11:00 AM',
  '12:00 PM',
  '1:00 PM',
  '2:00 PM',
  '3:00 PM',
  '4:00 PM',
  '5:00 PM',
  '6:00 PM',
  '7:00 PM',
  '8:00 PM',
];

const List<String> noticeOptions = <String>[
  'Same day',
  '12 hours',
  '24 hours',
  '48 hours',
  '72 hours',
];

const List<({String id, String label})> coreCategories =
    <({String id, String label})>[
  (id: 'structure', label: 'Structure'),
  (id: 'roof', label: 'Roof'),
  (id: 'electrical', label: 'Electrical'),
  (id: 'plumbing', label: 'Plumbing'),
  (id: 'hvac', label: 'HVAC'),
  (id: 'appliances', label: 'Appliances'),
];

const List<ScopeGroup> scopeGroups = <ScopeGroup>[
  ScopeGroup(
    id: 'structure',
    title: 'Structure & exterior',
    footnote: 'Foundation elevation measurements are a separate add-on.',
    items: <ScopeItem>[
      ScopeItem(id: 'foundation', label: 'Foundation'),
      ScopeItem(id: 'grading', label: 'Grading and Drainage'),
      ScopeItem(id: 'roof-covering', label: 'Roof Covering'),
      ScopeItem(id: 'roof-attic', label: 'Roof and Attic Structure'),
      ScopeItem(id: 'exterior-walls', label: 'Exterior Walls'),
      ScopeItem(id: 'porches', label: 'Porches'),
      ScopeItem(id: 'balconies', label: 'Balconies'),
      ScopeItem(id: 'decks', label: 'Decks'),
      ScopeItem(id: 'fence', label: 'Fence'),
    ],
  ),
  ScopeGroup(
    id: 'interior',
    title: 'Interior & insulation',
    footnote: 'Infrared thermal scanning is a separate add-on.',
    items: <ScopeItem>[
      ScopeItem(id: 'interior-walls', label: 'Interior Walls'),
      ScopeItem(id: 'ceilings', label: 'Ceilings'),
      ScopeItem(id: 'floors', label: 'Floors'),
      ScopeItem(id: 'doors', label: 'Doors'),
      ScopeItem(id: 'windows', label: 'Windows'),
      ScopeItem(id: 'stairways', label: 'Stairways'),
      ScopeItem(id: 'fireplace', label: 'Fireplace and Chimney'),
      ScopeItem(id: 'insulation', label: 'Insulation'),
    ],
  ),
  ScopeGroup(
    id: 'systems',
    title: 'Home systems',
    footnote: 'Sewer scope and septic inspection are separate add-ons.',
    items: <ScopeItem>[
      ScopeItem(id: 'electrical-panel', label: 'Electrical Panel', section: 'ELECTRICAL'),
      ScopeItem(id: 'branch-circuits', label: 'Branch Circuits', section: 'ELECTRICAL'),
      ScopeItem(id: 'heating', label: 'Heating Equipment', section: 'HEATING & COOLING'),
      ScopeItem(id: 'cooling', label: 'Cooling Equipment', section: 'HEATING & COOLING'),
      ScopeItem(id: 'ducts', label: 'Ducts and Vents', section: 'HEATING & COOLING'),
      ScopeItem(id: 'plumbing', label: 'Plumbing', section: 'PLUMBING'),
      ScopeItem(id: 'water-heater', label: 'Water Heater', section: 'PLUMBING'),
    ],
  ),
  ScopeGroup(
    id: 'appliances',
    title: 'Appliances & equipment',
    footnote: 'Items inspected where present and accessible.',
    items: <ScopeItem>[
      ScopeItem(id: 'dishwasher', label: 'Dishwasher'),
      ScopeItem(id: 'disposer', label: 'Food Waste Disposer'),
      ScopeItem(id: 'range-hood', label: 'Range Hood and Exhaust Systems'),
      ScopeItem(id: 'cooktops', label: 'Cooktops/Ovens'),
      ScopeItem(id: 'dryer-vents', label: 'Dryer Vents'),
      ScopeItem(id: 'garage-door', label: 'Garage Door Operator'),
    ],
  ),
];

int get scopeItemCount =>
    scopeGroups.fold(0, (int sum, ScopeGroup group) => sum + group.items.length);

Set<String> initialScopeIds() {
  return <String>{
    for (final ScopeGroup group in scopeGroups)
      for (final ScopeItem item in group.items) item.id,
  };
}

List<RateBand> defaultBands(YearBuiltGroup group) {
  final List<int?> hints = group == YearBuiltGroup.before1965
      ? <int?>[400, 450, 500, 575, null]
      : <int?>[350, 400, 450, 525, null];
  return <RateBand>[
    RateBand(
      id: 'up-to-1500',
      label: 'Up to 1,500',
      minSqFt: null,
      maxSqFt: 1500,
      method: PricingMethod.fixed,
      hintPrice: hints[0],
    ),
    RateBand(
      id: '1501-2500',
      label: '1,501–2,500',
      minSqFt: 1501,
      maxSqFt: 2500,
      method: PricingMethod.fixed,
      hintPrice: hints[1],
    ),
    RateBand(
      id: '2501-3500',
      label: '2,501–3,500',
      minSqFt: 2501,
      maxSqFt: 3500,
      method: PricingMethod.fixed,
      hintPrice: hints[2],
    ),
    RateBand(
      id: '3501-4500',
      label: '3,501–4,500',
      minSqFt: 3501,
      maxSqFt: 4500,
      method: PricingMethod.fixed,
      hintPrice: hints[3],
    ),
    RateBand(
      id: 'above-4500',
      label: 'Above 4,500',
      minSqFt: 4501,
      maxSqFt: null,
      method: PricingMethod.requestQuote,
      hintPrice: hints[4],
    ),
  ];
}

List<AddOnOffer> initialAddOns() {
  return const <AddOnOffer>[
    AddOnOffer(
      id: 'termite',
      name: 'Termite / WDI report',
      summary: 'Termites and other wood-destroying insects.',
      scopeText: 'Wood-destroying insect inspection and report.',
      accessText: 'Accessible interior and exterior. Confirm access before booking.',
      hintPrice: 100,
    ),
    AddOnOffer(
      id: 'sewer',
      name: 'Sewer scope',
      summary: 'Camera check of the main sewer line.',
      scopeText: 'Camera check of the main sewer line.',
      accessText: 'Accessible cleanout required. Confirm access before booking.',
      hintPrice: 175,
      hintMinutes: 45,
    ),
    AddOnOffer(
      id: 'pool',
      name: 'Pool and spa',
      summary: 'Equipment, surfaces and safety.',
      scopeText: 'Equipment, surfaces and safety.',
      accessText: 'Gate and equipment access required.',
      hintPrice: 125,
    ),
    AddOnOffer(
      id: 'foundation-elevation',
      name: 'Foundation elevation survey',
      summary: 'Measures how level the slab is.',
      scopeText: 'Measures how level the slab is.',
      accessText: 'Clear access around the slab. Confirm access before booking.',
      hintPrice: 150,
    ),
    AddOnOffer(
      id: 'thermal',
      name: 'Infrared thermal scan',
      summary: 'Screens for moisture and heat-loss patterns.',
      scopeText: 'Screens for moisture and heat-loss patterns.',
      accessText: 'Interior access required. Utilities should be on.',
      hintPrice: 75,
    ),
    AddOnOffer(
      id: 'radon',
      name: 'Radon test',
      summary: 'Measures radon gas levels in the air.',
      scopeText: 'Measures radon gas levels in the air.',
      accessText: 'Closed-house conditions. Confirm access before booking.',
      hintPrice: 150,
    ),
    AddOnOffer(
      id: 'mold',
      name: 'Mold assessment',
      summary: 'Visible mold review and air samples.',
      scopeText: 'Visible mold review and air samples.',
      accessText: 'Access to the areas of concern. Confirm before booking.',
      hintPrice: 250,
    ),
    AddOnOffer(
      id: 'sprinkler',
      name: 'Sprinkler system',
      summary: 'Zones, heads and controller.',
      scopeText: 'Zones, heads and controller.',
      accessText: 'Controller access required.',
      hintPrice: 75,
    ),
    AddOnOffer(
      id: 'septic',
      name: 'Septic inspection',
      summary: 'Tank and drain field.',
      scopeText: 'Tank and drain field.',
      accessText: 'Accessible tank lids required. Confirm access before booking.',
      hintPrice: 250,
    ),
  ];
}

String bandLabelFor({int? minSqFt, int? maxSqFt}) {
  if (minSqFt == null && maxSqFt != null) return 'Up to ${_grouped(maxSqFt)}';
  if (minSqFt != null && maxSqFt == null) {
    final int above = minSqFt > 0 ? minSqFt - 1 : minSqFt;
    return 'Above ${_grouped(above)}';
  }
  if (minSqFt != null && maxSqFt != null) {
    return '${_grouped(minSqFt)}–${_grouped(maxSqFt)}';
  }
  return 'Custom band';
}

InspectorDraft newInspectorDraft() {
  return InspectorDraft(
    step: InspectorStep.join,
    fullName: '',
    email: '',
    mobile: '',
    password: '',
    acceptedTerms: false,
    businessType: BusinessType.independent,
    businessName: '',
    yearsOfExperience: '',
    bio: '',
    licensingState: '',
    licenseNumber: '',
    coreCategoryIds: <String>{
      for (final ({String id, String label}) category in coreCategories)
        category.id,
    },
    serviceAreas: const <String>[],
    homeTypes: const <HomeType>{
      HomeType.singleFamily,
      HomeType.townhouse,
      HomeType.condo,
    },
    includedScopeIds: initialScopeIds(),
    rateCards: <HomeType, HomeRateCard>{
      for (final HomeType type in HomeType.values)
        type: HomeRateCard(
          before1965: defaultBands(YearBuiltGroup.before1965),
          from1965: defaultBands(YearBuiltGroup.from1965),
          beforeSaved: false,
          fromSaved: false,
        ),
    },
    activeHomeType: HomeType.singleFamily,
    addOns: initialAddOns(),
    availableDays: const <int>{0, 1, 2, 3, 4},
    startTime: '8:00 AM',
    endTime: '5:00 PM',
    minimumNotice: '24 hours',
    bookingPreference: BookingPreference.approveEach,
    calendarConnected: false,
    previewHomeType: HomeType.singleFamily,
    previewYear: '',
    previewSqFt: '',
    previewAddOnIds: const <String>{},
    confirmedAccurate: false,
    status: ApplicationStatus.draft,
  );
}

String _grouped(int value) {
  final String digits = value.toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}
