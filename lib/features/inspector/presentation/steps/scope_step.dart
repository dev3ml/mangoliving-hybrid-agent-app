import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/inspector_catalog.dart';
import '../../domain/models/inspector_draft.dart';
import '../controllers/inspector_flow_controller.dart';
import '../widgets/inspector_chrome.dart';

class ScopeReviewStep extends ConsumerWidget {
  const ScopeReviewStep({super.key, required this.groupIndex});

  final int groupIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InspectorDraft draft =
        ref.watch(inspectorFlowControllerProvider).requireValue;
    final ScopeGroup group = scopeGroups[groupIndex];
    final int included = group.items
        .where((ScopeItem item) => draft.includedScopeIds.contains(item.id))
        .length;
    final int totalIncluded = scopeGroups.fold<int>(
      0,
      (int sum, ScopeGroup current) =>
          sum +
          current.items
              .where((ScopeItem item) => draft.includedScopeIds.contains(item.id))
              .length,
    );
    final bool last = groupIndex == scopeGroups.length - 1;

    return InspectorStepScaffold(
      step: groupIndex + 1,
      total: scopeGroups.length,
      title: group.title,
      subtitle: 'Base scope · ${groupIndex + 1} of ${scopeGroups.length}',
      actionLabel: last ? 'Set base prices' : 'Continue',
      onAction: () {
        final InspectorStep next = switch (groupIndex) {
          0 => InspectorStep.scopeInterior,
          1 => InspectorStep.scopeSystems,
          2 => InspectorStep.scopeAppliances,
          _ => InspectorStep.pricingTypes,
        };
        ref.read(inspectorFlowControllerProvider.notifier).go(next);
      },
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '$included included items',
            style: const TextStyle(
              color: Color(0xFFF97316),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (int index = 0; index < group.items.length; index++) ...<Widget>[
          if (group.items[index].section != null &&
              (index == 0 ||
                  group.items[index].section != group.items[index - 1].section))
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(
                group.items[index].section!,
                style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF717182),
                ),
              ),
            ),
          _ScopeRow(
            label: group.items[index].label,
            selected: draft.includedScopeIds.contains(group.items[index].id),
            onToggle: () {
              final String id = group.items[index].id;
              ref.read(inspectorFlowControllerProvider.notifier).patch(
                    (InspectorDraft current) {
                      final Set<String> next = <String>{...current.includedScopeIds};
                      if (!next.add(id)) next.remove(id);
                      return current.copyWith(includedScopeIds: next);
                    },
                  );
            },
            onOpen: () {
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (BuildContext sheetContext) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          group.items[index].label,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(group.footnote),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
        InspectorNote(text: group.footnote),
        if (last)
          InspectorNote(
            icon: Icons.check_circle,
            tone: totalIncluded == scopeItemCount
                ? InspectorNoteTone.green
                : InspectorNoteTone.orange,
            text: totalIncluded == scopeItemCount
                ? '30 base items reviewed\nYour base price covers this scope.'
                : '$totalIncluded base items included\nUnchecked items are left out of the base price.',
          ),
      ],
    );
  }
}

class _ScopeRow extends StatelessWidget {
  const _ScopeRow({
    required this.label,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
  });

  final String label;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final InspectorPalette palette = InspectorPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              color: selected ? const Color(0xFFF97316) : palette.muted,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onToggle,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onOpen,
            icon: Icon(Icons.chevron_right, color: palette.muted),
          ),
        ],
      ),
    );
  }
}
