import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/env_config.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../account/presentation/controllers/theme_mode_controller.dart';
import '../../data/inspector_auth_remote.dart';
import '../../domain/models/inspector_session.dart';
import '../controllers/inspector_auth_controller.dart';

final inspectorBookingsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((Ref ref) async {
  return ref.watch(inspectorAuthRemoteProvider).bookings();
});

class InspectorInboxPage extends ConsumerStatefulWidget {
  const InspectorInboxPage({super.key});

  @override
  ConsumerState<InspectorInboxPage> createState() => _InspectorInboxPageState();
}

class _InspectorInboxPageState extends ConsumerState<InspectorInboxPage> {
  int _index = 0;

  static const List<String> _titles = <String>[
    'Bookings',
    'Schedule',
    'Earnings',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inspectorAuthControllerProvider.notifier).refresh();
    });
  }

  void _open(String token) {
    context.push(
      Uri(
        path: AppRoutes.inspectorBooking,
        queryParameters: <String, String>{'token': token},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final InspectorSession? session =
        ref.watch(inspectorAuthControllerProvider).valueOrNull;
    final AsyncValue<List<Map<String, dynamic>>> bookings =
        ref.watch(inspectorBookingsProvider);
    final int fresh = bookings.valueOrNull
            ?.where((Map<String, dynamic> row) => row['state'] == 'request_sent')
            .length ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: <Widget>[
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(inspectorBookingsProvider);
              ref.read(inspectorAuthControllerProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: switch (_index) {
        0 => _BookingsTab(
            session: session,
            bookings: bookings,
            onOpen: _open,
          ),
        1 => _ScheduleTab(bookings: bookings, onOpen: _open),
        2 => _EarningsTab(bookings: bookings, onOpen: _open),
        _ => _ProfileTab(session: session),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int index) {
          HapticFeedback.selectionClick();
          setState(() => _index = index);
        },
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: Badge(
              isLabelVisible: fresh > 0,
              label: Text('$fresh'),
              child: const Icon(Icons.assignment_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: fresh > 0,
              label: Text('$fresh'),
              child: const Icon(Icons.assignment),
            ),
            label: 'Bookings',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          const NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Earnings',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _BookingsTab extends ConsumerWidget {
  const _BookingsTab({
    required this.session,
    required this.bookings,
    required this.onOpen,
  });

  final InspectorSession? session;
  final AsyncValue<List<Map<String, dynamic>>> bookings;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final InspectorProfile? inspector = session?.inspector;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (inspector != null)
          Material(
            color: dark ? AppColors.surfaceDark : AppColors.mutedWash,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    inspector.displayName,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (inspector.companyName.isNotEmpty) inspector.companyName,
                      _approvalLabel(inspector.status),
                    ].where((String part) => part.isNotEmpty).join(' · '),
                    style: TextStyle(
                      color: dark ? AppColors.mutedDark : AppColors.muted,
                    ),
                  ),
                  if (_isApproved(inspector.status)) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      'Approved. Buyers can request you now.',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        Expanded(
          child: bookings.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (List<Map<String, dynamic>> rows) {
              return _RequestList(
                rows: rows,
                emptyColor: colors.onSurfaceVariant,
                onRefresh: () async => ref.invalidate(inspectorBookingsProvider),
                onOpen: onOpen,
              );
            },
          ),
        ),
      ],
    );
  }
}

bool _isApproved(String status) {
  final String value = status.trim().toLowerCase();
  return value == 'active' || value == 'approved' || value == 'live';
}

String _approvalLabel(String status) {
  if (_isApproved(status)) return 'Approved';
  if (status.trim().isEmpty) return 'Approved';
  return status.replaceAll('_', ' ');
}

enum _RequestFilter { all, fresh, upcoming, done }

class _RequestList extends StatefulWidget {
  const _RequestList({
    required this.rows,
    required this.emptyColor,
    required this.onRefresh,
    required this.onOpen,
  });

