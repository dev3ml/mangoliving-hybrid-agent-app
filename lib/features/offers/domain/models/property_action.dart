import 'package:intl/intl.dart';

import '../../../../core/constants/env_config.dart';

enum OfferBoardState { visited, offerPlaced, offerAccepted }

enum OfferStatus { draft, sent, accepted, rejected, countered }

enum OfferPdfKind { branded, attached }

extension OfferBoardStateX on OfferBoardState {
  String get apiValue => switch (this) {
        OfferBoardState.visited => 'visited',
        OfferBoardState.offerPlaced => 'offer_placed',
        OfferBoardState.offerAccepted => 'offer_accepted',
      };

  String get label => switch (this) {
        OfferBoardState.visited => 'Visited',
        OfferBoardState.offerPlaced => 'Offer Placed',
        OfferBoardState.offerAccepted => 'Offer Accepted',
      };

  static OfferBoardState? tryParse(String? raw) {
    return switch (raw) {
      'visited' => OfferBoardState.visited,
      'offer_placed' => OfferBoardState.offerPlaced,
      'offer_accepted' => OfferBoardState.offerAccepted,
      _ => null,
    };
  }
}

extension OfferStatusX on OfferStatus {
  String get label => switch (this) {
        OfferStatus.draft => 'Draft',
        OfferStatus.sent => 'Sent',
        OfferStatus.accepted => 'Accepted',
        OfferStatus.rejected => 'Rejected',
        OfferStatus.countered => 'Countered',
      };

  static OfferStatus? tryParse(String? raw) {
    for (final OfferStatus status in OfferStatus.values) {
      if (status.name == raw) return status;
    }
    return null;
  }
}

final class OfferPdfDocument {
  const OfferPdfDocument({
    this.buyerName,
    this.preparedByName,
    this.streetAddress,
    this.city,
    this.province,
    this.postalCode,
    this.offerAmount,
    this.listPrice,
    this.inspectionPeriodDays,
    this.inspectionText,
    this.notes,
    this.closingText,
    this.effectiveDate,
  });

  final String? buyerName;
  final String? preparedByName;
  final String? streetAddress;
  final String? city;
  final String? province;
  final String? postalCode;
  final num? offerAmount;
  final num? listPrice;
  final num? inspectionPeriodDays;
  final String? inspectionText;
  final String? notes;
  final String? closingText;
  final String? effectiveDate;

  factory OfferPdfDocument.fromJson(Map<String, dynamic> json) {
    return OfferPdfDocument(
      buyerName: json['buyerName'] as String?,
      preparedByName: json['preparedByName'] as String?,
      streetAddress: json['streetAddress'] as String?,
      city: json['city'] as String?,
      province: json['province'] as String?,
      postalCode: json['postalCode'] as String?,
      offerAmount: json['offerAmount'] as num?,
      listPrice: json['listPrice'] as num?,
      inspectionPeriodDays: json['inspectionPeriodDays'] as num?,
      inspectionText: json['inspectionText'] as String?,
      notes: json['notes'] as String?,
      closingText: json['closingText'] as String?,
      effectiveDate: json['effectiveDate'] as String?,
    );
  }
}

final class OfferDetails {
  const OfferDetails({
    this.offerCreatedAt,
    this.offerSentAt,
    this.offerStatus,
    this.listPrice,
    this.offerAmount,
    this.inspectionPeriodDays,
    this.notes,
    this.preparedById,
    this.preparedByName,
    this.documentUrl,
    this.documentName,
    this.brandedPdfUrl,
    this.pdfDocument,
  });

  final String? offerCreatedAt;
  final String? offerSentAt;
  final OfferStatus? offerStatus;
  final num? listPrice;
  final num? offerAmount;
  final num? inspectionPeriodDays;
  final String? notes;
  final String? preparedById;
  final String? preparedByName;
  final String? documentUrl;
  final String? documentName;
  final String? brandedPdfUrl;
  final OfferPdfDocument? pdfDocument;

  bool get isRejected => offerStatus == OfferStatus.rejected;
  bool get isAccepted => offerStatus == OfferStatus.accepted;

  String? get brandedResolvedUrl =>
      OfferPdfUrl.resolve(brandedPdfUrl, cacheBust: offerSentAt);
  String? get attachedResolvedUrl =>
      OfferPdfUrl.resolve(documentUrl, cacheBust: documentName);

