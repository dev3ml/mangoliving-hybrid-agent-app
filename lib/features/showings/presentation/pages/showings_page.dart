import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/env_config.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_skeleton.dart';
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
        title: const Text('Showings'),
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
          loading: () => const AppSkeletonPage(),
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
                color: AppColors.muted,
                height: 1.35,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CountChips(
          counts: view.counts,
          declined: view.requests
              .where(
                (ShowingRequest item) =>
                    item.statusEnum == ShowingStatus.declined,
              )
              .length,
          selected: view.filter,
          onSelected: (ShowingStatus? status) {
            ref.read(showingsControllerProvider.notifier).setFilter(
                  view.filter == status ? null : status,
                );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Column(
              children: <Widget>[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.showings.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.event_available_outlined,
                    color: AppColors.showings,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  view.filter == null
                      ? 'No showing requests yet'
                      : 'No ${view.filter!.label.toLowerCase()} requests',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  view.filter == null
                      ? 'Buyers connected to you can request property tours from the buyer app.'
                      : 'Try another status to see the rest of your requests.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
              ],
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
              onMessage: () => _openMessage(request),
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

  void _openMessage(ShowingRequest request) {
    final String clientId = (request.agentClientId ?? '').trim();
    final String note = (request.message ?? '').trim();
    if (clientId.isNotEmpty) {
      context.push(
        AppRoutes.messageThread(clientId),
        extra: note.isEmpty ? null : note,
      );
      return;
    }
    _showMessage(request);
  }

  Future<void> _showMessage(ShowingRequest request) {
    final String note = (request.message ?? '').trim();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Message'),
          content: Text(
            note.isEmpty
                ? 'No message is attached to this request.'
                : note,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _CountChips extends StatelessWidget {
  const _CountChips({
    required this.counts,
    required this.declined,
    required this.selected,
    required this.onSelected,
  });

  final ShowingCounts counts;
  final int declined;
  final ShowingStatus? selected;
  final ValueChanged<ShowingStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool light = theme.brightness == Brightness.light;
    final List<({String label, int value, ShowingStatus? status, Color color})>
        chips = <({String label, int value, ShowingStatus? status, Color color})>[
      (label: 'All', value: counts.total, status: null, color: AppColors.ink),
      (
        label: 'Pending',
        value: counts.pending,
        status: ShowingStatus.pending,
        color: AppColors.pending,
      ),
      (
        label: 'Scheduled',
        value: counts.scheduled,
        status: ShowingStatus.scheduled,
        color: AppColors.showings,
      ),
      (
        label: 'Completed',
        value: counts.completed,
        status: ShowingStatus.completed,
        color: AppColors.messages,
      ),
      (
        label: 'Cancelled',
        value: counts.cancelled,
        status: ShowingStatus.cancelled,
        color: AppColors.muted,
      ),
      (
        label: 'Declined',
        value: declined,
        status: ShowingStatus.declined,
        color: AppColors.destructive,
      ),
    ];
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final chip = chips[index];
          final bool active = selected == chip.status;
          return Material(
            color: active
                ? (light ? AppColors.accentWash : AppColors.accentWashDark)
                : (light ? Colors.white : theme.colorScheme.surfaceContainerHigh),
            elevation: active ? 0 : 1,
            shadowColor: const Color(0x14000000),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => onSelected(chip.status),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active ? AppColors.primary : Colors.transparent,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${chip.value}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: chip.color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chip.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
    final Uri? listing = request.listingUri(EnvConfig.buyerAppUrl);
    final Uri? mail = request.mailUri;
    final Uri? phone = request.phoneUri;
    final List<({IconData icon, String label, VoidCallback onTap})> links =
        <({IconData icon, String label, VoidCallback onTap})>[
      if (request.canMessage)
        (icon: Icons.chat_bubble_outline, label: 'Message', onTap: onMessage),
      if (listing != null)
        (
          icon: Icons.home_outlined,
          label: 'Listing',
          onTap: () => _openLink(
            context,
            listing,
            failure: 'Couldn’t open this listing.',
          ),
        ),
      if (mail != null)
        (
          icon: Icons.mail_outline,
          label: 'Email',
          onTap: () => _openContact(
            context,
            uri: mail,
            title: 'Email',
            value: request.buyerEmail!.trim(),
            unavailable:
                'Mail isn’t set up on this device. The iPhone simulator only opens Mail after you add an account. On a real iPhone this opens a new email.',
          ),
        ),
      if (phone != null)
        (
          icon: Icons.call_outlined,
          label: 'Call',
          onTap: () => _openContact(
            context,
            uri: phone,
            title: 'Call',
            value: request.buyerPhone!.trim(),
            unavailable:
                'This device can’t place calls. The iPhone simulator has no Phone app, so Call only opens the dialer on a real iPhone.',
          ),
        ),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFFFE4D0),
                  child: Text(
                    _initials(request.displayBuyerName),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    request.displayBuyerName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
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
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    request.propertyLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (request.propertySubtitle.isNotEmpty)
                    Text(
                      request.propertySubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Requested ${TimeFormat.showingDate(request.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.scheduledAt == null
                        ? 'Visit not set'
                        : 'Visit ${TimeFormat.showingDate(request.scheduledAt)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (request.canSchedule ||
                      request.canReschedule ||
                      request.canDecline ||
                      request.statusEnum == ShowingStatus.scheduled) ...<Widget>[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        if (request.canSchedule)
                          FilledButton.icon(
                            onPressed: busy ? null : onSchedule,
                            icon: const Icon(Icons.event_available_outlined, size: 16),
                            label: const Text('Schedule'),
                          ),
                        if (request.canReschedule)
                          FilledButton.icon(
                            onPressed: busy ? null : onReschedule,
                            icon: const Icon(Icons.event_repeat_outlined, size: 16),
                            label: const Text('Reschedule'),
                          ),
                        if (request.canDecline)
                          OutlinedButton(
                            onPressed: busy ? null : onDecline,
                            child: const Text('Decline'),
                          ),
                        if (request.statusEnum == ShowingStatus.scheduled)
                          OutlinedButton(
                            onPressed: busy ? null : onCancel,
                            child: const Text('Cancel visit'),
                          ),
                      ],
                    ),
                  ],
                  if (links.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Row(
                      children: links
                          .map(
                            (({IconData icon, String label, VoidCallback onTap}) link) {
                              return Expanded(
                                child: InkWell(
                                  onTap: link.onTap,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Column(
                                      children: <Widget>[
                                        Icon(link.icon, size: 18, color: AppColors.primary),
                                        const SizedBox(height: 4),
                                        Text(
                                          link.label,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) return parts.first[0].toUpperCase();
    return 'S';
  }

  bool get _iosSimulator =>
      !kIsWeb &&
      Platform.isIOS &&
      Platform.environment.containsKey('SIMULATOR_UDID');

  Future<void> _openContact(
    BuildContext context, {
    required Uri uri,
    required String title,
    required String value,
    required String unavailable,
  }) async {
    if (!_iosSimulator) {
      final bool opened = await _launch(uri, web: false);
      if (opened || !context.mounted) return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    final String reason = _iosSimulator
        ? unavailable
        : '$title couldn’t open on this phone. $value is copied so you can paste it into ${title == 'Call' ? 'Phone' : 'Mail'}.';
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SelectableText('$reason\n\n$value'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openLink(BuildContext context, Uri uri, {required String failure}) async {
    final bool opened = await _launch(uri, web: true);
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure)));
  }

  Future<bool> _launch(Uri uri, {required bool web}) async {
    final List<LaunchMode> modes = web
        ? <LaunchMode>[
            LaunchMode.externalApplication,
            LaunchMode.inAppBrowserView,
            LaunchMode.platformDefault,
          ]
        : <LaunchMode>[
            LaunchMode.externalApplication,
            LaunchMode.platformDefault,
          ];
    for (final LaunchMode mode in modes) {
      try {
        if (await launchUrl(uri, mode: mode)) return true;
      } on Object {
        // Try the next way to open the link.
      }
    }
    return false;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ShowingStatus status;

  @override
  Widget build(BuildContext context) {
    final Color tone = switch (status) {
      ShowingStatus.pending => AppColors.pending,
      ShowingStatus.scheduled => AppColors.showings,
      ShowingStatus.completed => AppColors.messages,
      ShowingStatus.cancelled => AppColors.muted,
      ShowingStatus.declined => AppColors.destructive,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: tone,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

