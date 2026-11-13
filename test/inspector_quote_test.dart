import 'package:flutter_test/flutter_test.dart';
import 'package:mangoliving_agent/features/inspector/domain/inspector_quote.dart';
import 'package:mangoliving_agent/features/inspector/domain/models/inspector_draft.dart';

void main() {
  test('1998 single-family at 2,800 sq ft totals 700 with two add-ons', () {
    final InspectorQuote quote = matchInspectionQuote(
      yearBuilt: 1998,
      sqFt: 2800,
      before1965: const <RateBand>[
        RateBand(
          id: 'before',
          label: '2,501–3,500',
          minSqFt: 2501,
          maxSqFt: 3500,
          method: PricingMethod.fixed,
          priceUsd: 500,
        ),
      ],
      from1965: const <RateBand>[
        RateBand(
          id: 'later',
          label: '2,501–3,500',
          minSqFt: 2501,
          maxSqFt: 3500,
          method: PricingMethod.fixed,
          priceUsd: 450,
        ),
      ],
      addOns: const <QuoteAddOnInput>[
        QuoteAddOnInput(
          name: 'Sewer scope',
          method: PricingMethod.fixed,
          priceUsd: 175,
        ),
        QuoteAddOnInput(
          name: 'Infrared thermal scan',
          method: PricingMethod.fixed,
          priceUsd: 75,
        ),
      ],
    );

    expect(quote.ready, isTrue);
    expect(quote.requestQuote, isFalse);
    expect(quote.yearGroup, YearBuiltGroup.from1965);
    expect(quote.bandLabel, '2,501–3,500');
    expect(quote.basePrice, 450);
    expect(quote.subtotal, 700);
  });

  test('a matched band with no dollar price is a request quote', () {
    final InspectorQuote quote = matchInspectionQuote(
      yearBuilt: 1998,
      sqFt: 5000,
      before1965: const <RateBand>[],
      from1965: const <RateBand>[
        RateBand(
          id: 'above',
          label: 'Above 4,500',
          minSqFt: 4501,
          maxSqFt: null,
          method: PricingMethod.requestQuote,
        ),
      ],
      addOns: const <QuoteAddOnInput>[],
    );

    expect(quote.ready, isTrue);
    expect(quote.requestQuote, isTrue);
    expect(quote.basePrice, isNull);
    expect(quote.subtotal, isNull);
    expect(quote.bandLabel, 'Above 4,500');
  });

  test('1964 uses the earlier year group', () {
    final InspectorQuote quote = matchInspectionQuote(
      yearBuilt: 1964,
      sqFt: 2800,
      before1965: const <RateBand>[
        RateBand(
          id: 'before',
          label: '2,501–3,500',
          minSqFt: 2501,
          maxSqFt: 3500,
          method: PricingMethod.fixed,
          priceUsd: 500,
        ),
      ],
      from1965: const <RateBand>[
        RateBand(
          id: 'later',
          label: '2,501–3,500',
          minSqFt: 2501,
          maxSqFt: 3500,
          method: PricingMethod.fixed,
          priceUsd: 450,
        ),
      ],
      addOns: const <QuoteAddOnInput>[],
    );

    expect(quote.yearGroup, YearBuiltGroup.before1965);
    expect(quote.basePrice, 500);
    expect(quote.subtotal, 500);
  });
}