  factory OfferDetails.fromJson(Map<String, dynamic> json) {
    final dynamic pdf = json['pdfDocument'];
    return OfferDetails(
      offerCreatedAt: json['offerCreatedAt'] as String?,
      offerSentAt: json['offerSentAt'] as String?,
      offerStatus: OfferStatusX.tryParse(json['offerStatus'] as String?),
      listPrice: json['listPrice'] as num?,
      offerAmount: json['offerAmount'] as num?,
      inspectionPeriodDays: json['inspectionPeriodDays'] as num?,
      notes: json['notes'] as String?,
      preparedById: json['preparedById'] as String?,
      preparedByName: json['preparedByName'] as String?,
      documentUrl: json['documentUrl'] as String?,
      documentName: json['documentName'] as String?,
      brandedPdfUrl: json['brandedPdfUrl'] as String?,
      pdfDocument: pdf is Map<String, dynamic>
          ? OfferPdfDocument.fromJson(pdf)
          : null,
    );
  }
}

final class OfferProperty {
  const OfferProperty({
    this.streetAddress,
    this.city,
    this.province,
    this.postalCode,
    this.listPrice,
    this.firstImageURL,
    this.listingPath,
  });

  final String? streetAddress;
  final String? city;
  final String? province;
  final String? postalCode;
  final num? listPrice;
  final String? firstImageURL;
  final String? listingPath;

  factory OfferProperty.fromJson(Map<String, dynamic> json) {
    return OfferProperty(
      streetAddress: json['streetAddress'] as String?,
      city: json['city'] as String?,
      province: json['province'] as String?,
      postalCode: json['postalCode'] as String?,
      listPrice: (json['ListPrice'] ?? json['listPrice']) as num?,
      firstImageURL: json['firstImageURL'] as String?,
      listingPath: json['listingPath'] as String?,
    );
  }
}

final class OfferBuyer {
  const OfferBuyer({this.id, this.firstName, this.lastName, this.email});

  final String? id;
  final String? firstName;
  final String? lastName;
  final String? email;

  String get displayName {
    final String name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (name.isNotEmpty) return name;
    if ((email ?? '').trim().isNotEmpty) return email!.trim();
    return '—';
  }

  factory OfferBuyer.fromJson(Map<String, dynamic> json) {
    return OfferBuyer(
      id: json['id']?.toString(),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
    );
  }
}

final class PropertyAction {
  const PropertyAction({
    required this.id,
    required this.buyerId,
    required this.propertyId,
    required this.currentState,
    this.agentId,
    this.agentName,
    this.property,
    this.offer,
    this.buyer,
    this.updatedAt,
  });

  final String id;
  final String buyerId;
  final String propertyId;
  final String currentState;
  final String? agentId;
  final String? agentName;
  final OfferProperty? property;
  final OfferDetails? offer;
  final OfferBuyer? buyer;
  final String? updatedAt;

  OfferBoardState? get boardState => OfferBoardStateX.tryParse(currentState);

  String get buyerName => buyer?.displayName ?? '—';

  String get streetLine {
    final String raw = (property?.streetAddress ?? '').split(';').first.trim();
    if (raw.isNotEmpty) return raw;
    if (propertyId.trim().isNotEmpty) return propertyId;
    return 'Listing';
  }

  String get cityLine => (property?.city ?? '').trim();

  bool get isRejected => offer?.isRejected == true;

  String get stageLabel => isRejected ? 'Offer rejected' : (boardState?.label ?? currentState);

  String get amountLabel => OfferMoney.format(offer?.offerAmount);

  String get sentLabel => OfferMoney.formatSent(offer?.offerSentAt);

  bool get canPrepare => boardState == OfferBoardState.visited;

  bool get canUpdate =>
      boardState == OfferBoardState.offerPlaced && !isRejected;

  bool get canSendAgain =>
      boardState == OfferBoardState.offerPlaced && isRejected;

  bool get canView =>
      (boardState == OfferBoardState.offerPlaced && !isRejected) ||
      boardState == OfferBoardState.offerAccepted;

  bool get canEditPdf =>
      boardState != OfferBoardState.offerAccepted && offer?.isAccepted != true;

  bool get canMarkDecision =>
      boardState == OfferBoardState.offerPlaced && !isRejected;

