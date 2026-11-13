import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/app_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../data/inspector_auth_remote.dart';
import '../controllers/inspector_auth_controller.dart';
import 'inspector_inbox_page.dart';

class InspectorBookingPage extends ConsumerStatefulWidget {
  const InspectorBookingPage({super.key, required this.token});

  final String token;

  @override
  ConsumerState<InspectorBookingPage> createState() =>
      _InspectorBookingPageState();
}

class _InspectorBookingPageState extends ConsumerState<InspectorBookingPage> {
  Map<String, dynamic>? _booking;
  Object? _error;
  bool _loading = true;
  bool _busy = false;
  bool _changingTime = false;
  DateTime? _appointment;
  DateTime? _reportDue;
  final TextEditingController _note = TextEditingController();
  final TextEditingController _license = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    _license.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'This page needs a booking link.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Map<String, dynamic> booking =
          await ref.read(inspectorAuthRemoteProvider).booking(widget.token);
      if (!mounted) return;
      final String profileLicense = ref
              .read(inspectorAuthControllerProvider)
              .valueOrNull
              ?.inspector
              .licenseNumber
              .trim() ??
          '';
      if (_license.text.trim().isEmpty && profileLicense.isNotEmpty) {
        _license.text = profileLicense;
      }
      setState(() {
        _booking = booking;
        _loading = false;
        _appointment ??= _defaultAppointment(booking);
        _reportDue ??= _defaultReportDue(booking, _appointment);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _run(Future<Map<String, dynamic>> Function() action) async {
    setState(() => _busy = true);
    try {
      final Map<String, dynamic> next = await action();
      if (!mounted) return;
      setState(() {
        _booking = <String, dynamic>{
          ...?_booking,
          ...next,
          if ((next['roster'] as List?)?.isEmpty ?? true)
            'roster': _booking?['roster'],
        };
      });
      ref.invalidate(inspectorBookingsProvider);
      if (mounted) setState(() => _changingTime = false);
    } catch (error) {
      _toast(_message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection request'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.inspectorHome);
            }
          },
        ),
        actions: const <Widget>[ThemeToggleButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _message(_error),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurface),
                    ),
                  ),
                )
              : _body(colors, _booking!),
    );
  }

  Widget _body(ColorScheme colors, Map<String, dynamic> booking) {
    final String state = booking['state']?.toString() ?? '';
    final Map<String, dynamic> property = _map(booking['property']);
    final Map<String, dynamic> request = _map(booking['request']);
    final Map<String, dynamic> payment = _map(booking['payment']);
    final Map<String, dynamic> contact = _map(booking['buyerContact']);
    final Map<String, dynamic>? quote = booking['quote'] is Map
        ? _map(booking['quote'])
        : null;
    final bool paid = payment['buyerPaid'] == true;
    final bool openRequest = state == 'request_sent';
    final bool waitingOnBuyer = state == 'provider_accepted';
    final bool booked = state == 'confirmed';
    final bool visitDone = state == 'inspection_completed' || state == 'report_delivered';
    final bool acceptBlocked = openRequest && !paid;
    final bool showScheduleForm = openRequest || (_changingTime && !visitDone);
    final Map<String, dynamic>? latestReport = _latestReport(booking);
    final bool reportHeld = latestReport?['status'] == 'correction_queue';
    final String quoteTitle = state == 'report_delivered'
        ? 'Report delivered'
        : state == 'inspection_completed'
            ? 'Visit done'
            : booked
                ? 'Booked'
                : 'Accepted';
    final String quoteBody = state == 'report_delivered'
        ? 'The buyer has the report.'
        : state == 'inspection_completed'
            ? 'The inspection is complete. Upload the PDF report below.'
            : booked
                ? 'This visit is confirmed. The buyer has the appointment.'
                : 'You accepted this time. Waiting for the buyer to confirm it.';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          property['streetAddress']?.toString().trim().isNotEmpty == true
              ? property['streetAddress'].toString()
              : 'Inspection request',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          [
            property['city'],
            property['province'],
            property['postalCode'],
          ].whereType<Object>().map((Object part) => '$part'.trim()).where((String part) => part.isNotEmpty).join(', '),
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              _stateLabel(state),
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (state == 'request_sent' && request['expiresAt'] != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            'Respond by ${_when(request['expiresAt'])}',
            style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 20),
        _section(colors, 'The request', <Widget>[
          _fact(colors, 'Services', _services(request['services'])),
          _fact(colors, 'Inspection needed by', _when(request['inspectionDeadline'])),
          _fact(colors, 'Report needed by', _when(request['reportDeadline'])),
          _fact(colors, 'Home', _home(property)),
          _fact(colors, 'Preferred times', _windows(request['preferredWindows'])),
          if ('${request['accessNotes'] ?? ''}'.trim().isNotEmpty)
            _fact(colors, 'Access notes', '${request['accessNotes']}'),
          _fact(
            colors,
            'Buyer',
            _buyer(contact),
          ),
          _fact(
            colors,
            'Payment',
            paid ? 'Buyer has paid' : 'Waiting for the buyer to pay',
          ),
        ]),
        if (quote != null && !openRequest) ...<Widget>[
          const SizedBox(height: 16),
          _section(colors, quoteTitle, <Widget>[
            Text(
              quoteBody,
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 12),
            _fact(colors, 'Inspector', '${quote['inspectorName'] ?? ''}'),
            _fact(colors, 'Appointment', _when(quote['appointmentAt'])),
            _fact(colors, 'Report by', _when(quote['reportDueAt'])),
            _fact(colors, 'Your portion', _money(payment['providerCents'])),
            if (!_changingTime && !visitDone)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _busy ? null : () => setState(() => _changingTime = true),
                  child: const Text('Propose a different time'),
                ),
              ),
          ]),
        ],
        if (showScheduleForm) ...<Widget>[
          const SizedBox(height: 16),
          _section(
            colors,
            openRequest
                ? (acceptBlocked ? 'Accept after payment' : 'Accept and schedule')
                : 'Propose a different time',
            <Widget>[
              if (acceptBlocked)
                Text(
                  'The buyer has not completed payment yet. Ask them to pay before you accept.',
                  style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
                ),
              if (openRequest && request['outsideFit'] == true)
                Text(
                  'The buyer knows you may not meet their dates. Propose the earliest time you can.',
                  style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Appointment'),
                subtitle: Text(_appointment == null ? 'Choose a time' : _when(_appointment)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _busy ? null : () => _pickAppointment(request),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Report due'),
                subtitle: Text(_reportDue == null ? 'Choose a time' : _when(_reportDue)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _busy ? null : _pickReportDue,
              ),
              TextField(
                controller: _note,
                enabled: !_busy,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note for the buyer',
                  hintText: 'Optional',
                ),
              ),
              const SizedBox(height: 12),
              if (openRequest) ...<Widget>[
                FilledButton(
                  onPressed: _busy || acceptBlocked ? null : () => _respond('accept'),
                  child: Text(_busy ? 'Sending…' : 'Accept'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy || acceptBlocked ? null : () => _respond('propose'),
                  child: const Text('Propose a change'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _busy ? null : _decline,
                  child: const Text('Decline'),
                ),
              ] else ...<Widget>[
                FilledButton(
                  onPressed: _busy ? null : () => _respond('propose'),
                  child: Text(_busy ? 'Sending…' : 'Send new time'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _changingTime = false),
                  child: const Text('Keep the current time'),
                ),
              ],
            ],
          ),
        ],
        if (state == 'confirmed') ...<Widget>[
          const SizedBox(height: 16),
          _section(colors, 'After the visit', <Widget>[
            FilledButton(
              onPressed: _busy ? null : _complete,
              child: const Text('Mark inspection complete'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _couldNotProceed,
              child: const Text('Could not proceed'),
            ),
          ]),
        ],
        if (state == 'inspection_completed' || state == 'report_delivered') ...<Widget>[
          const SizedBox(height: 16),
          _section(colors, 'Report', <Widget>[
            if (state == 'report_delivered')
              Text(
                'The buyer has the report.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
              ),
            if (reportHeld) ...<Widget>[
              Text(
                _holdMessage(latestReport),
                style: TextStyle(color: colors.error, height: 1.4),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _license,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'License number on the report',
                helperText: 'Use the license number on your profile.',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : () => _upload(property),
              child: const Text('Upload PDF report'),
            ),
          ]),
        ],
        if (payment['providerPaymentStatus'] == 'due_to_provider') ...<Widget>[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(
                      () => ref
                          .read(inspectorAuthRemoteProvider)
                          .paymentReceived(widget.token),
                    ),
            child: const Text('Payment received'),
          ),
        ],
        if (state == 'confirmed' || state == 'inspection_completed') ...<Widget>[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : _reviseDue,
            child: const Text('Report will be late'),
          ),
        ],
        if (waitingOnBuyer || booked) ...<Widget>[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _busy ? null : _cancel,
            child: const Text('Cancel booking'),
          ),
        ],
      ],
    );
  }

  Widget _section(ColorScheme colors, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _fact(ColorScheme colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value.isEmpty ? '—' : value, style: TextStyle(color: colors.onSurface)),
        ],
      ),
    );
  }

  Future<void> _respond(String decision) async {
    final Map<String, dynamic>? booking = _booking;
    if (booking == null || _appointment == null || _reportDue == null) {
      _toast('Choose an appointment and a report time.');
      return;
    }
    await _run(() {
      return ref.read(inspectorAuthRemoteProvider).respond(widget.token, <String, dynamic>{
        'decision': decision,
        'inspectorId': booking['requestedInspectorId'],
        'appointmentAt': _appointment!.toUtc().toIso8601String(),
        'reportDueAt': _reportDue!.toUtc().toIso8601String(),
        'note': _note.text.trim(),
      });
    });
  }

  Future<void> _decline() async {
    final String? reason = await _ask('Decline this request', 'Reason for the buyer');
    if (reason == null || reason.trim().isEmpty) return;
    await _run(() {
      return ref.read(inspectorAuthRemoteProvider).respond(widget.token, <String, dynamic>{
        'decision': 'decline',
        'reason': reason.trim(),
      });
    });
  }

  Future<void> _complete() async {
    final DateTime? appointment = DateTime.tryParse(
      '${_map(_booking?['quote'])['appointmentAt'] ?? ''}',
    );
    final bool early = appointment != null && appointment.isAfter(DateTime.now());
    if (early) {
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Appointment time not reached'),
            content: const Text(
              'Both you and the buyer must approve before it is marked complete.',
            ),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ask the buyer to approve'),
              ),
            ],
          );
        },
      );
      if (ok != true) return;
    }
    await _run(() {
      return ref.read(inspectorAuthRemoteProvider).complete(widget.token, <String, dynamic>{
        'outcome': 'completed',
        if (early) 'confirmEarly': true,
      });
    });
  }

  Future<void> _couldNotProceed() async {
    final String? reason = await _ask('Could not proceed', 'What stopped the inspection?');
    if (reason == null || reason.trim().isEmpty) return;
    await _run(() {
      return ref.read(inspectorAuthRemoteProvider).complete(widget.token, <String, dynamic>{
        'outcome': 'could_not_proceed',
        'reason': reason.trim(),
      });
    });
  }

  Future<void> _upload(Map<String, dynamic> property) async {
    if (_license.text.trim().isEmpty) {
      _toast('Enter the license number printed on the report.');
      return;
    }
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
    );
    final String? path = picked?.files.single.path;
    if (path == null || path.isEmpty) return;
    final String street = '${property['streetAddress'] ?? ''}'.split(';').first.trim();
    final DateTime? appointment = DateTime.tryParse(
      '${_map(_booking?['quote'])['appointmentAt'] ?? ''}',
    );
    await _run(() {
      return ref.read(inspectorAuthRemoteProvider).uploadReport(
            widget.token,
            path: path,
            street: street,
            licenseNumber: _license.text.trim(),
            inspectionDate: (appointment ?? DateTime.now()).toUtc().toIso8601String(),
          );
    });
    final Map<String, dynamic>? latest = _latestReport(_booking);
    if (latest?['status'] == 'correction_queue') {
      _toast(_holdMessage(latest));
    } else if (latest?['status'] == 'released') {
      _toast('Report sent to the buyer.');
    }
  }

  Future<void> _reviseDue() async {
    final DateTime? picked = await _pickWhen(DateTime.now().add(const Duration(days: 1)));
    if (picked == null) return;
    await _run(() {
      return ref.read(inspectorAuthRemoteProvider).reviseReportDue(widget.token, picked);
    });
  }

  Future<void> _cancel() async {
    final String? reason = await _ask('Cancel this booking', 'Reason for the buyer');
    if (reason == null || reason.trim().isEmpty) return;
    await _run(() {
      return ref.read(inspectorAuthRemoteProvider).cancel(widget.token, reason.trim());
    });
  }

  Future<String?> _ask(String title, String label) async {
    final TextEditingController controller = TextEditingController();
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(labelText: label),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
    return result;
  }

  Future<void> _pickAppointment(Map<String, dynamic> request) async {
    final DateTime? picked = await _pickWhen(_appointment ?? DateTime.now().add(const Duration(days: 1)));
    if (picked == null) return;
    setState(() {
      _appointment = picked;
      final DateTime? deadline = DateTime.tryParse('${request['reportDeadline'] ?? ''}');
      if (_reportDue == null || !_reportDue!.isAfter(picked)) {
        final DateTime nextDay = picked.add(const Duration(days: 1));
        _reportDue = deadline != null && deadline.isAfter(picked) && deadline.isBefore(nextDay)
            ? deadline
            : nextDay;
      }
    });
  }

  Future<void> _pickReportDue() async {
    final DateTime? picked = await _pickWhen(
      _reportDue ?? (_appointment ?? DateTime.now()).add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _reportDue = picked);
  }

  Future<DateTime?> _pickWhen(DateTime initial) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

