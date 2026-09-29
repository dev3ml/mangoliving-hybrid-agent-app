import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/models/showing_request.dart';
import '../controllers/showings_controller.dart';
import '../widgets/schedule_visit_sheet.dart';

class ShowingsPage extends ConsumerStatefulWidget {
  const ShowingsPage({super.key});

  @override
  ConsumerState<ShowingsPage> createState() => _ShowingsPageState();
}

class _ShowingsPageState extends ConsumerState<ShowingsPage> {
  @override
  Widget build(BuildContext context) {
    ref.listen<ShowingStatus?>(showingsInitialFilterProvider, (
      ShowingStatus? previous,
      ShowingStatus? next,
    ) {
      ref.read(showingsControllerProvider.notifier).setFilter(next);
    });

    final AsyncValue<ShowingsViewData> async =
        ref.watch(showingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Showing Requests'),
        actions: DashboardAppBarActions.of(
          extra: <Widget>[
            IconButton(
              tooltip: 'Refresh',
              onPressed: () =>
                  ref.read(showingsControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(showingsControllerProvider.notifier).refresh(),
        child: async.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: Text('Loading showing requests…')),
          error: (Object error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              Text(
                'Failed to load showing requests.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(error.toString()),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () =>
                    ref.read(showingsControllerProvider.notifier).refresh(),
                child: const Text('Refresh'),
              ),
            ],
          ),
          data: _body,
        ),
      ),
    );
  }