  final List<Map<String, dynamic>> rows;
  final Color emptyColor;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onOpen;

  @override
  State<_RequestList> createState() => _RequestListState();
}

class _RequestListState extends State<_RequestList> {
  _RequestFilter _filter = _RequestFilter.all;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<Map<String, dynamic>> shown = widget.rows
        .where((Map<String, dynamic> row) => _matches(_filter, row))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: <Widget>[
              for (final _RequestFilter filter in _RequestFilter.values) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_filterLabel(filter)),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: shown.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      _CountRow(rows: widget.rows),
                      const SizedBox(height: 16),
                      Text(
                        widget.rows.isEmpty
                            ? 'No inspection requests yet. You’re approved and live in the buyer shortlist.'
                            : 'Nothing in ${_filterLabel(_filter).toLowerCase()}.',
                        style: TextStyle(color: widget.emptyColor, height: 1.4),
                      ),
                      if (widget.rows.isEmpty) ...<Widget>[
                        const SizedBox(height: 16),
                        const _HowItWorks(),
                      ],
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: shown.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _CountRow(rows: widget.rows),
                        );
                      }
                      return _BookingCard(
                        booking: shown[index - 1],
                        colors: colors,
                        onOpen: widget.onOpen,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

bool _matches(_RequestFilter filter, Map<String, dynamic> booking) {
  final String state = booking['state']?.toString() ?? '';
  switch (filter) {
    case _RequestFilter.all:
      return true;
    case _RequestFilter.fresh:
      return state == 'request_sent';
    case _RequestFilter.upcoming:
      return state == 'provider_accepted' || state == 'confirmed';
    case _RequestFilter.done:
      return const <String>{
        'inspection_completed',
        'report_delivered',
        'closed',
        'declined',
        'expired',
        'cancelled',
      }.contains(state);
  }
}

String _filterLabel(_RequestFilter filter) {
  switch (filter) {
    case _RequestFilter.all:
      return 'All';
    case _RequestFilter.fresh:
      return 'New';
    case _RequestFilter.upcoming:
      return 'Upcoming';
    case _RequestFilter.done:
      return 'Done';
  }
}

String _stateLabel(String state) {
  switch (state) {
    case 'request_sent':
      return 'New request';
    case 'provider_accepted':
      return 'Waiting for the buyer';
    case 'confirmed':
      return 'Confirmed';
    case 'inspection_completed':
      return 'Inspection completed';
    case 'report_delivered':
      return 'Report delivered';
    default:
      return state.replaceAll('_', ' ');
  }
}

String _formatWhen(Object? iso) {
  if (iso == null) return '';
  final DateTime? date = DateTime.tryParse(iso.toString());
  if (date == null) return '';
  return DateFormat('MMM d, y · h:mm a').format(date.toLocal());
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.colors,
    required this.onOpen,
  });

  final Map<String, dynamic> booking;
  final ColorScheme colors;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> property = _map(booking['property']);
    final Map<String, dynamic> request = _map(booking['request']);
    final Map<String, dynamic> quote = _map(booking['quote']);
    final String address = [
      property['streetAddress'],
      property['city'],
    ].whereType<String>().where((String part) => part.trim().isNotEmpty).join(', ');
    final String state = booking['state']?.toString() ?? '';
    final String appointment = _formatWhen(quote['appointmentAt']);
    final String respondBy = _formatWhen(request['expiresAt']);
    final String when = appointment.isNotEmpty
        ? 'Appointment $appointment'
        : respondBy.isNotEmpty
            ? 'Respond by $respondBy'
            : '';
    final String token = booking['link']?.toString() ?? '';

    return Card(
      child: InkWell(
        onTap: token.isEmpty ? null : () => onOpen(token),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      address.isEmpty ? 'Inspection request' : address,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _stateLabel(state),
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (when.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(when, style: TextStyle(color: colors.onSurfaceVariant)),
              ],
              const SizedBox(height: 8),
              Text(
                'Open',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((dynamic key, dynamic item) => MapEntry('$key', item));
  }
  return <String, dynamic>{};
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int fresh = rows.where((Map<String, dynamic> row) => _matches(_RequestFilter.fresh, row)).length;
    final int upcoming = rows.where((Map<String, dynamic> row) => _matches(_RequestFilter.upcoming, row)).length;
    final int done = rows.where((Map<String, dynamic> row) => _matches(_RequestFilter.done, row)).length;
    return Row(
      children: <Widget>[
        _CountTile(label: 'New', value: '$fresh', color: colors.primary),
        const SizedBox(width: 8),
        _CountTile(label: 'Upcoming', value: '$upcoming', color: colors.onSurface),
        const SizedBox(width: 8),
        _CountTile(label: 'Done', value: '$done', color: colors.onSurface),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
              Text(label, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    const List<(String, String)> steps = <(String, String)>[
      ('1', 'A buyer picks you from the shortlist and pays.'),
      ('2', 'You accept a time, propose a change, or decline.'),
      ('3', 'After the visit, mark it complete and upload the report.'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('How a booking works', style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final (String number, String text) in steps) ...<Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(number, style: TextStyle(color: colors.primary, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(text, style: TextStyle(color: colors.onSurface, height: 1.35))),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab({required this.bookings, required this.onOpen});

  final AsyncValue<List<Map<String, dynamic>>> bookings;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return bookings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => _Message(error.toString()),
      data: (List<Map<String, dynamic>> rows) {
        final List<Map<String, dynamic>> visits = rows.where((Map<String, dynamic> row) {
          return _matches(_RequestFilter.upcoming, row);
        }).toList()
          ..sort((Map<String, dynamic> a, Map<String, dynamic> b) {
            final DateTime? left = DateTime.tryParse('${_map(a['quote'])['appointmentAt']}');
            final DateTime? right = DateTime.tryParse('${_map(b['quote'])['appointmentAt']}');
            if (left == null && right == null) return 0;
            if (left == null) return 1;
            if (right == null) return -1;
            return left.compareTo(right);
          });
        final ColorScheme colors = Theme.of(context).colorScheme;
        if (visits.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                'No visits on the calendar yet. Accepted requests show up here with their appointment time.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
              ),
            ],
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: visits.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            return _BookingCard(booking: visits[index], colors: colors, onOpen: onOpen);
          },
        );
      },
    );
  }
}

class _EarningsTab extends StatelessWidget {
  const _EarningsTab({required this.bookings, required this.onOpen});

  final AsyncValue<List<Map<String, dynamic>>> bookings;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return bookings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => _Message(error.toString()),
      data: (List<Map<String, dynamic>> rows) {
        final ColorScheme colors = Theme.of(context).colorScheme;
        int paidCents = 0;
        int waitingCents = 0;
        for (final Map<String, dynamic> row in rows) {
          final int cents = _cents(_map(row['payment'])['providerCents']);
          final bool paid = _map(row['payment'])['buyerPaid'] == true;
          if (_matches(_RequestFilter.done, row) && paid) {
            paidCents += cents;
          } else if (_matches(_RequestFilter.upcoming, row) && paid) {
            waitingCents += cents;
          }
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Row(
              children: <Widget>[
                _CountTile(label: 'From finished visits', value: _money(paidCents), color: colors.primary),
                const SizedBox(width: 8),
                _CountTile(label: 'Upcoming, paid', value: _money(waitingCents), color: colors.onSurface),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'MangoLiving collects from the buyer and passes your portion through. Direct payments show up on the booking after the visit.',
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              Text('Nothing to total yet.', style: TextStyle(color: colors.onSurfaceVariant))
            else
              for (final Map<String, dynamic> row in rows) ...<Widget>[
                _BookingCard(booking: row, colors: colors, onOpen: onOpen),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab({required this.session});

  final InspectorSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final InspectorProfile? inspector = session?.inspector;
    if (inspector == null) {
      return const Center(child: Text('Sign in to see your profile.'));
    }
    final String initials = inspector.displayName
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .take(2)
        .map((String part) => part[0].toUpperCase())
        .join();
    final String area = <String>[
      ...inspector.cities,
      ...inspector.states,
    ].join(', ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          children: <Widget>[
            _InspectorPhoto(
              url: inspector.photoUrl,
              initials: initials,
              color: colors.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    inspector.displayName,
                    style: TextStyle(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  if (inspector.companyName.isNotEmpty)
                    Text(inspector.companyName, style: TextStyle(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text(
                    _isApproved(inspector.status) ? 'Approved' : _approvalLabel(inspector.status),
                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (inspector.bio.isNotEmpty) ...<Widget>[
          Text(inspector.bio, style: TextStyle(color: colors.onSurface, height: 1.4)),
          const SizedBox(height: 16),
        ],
        _ProfileRow(label: 'Email', value: inspector.email),
        _ProfileRow(label: 'Phone', value: inspector.phone),
        _ProfileRow(label: 'License', value: inspector.licenseNumber),
        _ProfileRow(
          label: 'Experience',
          value: inspector.yearsExperience > 0 ? '${inspector.yearsExperience} years' : '',
        ),
        _ProfileRow(label: 'Coverage', value: area),
        if (inspector.services.isNotEmpty)
          _ProfileRow(label: 'Services', value: inspector.services.join(', ')),
        const SizedBox(height: 8),
        const _AppearancePicker(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(inspectorAuthControllerProvider.notifier).logout();
            if (context.mounted) context.go(AppRoutes.inspectorLogin);
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _InspectorPhoto extends StatelessWidget {
  const _InspectorPhoto({
    required this.url,
    required this.initials,
    required this.color,
  });

  final String url;
  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final String src = _reachablePhoto(url);
    final Widget fallback = CircleAvatar(
      radius: 32,
      backgroundColor: color.withValues(alpha: 0.16),
      child: Text(initials, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
    );
    if (src.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        src,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

String _reachablePhoto(String url) {
  final Uri? parsed = Uri.tryParse(url);
  if (parsed == null || !parsed.path.contains('/uploads/')) return url;
  final Uri api = Uri.parse(EnvConfig.apiBaseUrl);
  final bool local = api.host == 'localhost' || api.host == '127.0.0.1' || api.host == '10.0.2.2';
  if (!local) return url;
  if (parsed.host == api.host && parsed.port == api.port) return url;
  return Uri(
    scheme: api.scheme,
    host: api.host,
    port: api.hasPort ? api.port : null,
    path: parsed.path,
  ).toString();
}

class _AppearancePicker extends ConsumerWidget {
  const _AppearancePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ThemeMode mode = ref.watch(themeModeControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Appearance',
          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const <ButtonSegment<ThemeMode>>[
            ButtonSegment<ThemeMode>(value: ThemeMode.system, label: Text('System')),
            ButtonSegment<ThemeMode>(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment<ThemeMode>(value: ThemeMode.dark, label: Text('Dark')),
          ],
          selected: <ThemeMode>{mode},
          onSelectionChanged: (Set<ThemeMode> next) {
            ref.read(themeModeControllerProvider.notifier).setMode(next.first);
          },
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: colors.onSurface)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text.replaceFirst('Exception: ', ''), textAlign: TextAlign.center),
      ),
    );
  }
}

int _cents(Object? value) {
  if (value is num) return value.round();
  return int.tryParse('$value') ?? 0;
}

String _money(int cents) {
  if (cents <= 0) return '\$0';
  final bool whole = cents % 100 == 0;
  return '\$${(cents / 100).toStringAsFixed(whole ? 0 : 2)}';
}