  factory PropertyAction.fromJson(Map<String, dynamic> json) {
    final dynamic property = json['property'];
    final dynamic offer = json['offer'];
    final dynamic buyer = json['buyer'];
    return PropertyAction(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      buyerId: (json['buyerId'] ?? '').toString(),
      propertyId: (json['propertyId'] ?? '').toString(),
      currentState: (json['currentState'] ?? '').toString(),
      agentId: json['agentId']?.toString(),
      agentName: json['agentName'] as String?,
      property: property is Map<String, dynamic>
          ? OfferProperty.fromJson(property)
          : null,
      offer: offer is Map<String, dynamic> ? OfferDetails.fromJson(offer) : null,
      buyer: buyer is Map<String, dynamic> ? OfferBuyer.fromJson(buyer) : null,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

final class OfferCounts {
  const OfferCounts({
    required this.total,
    required this.visited,
    required this.offerPlaced,
    required this.offerAccepted,
  });

  final int total;
  final int visited;
  final int offerPlaced;
  final int offerAccepted;

  factory OfferCounts.from(List<PropertyAction> rows) {
    int visited = 0;
    int placed = 0;
    int accepted = 0;
    for (final PropertyAction row in rows) {
      switch (row.boardState) {
        case OfferBoardState.visited:
          visited += 1;
        case OfferBoardState.offerPlaced:
          placed += 1;
        case OfferBoardState.offerAccepted:
          accepted += 1;
        case null:
          break;
      }
    }
    return OfferCounts(
      total: rows.length,
      visited: visited,
      offerPlaced: placed,
      offerAccepted: accepted,
    );
  }
}

final class OfferPdfForm {
  const OfferPdfForm({
    required this.buyerName,
    required this.preparedByName,
    required this.streetAddress,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.offerAmount,
    required this.listPrice,
    required this.inspectionPeriodDays,
    required this.inspectionText,
    required this.notes,
    required this.closingText,
    required this.effectiveDate,
  });

  final String buyerName;
  final String preparedByName;
  final String streetAddress;
  final String city;
  final String province;
  final String postalCode;
  final String offerAmount;
  final String listPrice;
  final String inspectionPeriodDays;
  final String inspectionText;
  final String notes;
  final String closingText;
  final String effectiveDate;

  static const String defaultClosingText =
      'Closing date and remaining items will be confirmed with the buyer and agent.';

  static String defaultInspectionText([Object days = 7]) {
    final Object value = days.toString().trim().isEmpty ? 7 : days;
    return 'This offer includes a $value-day inspection period unless the parties agree otherwise.';
  }

  factory OfferPdfForm.empty() {
    return OfferPdfForm(
      buyerName: '',
      preparedByName: '',
      streetAddress: '',
      city: '',
      province: '',
      postalCode: '',
      offerAmount: '',
      listPrice: '',
      inspectionPeriodDays: '7',
      inspectionText: defaultInspectionText(7),
      notes: '',
      closingText: defaultClosingText,
      effectiveDate: '',
    );
  }

  factory OfferPdfForm.fromRow(PropertyAction row) {
    final OfferPdfDocument? pdf = row.offer?.pdfDocument;
    final Object days =
        pdf?.inspectionPeriodDays ?? row.offer?.inspectionPeriodDays ?? 7;
    return OfferPdfForm(
      buyerName: (pdf?.buyerName ?? '').trim().isNotEmpty
          ? pdf!.buyerName!.trim()
          : row.buyerName == '—'
              ? ''
              : row.buyerName,
      preparedByName: (pdf?.preparedByName ??
              row.offer?.preparedByName ??
              row.agentName ??
              '')
          .trim(),
      streetAddress: ((pdf?.streetAddress ?? row.property?.streetAddress) ?? '')
          .split(';')
          .first
          .trim(),
      city: pdf?.city ?? row.property?.city ?? '',
      province: pdf?.province ?? row.property?.province ?? '',
      postalCode: pdf?.postalCode ?? row.property?.postalCode ?? '',
      offerAmount: '${pdf?.offerAmount ?? row.offer?.offerAmount ?? ''}',
      listPrice:
          '${pdf?.listPrice ?? row.offer?.listPrice ?? row.property?.listPrice ?? ''}',
      inspectionPeriodDays: '$days',
      inspectionText: (pdf?.inspectionText ?? '').trim().isNotEmpty
          ? pdf!.inspectionText!
          : defaultInspectionText(days),
      notes: pdf?.notes ?? row.offer?.notes ?? '',
      closingText: (pdf?.closingText ?? '').trim().isNotEmpty
          ? pdf!.closingText!
          : defaultClosingText,
      effectiveDate: _dateInput(pdf?.effectiveDate ?? row.offer?.offerSentAt),
    );
  }

  String? get amountError {
    final num? value = num.tryParse(offerAmount.trim());
    if (value == null || !value.isFinite || value <= 0) {
      return 'Enter a valid offer amount.';
    }
    return null;
  }

  String? get daysError {
    final num? value = num.tryParse(inspectionPeriodDays.trim());
    if (value == null || !value.isFinite || value < 1) {
      return 'Inspection period must be at least 1 day.';
    }
    return null;
  }

  OfferPdfForm copyWith({
    String? buyerName,
    String? preparedByName,
    String? streetAddress,
    String? city,
    String? province,
    String? postalCode,
    String? offerAmount,
    String? listPrice,
    String? inspectionPeriodDays,
    String? inspectionText,
    String? notes,
    String? closingText,
    String? effectiveDate,
  }) {
    return OfferPdfForm(
      buyerName: buyerName ?? this.buyerName,
      preparedByName: preparedByName ?? this.preparedByName,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      offerAmount: offerAmount ?? this.offerAmount,
      listPrice: listPrice ?? this.listPrice,
      inspectionPeriodDays: inspectionPeriodDays ?? this.inspectionPeriodDays,
      inspectionText: inspectionText ?? this.inspectionText,
      notes: notes ?? this.notes,
      closingText: closingText ?? this.closingText,
      effectiveDate: effectiveDate ?? this.effectiveDate,
    );
  }

  OfferPdfForm withInspectionDays(String days) {
    final String previousDefault = defaultInspectionText(inspectionPeriodDays);
    final bool rewrite =
        inspectionText.trim().isEmpty || inspectionText == previousDefault;
    return copyWith(
      inspectionPeriodDays: days,
      inspectionText: rewrite ? defaultInspectionText(days) : inspectionText,
    );
  }

  Map<String, dynamic> toWriteBody() {
    final Map<String, dynamic> body = <String, dynamic>{
      'offerAmount': num.parse(offerAmount.trim()),
      'inspectionPeriodDays': num.parse(inspectionPeriodDays.trim()),
    };
    final String? list = listPrice.trim().isEmpty ? null : listPrice.trim();
    if (list != null) body['listPrice'] = num.parse(list);
    void put(String key, String value) {
      if (value.trim().isNotEmpty) body[key] = value.trim();
    }

    put('notes', notes);
    put('buyerName', buyerName);
    put('preparedByName', preparedByName);
    put('streetAddress', streetAddress);
    put('city', city);
    put('province', province);
    put('postalCode', postalCode);
    put('inspectionText', inspectionText);
    put('closingText', closingText);
    put('effectiveDate', effectiveDate);
    return body;
  }

  static String _dateInput(String? value) {
    if (value == null || value.isEmpty) return '';
    final DateTime? date = DateTime.tryParse(value);
    if (date == null) return '';
    return date.toIso8601String().sliceDate;
  }
}

abstract final class OfferMoney {
  static final NumberFormat _usd = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 0,
  );

  static String format(num? value) {
    if (value == null || !value.isFinite) return '—';
    return _usd.format(value);
  }

  static String formatSent(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final DateTime? date = DateTime.tryParse(iso);
    if (date == null) return '—';
    return DateFormat('MMM d, y, h:mm a').format(date.toLocal());
  }
}

abstract final class OfferPdfUrl {
  static String? resolve(String? storedUrl, {Object? cacheBust}) {
    if (storedUrl == null || storedUrl.trim().isEmpty) return null;
    final String fileName = storedUrl.split('/').last.split('?').first;
    if (!fileName.toLowerCase().endsWith('.pdf')) return storedUrl;
    final String base = EnvConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    final String href = '$base/uploads/offers/$fileName';
    if (cacheBust == null || cacheBust.toString().isEmpty) return href;
    return '$href?t=${Uri.encodeComponent(cacheBust.toString())}';
  }
}

extension on String {
  String get sliceDate => length >= 10 ? substring(0, 10) : this;
}