Map<String, dynamic>? _latestReport(Map<String, dynamic>? booking) {
  final Object? report = booking?['report'];
  final Object? versions = report is Map ? report['versions'] : null;
  if (versions is! List || versions.isEmpty) return null;
  final Object? latest = versions.last;
  return latest is Map ? _map(latest) : null;
}

String _holdMessage(Map<String, dynamic>? version) {
  final String note = '${version?['note'] ?? ''}'.trim();
  if (note.isNotEmpty) return note;
  return 'The report was not sent to the buyer. The license number has to match the one on your profile.';
}

String _message(Object? error) {
  if (error is DioException) return ExceptionMapper.fromDio(error).message;
  if (error == null) return 'This link is no longer valid.';
  return error.toString().replaceFirst('Exception: ', '');
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((dynamic key, dynamic item) => MapEntry('$key', item));
  }
  return <String, dynamic>{};
}

String _when(Object? iso) {
  if (iso is DateTime) return DateFormat('MMM d, y · h:mm a').format(iso.toLocal());
  final DateTime? date = DateTime.tryParse('$iso');
  if (date == null) return '';
  return DateFormat('MMM d, y · h:mm a').format(date.toLocal());
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
    case 'declined':
      return 'Declined';
    case 'expired':
      return 'Expired';
    case 'cancelled':
      return 'Cancelled';
    default:
      return state.replaceAll('_', ' ');
  }
}

