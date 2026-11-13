import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/inspector_quote.dart';
import '../../domain/models/inspector_draft.dart';
import '../controllers/inspector_flow_controller.dart';
import '../widgets/inspector_chrome.dart';

class AddOnListStep extends ConsumerWidget {
  const AddOnListStep({super.key, required this.pageIndex});

  final int pageIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InspectorDraft draft =
        ref.watch(inspectorFlowControllerProvider).requireValue;
    final int start = pageIndex * 3;
    final List<AddOnOffer> page = draft.addOns.skip(start).take(3).toList();
    final bool last = pageIndex == 2;

    return InspectorStepScaffold(
      step: pageIndex + 1,
      total: 4,
      title: 'Optional add-ons',
      subtitle: 'Services ${start + 1}–${start + page.length} of ${draft.addOns.length}',
      actionLabel: last ? 'Review add-on settings' : 'Continue',
      onAction: () {
        final InspectorStep next = switch (pageIndex) {
          0 => InspectorStep.addonsFoundation,
          1 => InspectorStep.addonsMold,
          _ => InspectorStep.quote,
        };
        ref.read(inspectorFlowControllerProvider.notifier).go(next);
      },
      children: <Widget>[
        const Text('Turn off any service you do not offer.'),
        const SizedBox(height: 12),
        for (final AddOnOffer addOn in page)
          _AddOnCard(
            addOn: addOn,
            onToggle: (bool enabled) {
              ref.read(inspectorFlowControllerProvider.notifier).patch(
                    (InspectorDraft current) {
                      final AddOnOffer? latest = current.addOnById(addOn.id);
                      if (latest == null) return current;
                      final Set<String> selected = <String>{...current.previewAddOnIds};
                      if (!enabled) selected.remove(addOn.id);
                      return current
                          .updateAddOn(addOn.id, latest.copyWith(enabled: enabled))
                          .copyWith(previewAddOnIds: selected);
                    },
                  );
            },
            onPrice: (String raw) {
              final int? price = parseWholeNumber(raw);
              ref.read(inspectorFlowControllerProvider.notifier).patch(
                    (InspectorDraft current) {
                      final AddOnOffer? latest = current.addOnById(addOn.id);
                      if (latest == null) return current;
                      return current.updateAddOn(
                        addOn.id,
                        latest.copyWith(
                          method: PricingMethod.fixed,
                          priceUsd: raw.trim().isEmpty ? null : price,
                        ),
                      );
                    },
                  );
            },
            onOpen: () {
              ref.read(inspectorFlowControllerProvider.notifier).patch(
                    (InspectorDraft current) =>
                        current.copyWith(editingAddOnId: addOn.id),
                  );
            },
          ),
        const InspectorNote(
          text: 'None of these nine services are included in the base rate.',
        ),
      ],
    );
  }
}

class _AddOnCard extends StatefulWidget {
  const _AddOnCard({
    required this.addOn,
    required this.onToggle,
    required this.onPrice,
    required this.onOpen,
  });

  final AddOnOffer addOn;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onPrice;
  final VoidCallback onOpen;

  @override
  State<_AddOnCard> createState() => _AddOnCardState();
}

class _AddOnCardState extends State<_AddOnCard> {
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(text: widget.addOn.priceUsd?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _AddOnCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String next = widget.addOn.priceUsd?.toString() ?? '';
    if (widget.addOn.method == PricingMethod.requestQuote && _price.text.isNotEmpty) {
      _price.clear();
    } else if (_price.text != next && next.isNotEmpty && _price.text.isEmpty) {
      _price.text = next;
    }
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final InspectorPalette palette = InspectorPalette.of(context);
    final AddOnOffer addOn = widget.addOn;
    final bool request = addOn.method == PricingMethod.requestQuote;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: InkWell(
                  onTap: widget.onOpen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Separate add-on',
                        style: TextStyle(
                          color: Color(0xFFF97316),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        addOn.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: palette.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Switch(
                value: addOn.enabled,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFFF97316),
                onChanged: widget.onToggle,
              ),
            ],
          ),
          Text(addOn.summary, style: TextStyle(color: palette.muted)),
          const SizedBox(height: 10),
          if (request)
            const Text(
              'Request a quote',
              style: TextStyle(fontWeight: FontWeight.w700),
            )
          else
            TextField(
              controller: _price,
              enabled: addOn.enabled,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: widget.onPrice,
              decoration: InputDecoration(
                labelText: 'Price per inspection (USD)',
                hintText: addOn.hintPrice.toString(),
                isDense: true,
              ),
            ),
        ],
      ),
    );
  }
}

