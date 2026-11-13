import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/inspector_catalog.dart';
import '../../domain/inspector_quote.dart';
import '../../domain/models/inspector_draft.dart';
import '../controllers/inspector_flow_controller.dart';
import '../widgets/inspector_chrome.dart';

class PricingTypesStep extends ConsumerWidget {
  const PricingTypesStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InspectorDraft draft = ref
        .watch(inspectorFlowControllerProvider)
        .requireValue;
    final List<HomeType> types = draft.selectedHomeTypes;
    final HomeType? next = types.cast<HomeType?>().firstWhere(
      (HomeType? type) => type != null && !draft.cardFor(type).isComplete,
      orElse: () => null,
    );
    final InspectorPalette palette = InspectorPalette.of(context);
    final int included = draft.includedScopeIds.length;

    return InspectorStepScaffold(
      step: 1,
      total: 4,
      title: 'Base inspection pricing',
      subtitle: 'Add-ons are priced separately in the next step.',
      actionLabel: next == null
          ? 'Review rate cards'
          : 'Price ${next.label.toLowerCase()}',
      onAction: () {
        final InspectorFlowController notifier = ref.read(
          inspectorFlowControllerProvider.notifier,
        );
        if (next == null) {
          notifier.go(InspectorStep.pricingSummary);
          return;
        }
        notifier.patch(
          (InspectorDraft current) => current.copyWith(
            activeHomeType: next,
            step: InspectorStep.pricingBefore1965,
          ),
        );
      },
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.orangeSoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                '$included-item base scope confirmed',
                style: const TextStyle(
                  color: Color(0xFFF97316),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final HomeType type in types)
          _HomeTypeCard(
            type: type,
            card: draft.cardFor(type),
            emphasize: type == next,
            onOpen: () {
              ref
                  .read(inspectorFlowControllerProvider.notifier)
                  .patch(
                    (InspectorDraft current) => current.copyWith(
                      activeHomeType: type,
                      step: InspectorStep.pricingBefore1965,
                    ),
                  );
            },
          ),
        const SizedBox(height: 8),
        Text(
          'Your three pricing factors',
          style: TextStyle(fontWeight: FontWeight.w800, color: palette.ink),
        ),
        const SizedBox(height: 8),
        const Row(
          children: <Widget>[
            Expanded(
              child: _Factor(icon: Icons.house_outlined, label: 'Home type'),
            ),
            Expanded(
              child: _Factor(
                icon: Icons.calendar_today_outlined,
                label: 'Year built',
              ),
            ),
            Expanded(
              child: _Factor(icon: Icons.straighten, label: 'Home size'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _YearCallout(
          title: 'Before 1965',
          detail: 'Homes built in 1964 or earlier.',
        ),
        const SizedBox(height: 8),
        const _YearCallout(
          title: '1965 or later',
          detail: 'Includes homes built in 1965.',
        ),
      ],
    );
  }
}

class PricingYearStep extends ConsumerStatefulWidget {
  const PricingYearStep({super.key, required this.from1965});

  final bool from1965;

  @override
  ConsumerState<PricingYearStep> createState() => _PricingYearStepState();
}

class _PricingYearStepState extends ConsumerState<PricingYearStep> {
  final Map<String, TextEditingController> _prices =
      <String, TextEditingController>{};
  String? _error;

  YearBuiltGroup get _group =>
      widget.from1965 ? YearBuiltGroup.from1965 : YearBuiltGroup.before1965;

  @override
  void dispose() {
    for (final TextEditingController controller in _prices.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _ensureControllers(List<RateBand> bands) {
    for (final RateBand band in bands) {
      _prices.putIfAbsent(band.id, () {
        final int? shown =
            band.priceUsd ??
            (band.method == PricingMethod.fixed ? band.hintPrice : null);
        return TextEditingController(text: shown?.toString() ?? '');
      });
    }
  }

  RateBand _resolvedBand(RateBand band) {
    if (band.method == PricingMethod.requestQuote) return band;
    final String typed = _prices[band.id]?.text.trim() ?? '';
    final int? typedPrice = typed.isEmpty ? null : parseWholeNumber(typed);
    if (typedPrice != null) {
      return band.copyWith(method: PricingMethod.fixed, priceUsd: typedPrice);
    }
    if (band.priceUsd != null) return band;
    if (band.hintPrice != null) {
      return band.copyWith(priceUsd: band.hintPrice);
    }
    return band;
  }

  List<RateBand> _resolvedBands(List<RateBand> bands) {
    return <RateBand>[for (final RateBand band in bands) _resolvedBand(band)];
  }

  void _openYear(InspectorStep step) {
    ref.read(inspectorFlowControllerProvider.notifier).patch((
      InspectorDraft current,
    ) {
      final HomeRateCard card = current.cardFor(current.activeHomeType);
      final List<RateBand> bands = _resolvedBands(card.bandsFor(_group));
      HomeRateCard next = card.replace(_group, bands);
      if (bands.every((RateBand band) => band.isPriced)) {
        next = widget.from1965
            ? next.copyWith(fromSaved: true)
            : next.copyWith(beforeSaved: true);
      }
      return current
          .updateCard(current.activeHomeType, next)
          .copyWith(step: step);
    });
  }

  void _setMethod(RateBand band, PricingMethod method) {
    ref.read(inspectorFlowControllerProvider.notifier).patch((
      InspectorDraft current,
    ) {
      final HomeRateCard card = current.cardFor(current.activeHomeType);
      final List<RateBand> bands = <RateBand>[...card.bandsFor(_group)];
      final int index = bands.indexWhere((RateBand item) => item.id == band.id);
      if (index < 0) return current;
      bands[index] = band.copyWith(
        method: method,
        priceUsd: method == PricingMethod.requestQuote ? null : band.priceUsd,
      );
      return current.updateCard(
        current.activeHomeType,
        card.replace(_group, bands, saved: false),
      );
    });
  }

  void _setPrice(RateBand band, String raw) {
    final int? price = parseWholeNumber(raw);
    ref.read(inspectorFlowControllerProvider.notifier).patch((
      InspectorDraft current,
    ) {
      final HomeRateCard card = current.cardFor(current.activeHomeType);
      final List<RateBand> bands = <RateBand>[...card.bandsFor(_group)];
      final int index = bands.indexWhere((RateBand item) => item.id == band.id);
      if (index < 0) return current;
      bands[index] = bands[index].copyWith(
        method: PricingMethod.fixed,
        priceUsd: raw.trim().isEmpty ? null : price,
      );
      return current.updateCard(
        current.activeHomeType,
        card.replace(_group, bands, saved: false),
      );
    });
  }

  Future<void> _addBand() async {
    final ({int? minSqFt, int? maxSqFt})? added =
        await showDialog<({int? minSqFt, int? maxSqFt})>(
          context: context,
          builder: (BuildContext context) => const _AddBandDialog(),
        );
    final int? minSqFt = added?.minSqFt;
    final int? maxSqFt = added?.maxSqFt;
    if (added == null || (minSqFt == null && maxSqFt == null)) return;
    ref.read(inspectorFlowControllerProvider.notifier).patch((
      InspectorDraft current,
    ) {
      final HomeRateCard card = current.cardFor(current.activeHomeType);
      final List<RateBand> bands =
          <RateBand>[
            ...card.bandsFor(_group),
            RateBand(
              id: 'band-${DateTime.now().microsecondsSinceEpoch}',
              label: bandLabelFor(minSqFt: minSqFt, maxSqFt: maxSqFt),
              minSqFt: minSqFt,
              maxSqFt: maxSqFt,
              method: PricingMethod.fixed,
            ),
          ]..sort((RateBand a, RateBand b) {
            return (a.minSqFt ?? -1).compareTo(b.minSqFt ?? -1);
          });
      return current.updateCard(
        current.activeHomeType,
        card.replace(_group, bands, saved: false),
      );
    });
  }

  void _save() {
    final InspectorDraft? draft = ref
        .read(inspectorFlowControllerProvider)
        .valueOrNull;
    if (draft == null) return;
    final List<RateBand> bands = _resolvedBands(
      draft.cardFor(draft.activeHomeType).bandsFor(_group),
    );
    if (bands.any((RateBand band) => !band.isPriced)) {
      setState(() {
        _error = 'Enter a price or choose Request quote for every size band.';
      });
      return;
    }
    final InspectorFlowController notifier = ref.read(
      inspectorFlowControllerProvider.notifier,
    );
    notifier.patch((InspectorDraft current) {
      final HomeRateCard card = current.cardFor(current.activeHomeType);
      final List<RateBand> resolved = _resolvedBands(card.bandsFor(_group));
      if (!widget.from1965) {
        return current
            .updateCard(
              current.activeHomeType,
              card.replace(_group, resolved).copyWith(beforeSaved: true),
            )
            .copyWith(step: InspectorStep.pricingFrom1965);
      }
      final HomeRateCard priced = card.replace(_group, resolved);
      final bool beforeReady = priced.before1965.every(
        (RateBand band) => band.isPriced,
      );
      final InspectorDraft saved = current.updateCard(
        current.activeHomeType,
        priced.copyWith(
          fromSaved: true,
          beforeSaved: priced.beforeSaved || beforeReady,
        ),
      );
      return saved.copyWith(
        step: saved.pricingComplete
            ? InspectorStep.pricingSummary
            : InspectorStep.pricingTypes,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final InspectorDraft draft = ref
        .watch(inspectorFlowControllerProvider)
        .requireValue;
    final HomeType type = draft.selectedHomeTypes.contains(draft.activeHomeType)
        ? draft.activeHomeType
        : draft.selectedHomeTypes.first;
    final List<HomeType> types = draft.selectedHomeTypes;
    final int typeIndex = types.indexOf(type);
    final List<RateBand> bands = draft.cardFor(type).bandsFor(_group);
    _ensureControllers(bands);
    final InspectorPalette palette = InspectorPalette.of(context);

    return InspectorStepScaffold(
      step: widget.from1965 ? 3 : 2,
      total: 4,
      title: '${type.label} base rates',
      subtitle: 'Full price for the base scope.',
      error: _error,
      actionLabel: widget.from1965
          ? 'Save ${type.label.toLowerCase()} rates'
          : 'Next: 1965 or later',
      onAction: _save,
      children: <Widget>[
        Text(
          'Home type ${typeIndex + 1} of ${types.length}',
          style: const TextStyle(
            color: Color(0xFFF97316),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _YearSwitch(
          from1965: widget.from1965,
          onBefore: () {
            if (!widget.from1965) return;
            _openYear(InspectorStep.pricingBefore1965);
          },
          onAfter: () {
            if (widget.from1965) return;
            _openYear(InspectorStep.pricingFrom1965);
          },
        ),
        const SizedBox(height: 14),
        Text(
          'Enter the full base inspection price by home size.',
          style: TextStyle(color: palette.muted),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Home size (sq. ft.)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: palette.muted,
                ),
              ),
            ),
            SizedBox(
              width: 150,
              child: Text(
                'Price (USD)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: palette.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final RateBand band in bands)
          _BandRow(
            band: band,
            controller: _prices[band.id],
            onPrice: (String value) => _setPrice(band, value),
            onMethod: (PricingMethod method) => _setMethod(band, method),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addBand,
          icon: const Icon(Icons.add),
          label: const Text('Add band'),
        ),
        InspectorNote(
          text: widget.from1965
              ? 'Includes homes built in 1965.'
              : 'Optional add-ons are not included in these rates.',
        ),
      ],
    );
  }
}

class PricingSummaryStep extends ConsumerWidget {
  const PricingSummaryStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InspectorDraft draft = ref
        .watch(inspectorFlowControllerProvider)
        .requireValue;
    final List<HomeType> types = draft.selectedHomeTypes;
    final int complete = types
        .where((HomeType type) => draft.cardFor(type).isComplete)
        .length;
    final InspectorPalette palette = InspectorPalette.of(context);

    return InspectorStepScaffold(
      step: 4,
      total: 4,
      title: 'Base pricing complete',
      actionLabel: 'Configure add-ons',
      onAction: () => ref
          .read(inspectorFlowControllerProvider.notifier)
          .go(InspectorStep.addonsPest),
      children: <Widget>[
        InspectorNote(
          icon: Icons.check_circle,
          tone: InspectorNoteTone.green,
          text: '$complete home types configured',
        ),
        const SizedBox(height: 12),
        for (final HomeType type in types)
          _HomeTypeCard(
            type: type,
            card: draft.cardFor(type),
            emphasize: false,
            onOpen: () {
              ref
                  .read(inspectorFlowControllerProvider.notifier)
                  .patch(
                    (InspectorDraft current) => current.copyWith(
                      activeHomeType: type,
                      step: InspectorStep.pricingBefore1965,
                    ),
                  );
            },
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _copyCard(context, ref, draft),
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copy & adjust a rate card'),
        ),
        const SizedBox(height: 8),
        Text(
          'Repeat the same pricing steps for each home type.',
          style: TextStyle(color: palette.muted),
        ),
        const InspectorNote(
          text:
              'Next: choose the optional services you offer and set their prices.',
        ),
      ],
    );
  }

  Future<void> _copyCard(
    BuildContext context,
    WidgetRef ref,
    InspectorDraft draft,
  ) async {
    final List<HomeType> types = draft.selectedHomeTypes;
    if (types.length < 2) {
      await showInspectorNoteDialog(
        context,
        title: 'Copy a rate card',
        message: 'Select another home type before copying a rate card.',
      );
      return;
    }
    HomeType source = types.firstWhere(
      (HomeType type) => draft.cardFor(type).isComplete,
      orElse: () => types.first,
    );
    HomeType target = types.firstWhere((HomeType type) => type != source);
    final bool? copied = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setLocal) {
                return AlertDialog(
                  title: const Text('Copy & adjust a rate card'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DropdownButtonFormField<HomeType>(
                        initialValue: source,
                        decoration: const InputDecoration(
                          labelText: 'Copy from',
                        ),
                        items: <DropdownMenuItem<HomeType>>[
                          for (final HomeType type in types)
                            DropdownMenuItem<HomeType>(
                              value: type,
                              child: Text(type.label),
                            ),
                        ],
                        onChanged: (HomeType? value) {
                          if (value == null) return;
                          setLocal(() => source = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<HomeType>(
                        initialValue: target,
                        decoration: const InputDecoration(labelText: 'Copy to'),
                        items: <DropdownMenuItem<HomeType>>[
                          for (final HomeType type in types)
                            if (type != source)
                              DropdownMenuItem<HomeType>(
                                value: type,
                                child: Text(type.label),
                              ),
                        ],
                        onChanged: (HomeType? value) {
                          if (value == null) return;
                          setLocal(() => target = value);
                        },
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Copy & adjust'),
                    ),
                  ],
                );
              },
        );
      },
    );
    if (copied != true || source == target) return;
    ref.read(inspectorFlowControllerProvider.notifier).patch((
      InspectorDraft current,
    ) {
      final HomeRateCard from = current.cardFor(source);
      return current
          .updateCard(
            target,
            HomeRateCard(
              before1965: <RateBand>[...from.before1965],
              from1965: <RateBand>[...from.from1965],
              beforeSaved: from.beforeSaved,
              fromSaved: from.fromSaved,
            ),
          )
          .copyWith(
            activeHomeType: target,
            step: InspectorStep.pricingBefore1965,
          );
    });
  }
}

class _AddBandDialog extends StatefulWidget {
  const _AddBandDialog();

  @override
  State<_AddBandDialog> createState() => _AddBandDialogState();
}

class _AddBandDialogState extends State<_AddBandDialog> {
  final TextEditingController _min = TextEditingController();
  final TextEditingController _max = TextEditingController();

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a size band'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _min,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minimum sq. ft.',
              hintText: '4501',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _max,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Maximum sq. ft.',
              hintText: 'Leave blank for open-ended',
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((
            minSqFt: parseWholeNumber(_min.text),
            maxSqFt: parseWholeNumber(_max.text),
          )),
          child: const Text('Add band'),
        ),
      ],
    );
  }
}

class _HomeTypeCard extends StatelessWidget {
  const _HomeTypeCard({
    required this.type,
    required this.card,
    required this.emphasize,
    required this.onOpen,
  });

  final HomeType type;
  final HomeRateCard card;
  final bool emphasize;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final InspectorPalette palette = InspectorPalette.of(context);
    final bool complete = card.isComplete;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: <Widget>[
          Icon(_homeIcon(type), color: palette.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  type.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: palette.ink,
                  ),
                ),
                Text(
                  complete
                      ? 'Both year groups complete'
                      : 'Set prices for both year groups and all size bands.',
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          if (complete)
            TextButton(onPressed: onOpen, child: const Text('Edit'))
          else if (emphasize)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: onOpen,
              child: const Text('Set prices'),
            )
          else
            Text(
              'Not started',
              style: TextStyle(
                color: palette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _Factor extends StatelessWidget {
  const _Factor({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final InspectorPalette palette = InspectorPalette.of(context);
    return Column(
      children: <Widget>[
        Icon(icon, color: const Color(0xFFF97316)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: palette.ink)),
      ],
    );
  }
}

class _YearCallout extends StatelessWidget {
  const _YearCallout({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final InspectorPalette palette = InspectorPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(detail, style: TextStyle(color: palette.muted)),
        ],
      ),
    );
  }
}

class _YearSwitch extends StatelessWidget {
  const _YearSwitch({
    required this.from1965,
    required this.onBefore,
    required this.onAfter,
  });

  final bool from1965;
  final VoidCallback onBefore;
  final VoidCallback onAfter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _pill('Before 1965', !from1965, onBefore)),
        const SizedBox(width: 8),
        Expanded(child: _pill('1965 or later', from1965, onAfter)),
      ],
    );
  }