  Widget _body(ShowingsViewData view) {
    final List<ShowingRequest> visible = view.visible;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: <Widget>[
        Text(
          'Manage tour requests from buyers connected to you.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CountChips(
          counts: view.counts,
          selected: view.filter,
          onSelected: (ShowingStatus? status) {
            ref.read(showingsControllerProvider.notifier).setFilter(
                  view.filter == status ? null : status,
                );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: const Text('All'),
              selected: view.filter == null,
              onSelected: (_) =>
                  ref.read(showingsControllerProvider.notifier).setFilter(null),
            ),
            ...ShowingStatus.values.map((ShowingStatus status) {
              return ChoiceChip(
                label: Text(status.label),
                selected: view.filter == status,
                onSelected: (_) {
                  ref.read(showingsControllerProvider.notifier).setFilter(
                        view.filter == status ? null : status,
                      );
                },
              );
            }),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(
              view.filter == null
                  ? 'No showing requests yet. Buyers connected to you can request property tours from the buyer app.'
                  : 'No ${view.filter!.label.toLowerCase()} requests.',
            ),
          )
        else
          ...visible.map((ShowingRequest request) {
            return _ShowingCard(
              request: request,
              busy: view.isBusy(request.id),
              onSchedule: () => _schedule(request, reschedule: false),
              onReschedule: () => _schedule(request, reschedule: true),
              onDecline: () => _confirmDecline(request),
              onCancel: () => _confirmCancel(request),
              onMark: (ShowingStatus status) => _mark(request, status),
              onMessage: () => _showMessage(request),
            );
          }),
      ],
    );
  }

  Future<void> _schedule(ShowingRequest request, {required bool reschedule}) async {
    final DateTime? when = await showScheduleVisitSheet(
      context,
      request: request,
      reschedule: reschedule,
    );
    if (when == null || !mounted) return;
    try {
      await ref.read(showingsControllerProvider.notifier).schedule(
            request: request,
            when: when,
          );
      if (!mounted) return;
      final String label = TimeFormat.showingDate(when.toIso8601String());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reschedule
                ? 'Visit rescheduled for $label'
                : 'Visit scheduled for $label',
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _confirmDecline(ShowingRequest request) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Decline showing request from ${request.displayBuyerName}?',
          ),
          content: const Text(
            'The request will be marked as declined. The buyer can submit another request for a different property or time.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Decline request'),
            ),
          ],
        );
      },
    );
    if (ok == true) await _mark(request, ShowingStatus.declined);
  }

  Future<void> _confirmCancel(ShowingRequest request) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Cancel showing request from ${request.displayBuyerName}?',
          ),
          content: const Text(
            'The scheduled visit will be cancelled. The buyer will see the request as cancelled and can rebook if needed.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep visit'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cancel visit'),
            ),
          ],
        );
      },
    );
    if (ok == true) await _mark(request, ShowingStatus.cancelled);
  }

  Future<void> _mark(ShowingRequest request, ShowingStatus status) async {
    try {
      await ref.read(showingsControllerProvider.notifier).mark(
            request: request,
            status: status,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked as ${status.label.toLowerCase()}')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _showMessage(ShowingRequest request) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Showing message', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '${request.displayBuyerName} · ${request.listingTitle}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(request.message ?? ''),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CountChips extends StatelessWidget {
  const _CountChips({
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  final ShowingCounts counts;
  final ShowingStatus? selected;
  final ValueChanged<ShowingStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<({String label, int value, ShowingStatus? status})> chips =
        <({String label, int value, ShowingStatus? status})>[
      (label: 'Total', value: counts.total, status: null),
      (label: 'Pending', value: counts.pending, status: ShowingStatus.pending),
      (label: 'Scheduled', value: counts.scheduled, status: ShowingStatus.scheduled),
      (label: 'Completed', value: counts.completed, status: ShowingStatus.completed),
      (label: 'Cancelled', value: counts.cancelled, status: ShowingStatus.cancelled),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((chip) {
        final bool active = selected == chip.status && chip.status != null;
        return Material(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color: active
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: active ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => onSelected(chip.status),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${chip.value}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    chip.label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ShowingCard extends StatelessWidget {
  const _ShowingCard({
    required this.request,
    required this.busy,
    required this.onSchedule,
    required this.onReschedule,
    required this.onDecline,
    required this.onCancel,
    required this.onMark,
    required this.onMessage,
  });

  final ShowingRequest request;
  final bool busy;
  final VoidCallback onSchedule;
  final VoidCallback onReschedule;
  final VoidCallback onDecline;
  final VoidCallback onCancel;
  final ValueChanged<ShowingStatus> onMark;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    request.displayBuyerName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusBadge(status: request.statusEnum),
                PopupMenuButton<ShowingStatus>(
                  enabled: !busy,
                  onSelected: (ShowingStatus status) {
                    if (status == ShowingStatus.scheduled) {
                      if (request.canSchedule) {
                        onSchedule();
                      } else {
                        onReschedule();
                      }
                      return;
                    }
                    if (status == ShowingStatus.declined && request.canDecline) {
                      onDecline();
                      return;
                    }
                    if (status == ShowingStatus.cancelled &&
                        request.statusEnum == ShowingStatus.scheduled) {
                      onCancel();
                      return;
                    }
                    onMark(status);
                  },
                  itemBuilder: (BuildContext context) {
                    return ShowingStatus.values
                        .where((ShowingStatus s) => s != request.statusEnum)
                        .map(
                          (ShowingStatus s) => PopupMenuItem<ShowingStatus>(
                            value: s,
                            child: Text(s.markAsLabel),
                          ),
                        )
                        .toList();
                  },
                ),
              ],
            ),
            Text(request.propertyLabel, style: theme.textTheme.bodyMedium),
            if (request.propertySubtitle.isNotEmpty)
              Text(request.propertySubtitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              'Requested ${TimeFormat.showingDate(request.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              request.scheduledAt == null
                  ? 'Visit Not set'
                  : 'Visit ${TimeFormat.showingDate(request.scheduledAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (request.canSchedule)
                  OutlinedButton.icon(
                    onPressed: busy ? null : onSchedule,
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Schedule'),
                  ),
                if (request.canReschedule)
                  OutlinedButton.icon(
                    onPressed: busy ? null : onReschedule,
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Reschedule'),
                  ),
                if (request.canDecline)
                  TextButton(
                    onPressed: busy ? null : onDecline,
                    child: const Text('Decline'),
                  ),
                if (request.statusEnum == ShowingStatus.scheduled)
                  TextButton(
                    onPressed: busy ? null : onCancel,
                    child: const Text('Cancel visit'),
                  ),
                if (request.hasMessage)
                  TextButton(
                    onPressed: onMessage,
                    child: const Text('View'),
                  ),
                if (request.hasListingUrl)
                  TextButton(
                    onPressed: () => _openUri(request.propertyUrl!),
                    child: const Text('View listing'),
                  ),
                if (request.hasEmail)
                  TextButton(
                    onPressed: () => _openUri('mailto:${request.buyerEmail}'),
                    child: const Text('Email buyer'),
                  ),
                if (request.hasPhone)
                  TextButton(
                    onPressed: () => _openUri('tel:${request.buyerPhone}'),
                    child: const Text('Call'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUri(String raw) async {
    final Uri? uri = Uri.tryParse(raw);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      // Listing / mail / phone open is best-effort on device.
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ShowingStatus status;

  @override
  Widget build(BuildContext context) {
    final bool destructive = status == ShowingStatus.cancelled ||
        status == ShowingStatus.declined;
    final bool pending = status == ShowingStatus.pending;
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(status.label),
      backgroundColor: pending
          ? AppColors.primary.withValues(alpha: 0.12)
          : destructive
              ? AppColors.destructive.withValues(alpha: 0.12)
              : null,
      labelStyle: TextStyle(
        color: pending
            ? AppColors.primary
            : destructive
                ? AppColors.destructive
                : null,
      ),
    );
  }
}

