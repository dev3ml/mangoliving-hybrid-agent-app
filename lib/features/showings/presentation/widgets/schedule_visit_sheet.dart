import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/models/showing_request.dart';

Future<DateTime?> showScheduleVisitSheet(
  BuildContext context, {
  required ShowingRequest request,
  required bool reschedule,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) {
      return ScheduleVisitSheet(request: request, reschedule: reschedule);
    },
  );
}

class ScheduleVisitSheet extends StatefulWidget {
  const ScheduleVisitSheet({
    super.key,
    required this.request,
    required this.reschedule,
  });

  final ShowingRequest request;
  final bool reschedule;

  @override
  State<ScheduleVisitSheet> createState() => _ScheduleVisitSheetState();
}

class _ScheduleVisitSheetState extends State<ScheduleVisitSheet> {
  DateTime? _date;
  TimeParts _time = ShowingSchedule.defaultTime;
  bool _submitting = false;
  bool _movedPastVisit = false;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    final DateTime? existing = widget.request.scheduledAtDate?.toLocal();
    final ({DateTime date, TimeParts time}) selection =
        ShowingSchedule.initialSelection(existing: existing, now: now);
    _date = selection.date;
    _time = selection.time;
    _movedPastVisit = existing != null && !existing.isAfter(now);
  }

  String? get _error {
    return ShowingSchedule.validate(
      date: _date,
      time: _time,
      now: DateTime.now(),
    );
  }

  bool get _dateIsToday {
    if (_date == null) return false;
    final DateTime now = DateTime.now();
    return _date!.year == now.year &&
        _date!.month == now.month &&
        _date!.day == now.day;
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime first = DateTime(now.year, now.month, now.day);
    final DateTime last = DateTime(now.year + 2);
    DateTime initial = _date ?? first;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final DateTime? next = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (next == null) return;
    setState(() => _date = next);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? next = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _time.hour, minute: _time.minute),
    );
    if (next == null) return;
    setState(() => _time = TimeParts(next.hour, next.minute));
  }

  void _confirm() {
    final String? error = _error;
    if (error != null) return;
    setState(() => _submitting = true);
    Navigator.of(context).pop(ShowingSchedule.combine(_date!, _time));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime? preview =
        _date == null ? null : ShowingSchedule.combine(_date!, _time);
    final bool pastOnToday =
        _date != null && ShowingSchedule.isPastOnDate(_date!, _time, DateTime.now());

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            widget.reschedule ? 'Reschedule a visit' : 'Schedule a visit',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Pick a date and time to tour ${widget.request.listingTitle}. The buyer will see the new visit time.',
            style: theme.textTheme.bodySmall,
          ),
          if (_movedPastVisit) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'The previous visit time has passed. A new time is filled in — change it if you want.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(
              _date == null
                  ? 'Pick a date'
                  : DateFormat.yMMMd().format(_date!),
            ),
            onTap: _submitting ? null : _pickDate,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(
              TimeOfDay(hour: _time.hour, minute: _time.minute).format(context),
            ),
            subtitle: _dateIsToday && pastOnToday
                ? Text(
                    'Must be in the future',
                    style: TextStyle(color: theme.colorScheme.error),
                  )
                : null,
            onTap: _submitting ? null : _pickTime,
          ),
          if (preview != null)
            Text(
              'Visit: ${TimeFormat.showingDate(preview.toIso8601String())}',
              style: theme.textTheme.titleSmall,
            ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _submitting || _error != null ? null : _confirm,
            child: Text(
              _submitting
                  ? 'Saving…'
                  : (widget.reschedule ? 'Save new time' : 'Confirm visit'),
            ),
          ),
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