  Widget _pill(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? const Color(0xFFF97316) : const Color(0xFFF6F3F0),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : const Color(0xFF171717),
            ),
          ),
        ),
      ),
    );
  }
}

class _BandRow extends StatelessWidget {
  const _BandRow({
    required this.band,
    required this.controller,
    required this.onPrice,
    required this.onMethod,
  });

  final RateBand band;
  final TextEditingController? controller;
  final ValueChanged<String> onPrice;
  final ValueChanged<PricingMethod> onMethod;

  @override
  Widget build(BuildContext context) {
    final InspectorPalette palette = InspectorPalette.of(context);
    final bool request = band.method == PricingMethod.requestQuote;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              band.label,
              style: TextStyle(fontWeight: FontWeight.w600, color: palette.ink),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: request
                ? OutlinedButton(
                    onPressed: () => _menu(context),
                    child: const Text('Request quote'),
                  )
                : TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: onPrice,
                    decoration: InputDecoration(
                      hintText: band.hintPrice?.toString() ?? '0',
                      isDense: true,
                      suffixIcon: IconButton(
                        onPressed: () => _menu(context),
                        icon: const Icon(Icons.arrow_drop_down),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _menu(BuildContext context) async {
    final PricingMethod? method = await showModalBottomSheet<PricingMethod>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: const Text('Set price'),
                onTap: () => Navigator.of(context).pop(PricingMethod.fixed),
              ),
              ListTile(
                title: const Text('Request quote'),
                onTap: () =>
                    Navigator.of(context).pop(PricingMethod.requestQuote),
              ),
            ],
          ),
        );
      },
    );
    if (method != null) onMethod(method);
  }
}

IconData _homeIcon(HomeType type) {
  return switch (type) {
    HomeType.singleFamily => Icons.house_outlined,
    HomeType.townhouse => Icons.holiday_village_outlined,
    HomeType.condo => Icons.apartment_outlined,
    HomeType.duplex => Icons.other_houses_outlined,
  };
}