String _services(Object? value) {
  const Map<String, String> labels = <String, String>{
    'general': 'Standard home inspection',
  };
  if (value is! List || value.isEmpty) return 'Standard home inspection';
  return value.map((dynamic item) => labels['$item'] ?? '$item').join(', ');
}

String _home(Map<String, dynamic> property) {
  final String size = property['livingArea'] == null
      ? 'Size unknown'
      : '${property['livingArea']} sq ft';
  final String year = property['yearBuilt'] == null ? '' : ' · built ${property['yearBuilt']}';
  return '$size$year';
}

String _windows(Object? value) {
  if (value is! List || value.isEmpty) return 'None given';
  return value.whereType<Map>().map((Map window) {
    return '${window['date'] ?? ''} ${window['start'] ?? ''}–${window['end'] ?? ''}'.trim();
  }).where((String line) => line.isNotEmpty).join('\n');
}

String _buyer(Map<String, dynamic> contact) {
  final String name = '${contact['name'] ?? ''}'.trim();
  final String email = '${contact['email'] ?? ''}'.trim();
  final String phone = '${contact['phone'] ?? ''}'.trim();
  final String details = <String>[name, email, phone].where((String part) => part.isNotEmpty).join('\n');
  if (email.isEmpty && phone.isEmpty) {
    return details.isEmpty
        ? 'Contact details are shared once the buyer confirms.'
        : '$details\nContact details are shared once the buyer confirms.';
  }
  return details;
}