class AddOnSettingsStep extends ConsumerStatefulWidget {
  const AddOnSettingsStep({super.key, required this.addOnId});

  final String addOnId;

  @override
  ConsumerState<AddOnSettingsStep> createState() => _AddOnSettingsStepState();
}

class _AddOnSettingsStepState extends ConsumerState<AddOnSettingsStep> {
  late AddOnOffer _draft;
  late final TextEditingController _price;
  late final TextEditingController _minutes;
  late final TextEditingController _scope;
  late final TextEditingController _access;
  String? _error;

  @override
  void initState() {
    super.initState();
    final InspectorDraft draft =
        ref.read(inspectorFlowControllerProvider).requireValue;
    _draft = draft.addOnById(widget.addOnId) ?? draft.addOns.first;
    _price = TextEditingController(text: _draft.priceUsd?.toString() ?? '');
    _minutes = TextEditingController(
      text: _draft.additionalMinutes?.toString() ?? '',
    );
    _scope = TextEditingController(text: _draft.scopeText);
    _access = TextEditingController(text: _draft.accessText);
  }

  @override
  void dispose() {
    _price.dispose();
    _minutes.dispose();
    _scope.dispose();
    _access.dispose();
    super.dispose();
  }

  void _save() {
    if (_draft.enabled &&
        _draft.method == PricingMethod.fixed &&
        parseWholeNumber(_price.text) == null) {
      setState(() => _error = 'Enter a fixed price or choose Request a quote.');
      return;
    }
    final AddOnOffer next = _draft.copyWith(
      priceUsd: _draft.method == PricingMethod.requestQuote
          ? null
          : parseWholeNumber(_price.text),
      additionalMinutes: parseWholeNumber(_minutes.text),
      scopeText: _scope.text.trim().isEmpty ? _draft.scopeText : _scope.text.trim(),
      accessText: _access.text.trim().isEmpty ? _draft.accessText : _access.text.trim(),
    );
    ref.read(inspectorFlowControllerProvider.notifier).patch(
          (InspectorDraft current) {
            final Set<String> selected = <String>{...current.previewAddOnIds};
            if (!next.enabled) selected.remove(next.id);
            return current
                .updateAddOn(next.id, next)
                .copyWith(
                  previewAddOnIds: selected,
                  step: InspectorStep.quote,
                  clearEditingAddOn: true,
                );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final InspectorPalette palette = InspectorPalette.of(context);
    return InspectorStepScaffold(
      step: 4,
      total: 4,
      title: '${_draft.name} settings',
      error: _error,
      actionLabel: 'Save & preview quote',
      onAction: _save,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.orangeSoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                'Optional add-on',
                style: TextStyle(
                  color: Color(0xFFF97316),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Offer this service'),
          subtitle: const Text('Show this add-on to buyers.'),
          value: _draft.enabled,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFFF97316),
          onChanged: (bool value) => setState(() {
            _draft = _draft.copyWith(enabled: value);
          }),
        ),
        Text(
          'Pricing method',
          style: TextStyle(fontWeight: FontWeight.w800, color: palette.ink),
        ),
        const SizedBox(height: 8),
        InspectorChoiceCard(
          title: 'Fixed add-on fee',
          detail: 'Set a price for each inspection.',
          selected: _draft.method == PricingMethod.fixed,
          onTap: () => setState(() {
            _draft = _draft.copyWith(method: PricingMethod.fixed);
          }),
        ),
        InspectorChoiceCard(
          title: 'Request a quote',
          detail: 'Buyers will request a custom price.',
          selected: _draft.method == PricingMethod.requestQuote,
          onTap: () => setState(() {
            _draft = _draft.copyWith(method: PricingMethod.requestQuote);
          }),
        ),
        if (_draft.method == PricingMethod.fixed)
          InspectorField(
            label: 'Price per inspection (USD)',
            controller: _price,
            hint: _draft.hintPrice.toString(),
            keyboardType: TextInputType.number,
          ),
        InspectorField(
          label: 'Additional time',
          controller: _minutes,
          hint: _draft.hintMinutes?.toString() ?? '0',
          helper: 'Minutes added when a buyer selects this service.',
          keyboardType: TextInputType.number,
        ),
        InspectorField(
          label: 'Scope shown to buyers',
          controller: _scope,
          maxLines: 3,
        ),
        InspectorField(
          label: 'Access requirements',
          controller: _access,
          maxLines: 3,
        ),
        const InspectorNote(
          text: 'Charged once, only when selected by the buyer.',
        ),
      ],
    );
  }
}
