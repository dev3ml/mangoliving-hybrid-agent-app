import 'inspector_catalog.dart';
import 'models/inspector_draft.dart';

class QuoteAddOnInput {
  const QuoteAddOnInput({
    required this.name,
    required this.method,
    this.priceUsd,
  });

  final String name;
  final PricingMethod method;
  final int? priceUsd;
}

class QuoteLine {
  const QuoteLine({
    required this.name,
    required this.requestQuote,
    this.priceUsd,
  });

  final String name;
  final bool requestQuote;
  final int? priceUsd;
}

class InspectorQuote {
  const InspectorQuote({
    required this.ready,
    required this.requestQuote,
    required this.addOns,
    this.yearGroup,
    this.bandLabel,
    this.basePrice,
    this.subtotal,
  });

  const InspectorQuote.notReady()
      : ready = false,
        requestQuote = false,
        addOns = const <QuoteLine>[],
        yearGroup = null,
        bandLabel = null,
        basePrice = null,
        subtotal = null;

  final bool ready;
  final bool requestQuote;
  final YearBuiltGroup? yearGroup;
  final String? bandLabel;
  final int? basePrice;
  final List<QuoteLine> addOns;
  final int? subtotal;
}

/// Matches a buyer quote from home type rates already chosen for the year.
///
/// Homes built before [inspectorYearSplit] use the earlier card. 1965 and
/// every later year use the second card. A band with no dollar price, or an
/// explicit request-quote band, becomes "Request quote" instead of a total.
InspectorQuote matchInspectionQuote({
  required int yearBuilt,
  required int sqFt,
  required List<RateBand> before1965,
  required List<RateBand> from1965,
  required List<QuoteAddOnInput> addOns,
}) {
  if (yearBuilt < 1800 || yearBuilt > 2100 || sqFt <= 0) {
    return const InspectorQuote.notReady();
  }

  final YearBuiltGroup group = yearBuilt < inspectorYearSplit
      ? YearBuiltGroup.before1965
      : YearBuiltGroup.from1965;
  final List<RateBand> bands =
      group == YearBuiltGroup.before1965 ? before1965 : from1965;
  final RateBand? band = _matchBand(bands, sqFt);
  final List<QuoteLine> lines = <QuoteLine>[
    for (final QuoteAddOnInput addOn in addOns)
      QuoteLine(
        name: addOn.name,
        requestQuote:
            addOn.method == PricingMethod.requestQuote || addOn.priceUsd == null,
        priceUsd: addOn.method == PricingMethod.requestQuote ? null : addOn.priceUsd,
      ),
  ];

  if (band == null ||
      band.method == PricingMethod.requestQuote ||
      band.priceUsd == null) {
    return InspectorQuote(
      ready: true,
      requestQuote: true,
      yearGroup: group,
      bandLabel: band?.label,
      addOns: lines,
    );
  }

  final int basePrice = band.priceUsd!;
  final bool addOnNeedsQuote = lines.any((QuoteLine line) => line.requestQuote);
  final int subtotal = basePrice +
      lines.fold(0, (int sum, QuoteLine line) => sum + (line.priceUsd ?? 0));

  return InspectorQuote(
    ready: true,
    requestQuote: addOnNeedsQuote,
    yearGroup: group,
    bandLabel: band.label,
    basePrice: basePrice,
    addOns: lines,
    subtotal: addOnNeedsQuote ? null : subtotal,
  );
}

RateBand? _matchBand(List<RateBand> bands, int sqFt) {
  for (final RateBand band in bands) {
    final int minSqFt = band.minSqFt ?? 0;
    final int maxSqFt = band.maxSqFt ?? 1 << 30;
    if (sqFt >= minSqFt && sqFt <= maxSqFt) return band;
  }
  return null;
}

String formatUsd(int amount) {
  final String digits = amount.abs().toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return amount < 0 ? '-\$${out.toString()}' : '\$${out.toString()}';
}

int? parseWholeNumber(String raw) {
  final String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}