String _money(Object? cents) {
  final num? value = cents is num ? cents : num.tryParse('$cents');
  if (value == null || value <= 0) return '';
  final bool whole = value % 100 == 0;
  return '\$${(value / 100).toStringAsFixed(whole ? 0 : 2)}';
}

DateTime? _defaultAppointment(Map<String, dynamic> booking) {
  final Object? windows = _map(booking['request'])['preferredWindows'];
  if (windows is List && windows.isNotEmpty && windows.first is Map) {
    final Map window = windows.first as Map;
    final DateTime? date = DateTime.tryParse('${window['date']}');
    final List<String> start = '${window['start'] ?? ''}'.split(':');
    if (date != null && start.length >= 2) {
      final int? hour = int.tryParse(start[0]);
      final int? minute = int.tryParse(start[1]);
      if (hour != null && minute != null) {
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
    }
  }
  final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
  return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
}

DateTime? _defaultReportDue(Map<String, dynamic> booking, DateTime? appointment) {
  final DateTime? deadline = DateTime.tryParse(
    '${_map(booking['request'])['reportDeadline'] ?? ''}',
  );
  if (appointment == null) return deadline;
  if (deadline != null && deadline.isAfter(appointment)) return deadline;
  return appointment.add(const Duration(days: 1));
}
