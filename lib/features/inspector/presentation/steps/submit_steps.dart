import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/app_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/inspector_catalog.dart';
import '../../domain/inspector_quote.dart';
import '../../domain/models/inspector_draft.dart';
import '../controllers/inspector_flow_controller.dart';
import '../inspector_navigation.dart';
import '../widgets/inspector_chrome.dart';

class QuotePreviewStep extends ConsumerStatefulWidget {
  const QuotePreviewStep({super.key});

  @override
  ConsumerState<QuotePreviewStep> createState() => _QuotePreviewStepState();
}

class _QuotePreviewStepState extends ConsumerState<QuotePreviewStep> {
  late final TextEditingController _year;
  late final TextEditingController _size;
  String? _error;

  @override
  void initState() {
    super.initState();
    final InspectorDraft draft =
        ref.read(inspectorFlowControllerProvider).requireValue;
    _year = TextEditingController(text: draft.previewYear);
    _size = TextEditingController(text: draft.previewSqFt);
  }

  @override
  void dispose() {
    _year.dispose();
    _size.dispose();
    super.dispose();
  }

  void _continue() {
    final InspectorQuote? quote = ref.read(inspectorQuoteProvider).valueOrNull;
    if (quote == null || !quote.ready) {
      setState(() => _error = 'Enter a year built and home size to preview the price.');
      return;
    }
    ref.read(inspectorFlowControllerProvider.notifier).go(InspectorStep.availability);
  }

  @override
  Widget build(BuildContext context) {
    final InspectorDraft draft =
        ref.watch(inspectorFlowControllerProvider).requireValue;
    final InspectorQuote? quote = ref.watch(inspectorQuoteProvider).valueOrNull;
    final InspectorPalette palette = InspectorPalette.of(context);
    final List<HomeType> types = draft.selectedHomeTypes;
    final HomeType selected = types.contains(draft.previewHomeType)
        ? draft.previewHomeType
        : (types.isEmpty ? HomeType.singleFamily : types.first);
    final List<AddOnOffer> offered =
        draft.addOns.where((AddOnOffer addOn) => addOn.enabled).toList();

    return InspectorStepScaffold(
      step: 1,
      total: 4,
      title: 'Preview a quote',
      subtitle: 'Review the details and estimated price.',
      error: _error,
      actionLabel: 'Continue to availability',
      onAction: _continue,
      children: <Widget>[
        if (types.isEmpty)
          const Text('Choose a home type on the coverage step.')
        else
          DropdownButtonFormField<HomeType>(
            key: ValueKey<HomeType>(selected),
            initialValue: selected,
            decoration: const InputDecoration(labelText: 'Home type'),
            items: <DropdownMenuItem<HomeType>>[
              for (final HomeType type in types)
                DropdownMenuItem<HomeType>(value: type, child: Text(type.label)),
            ],
            onChanged: (HomeType? value) {
              if (value == null) return;
              ref.read(inspectorFlowControllerProvider.notifier).patch(
                    (InspectorDraft current) =>
                        current.copyWith(previewHomeType: value),
                  );
            },
          ),
        const SizedBox(height: 12),
        InspectorField(
          label: 'Year built',
          controller: _year,
          hint: '1998',
          keyboardType: TextInputType.number,
          onChanged: (String value) => ref
              .read(inspectorFlowControllerProvider.notifier)
              .patch((InspectorDraft current) => current.copyWith(previewYear: value)),
        ),
        InspectorField(
          label: 'Home size',
          controller: _size,
          hint: '2,800',
          helper: 'Square feet',
          keyboardType: TextInputType.number,
          onChanged: (String value) => ref
              .read(inspectorFlowControllerProvider.notifier)
              .patch((InspectorDraft current) => current.copyWith(previewSqFt: value)),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Selected add-ons',
                style: TextStyle(fontWeight: FontWeight.w800, color: palette.ink),
              ),
            ),
            TextButton(
              onPressed: () => ref
                  .read(inspectorFlowControllerProvider.notifier)
                  .go(InspectorStep.addonsPest),
              child: const Text('Change add-ons'),
            ),
          ],
        ),
        if (offered.isEmpty)
          Text(
            'Turn on add-ons to include them in a quote.',
            style: TextStyle(color: palette.muted),
          ),
        for (final AddOnOffer addOn in offered)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: draft.previewAddOnIds.contains(addOn.id),
            activeColor: AppColors.primary,
            title: Text(addOn.name),
            secondary: Text(
              addOn.method == PricingMethod.requestQuote || addOn.priceUsd == null
                  ? 'Request quote'
                  : formatUsd(addOn.priceUsd!),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (bool? value) {
              ref.read(inspectorFlowControllerProvider.notifier).patch(
                    (InspectorDraft current) {
                      final Set<String> next = <String>{...current.previewAddOnIds};
                      if (value ?? false) {
                        next.add(addOn.id);
                      } else {
                        next.remove(addOn.id);
                      }
                      return current.copyWith(previewAddOnIds: next);
                    },
                  );
            },
          ),
        const Divider(height: 28),
        if (quote == null || !quote.ready)
          Text(
            'Enter a year built and home size to see the buyer price.',
            style: TextStyle(color: palette.muted),
          )
        else ...<Widget>[
          _PriceLine(
            title: 'Base inspection',
            detail: quote.bandLabel == null
                ? '30-item scope · ${quote.yearGroup?.label ?? ''}'
                : '30-item scope · ${quote.yearGroup?.label ?? ''}\n${quote.bandLabel} sq. ft.',
            amount: quote.requestQuote && quote.basePrice == null
                ? 'Request quote'
                : formatUsd(quote.basePrice ?? 0),
          ),
          for (final QuoteLine line in quote.addOns)
            _PriceLine(
              title: line.name,
              amount: line.requestQuote ? 'Request quote' : formatUsd(line.priceUsd ?? 0),
            ),
          const SizedBox(height: 8),
          Text(
            'Inspection subtotal',
            style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700),
          ),
          Text(
            quote.requestQuote || quote.subtotal == null
                ? 'Request quote'
                : formatUsd(quote.subtotal!),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
        const InspectorNote(
          text: 'Base price + selected add-ons. Preview only. No booking is created.',
        ),
      ],
    );
  }
}

class AvailabilityStep extends ConsumerWidget {
  const AvailabilityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InspectorDraft draft =
        ref.watch(inspectorFlowControllerProvider).requireValue;
    final InspectorPalette palette = InspectorPalette.of(context);
    return InspectorStepScaffold(
      step: 2,
      total: 4,
      title: 'When can you inspect?',
      subtitle: 'Set your typical availability for inspections.',
      actionLabel: 'Review application',
      onAction: () {
        if (draft.availableDays.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select at least one available day.')),
          );
          return;
        }
        ref.read(inspectorFlowControllerProvider.notifier).go(InspectorStep.review);
      },
      children: <Widget>[
        Text(
          'Available days',
          style: TextStyle(fontWeight: FontWeight.w800, color: palette.ink),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for (int day = 0; day < 7; day++)
              _DayDot(
                label: const <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'][day],
                selected: draft.availableDays.contains(day),
                onTap: () {
                  ref.read(inspectorFlowControllerProvider.notifier).patch(
                        (InspectorDraft current) {
                          final Set<int> next = <int>{...current.availableDays};
                          if (!next.add(day)) next.remove(day);
                          return current.copyWith(availableDays: next);
                        },
                      );
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Available hours',
          style: TextStyle(fontWeight: FontWeight.w800, color: palette.ink),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: InspectorDropdown<String>(
                label: 'Start',
                value: draft.startTime,
                hint: '8:00 AM',
                items: inspectionTimes,
                onChanged: (String? value) {
                  if (value == null) return;
                  ref.read(inspectorFlowControllerProvider.notifier).patch(
                        (InspectorDraft current) =>
                            current.copyWith(startTime: value),
                      );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InspectorDropdown<String>(
                label: 'End',
                value: draft.endTime,
                hint: '5:00 PM',
                items: inspectionTimes,
                onChanged: (String? value) {
                  if (value == null) return;
                  ref.read(inspectorFlowControllerProvider.notifier).patch(
                        (InspectorDraft current) => current.copyWith(endTime: value),
                      );
                },
              ),
            ),
          ],
        ),
        InspectorDropdown<String>(
          label: 'Minimum notice',
          value: draft.minimumNotice,
          hint: '24 hours',
          items: noticeOptions,
          onChanged: (String? value) {
            if (value == null) return;
            ref.read(inspectorFlowControllerProvider.notifier).patch(
                  (InspectorDraft current) =>
                      current.copyWith(minimumNotice: value),
                );
          },
        ),
        Text(
          'Booking preference',
          style: TextStyle(fontWeight: FontWeight.w800, color: palette.ink),
        ),
        const SizedBox(height: 8),
        for (final BookingPreference preference in BookingPreference.values)
          InspectorChoiceCard(
            title: preference.label,
            detail: preference.detail,
            selected: draft.bookingPreference == preference,
            onTap: () => ref.read(inspectorFlowControllerProvider.notifier).patch(
                  (InspectorDraft current) =>
                      current.copyWith(bookingPreference: preference),
                ),
          ),
        OutlinedButton.icon(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            disabledForegroundColor: palette.muted,
            side: BorderSide(color: palette.line),
          ),
          icon: const Icon(Icons.calendar_month),
          label: const Text('Connect calendar'),
        ),
        Text(
          'Calendar connection isn’t available yet.',
          style: TextStyle(color: palette.muted, fontSize: 12),
        ),
        const InspectorNote(
          text: 'Selected add-ons can extend appointment time.',
        ),
      ],
    );
  }
}

class ReviewSubmitStep extends ConsumerWidget {
  const ReviewSubmitStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InspectorDraft draft =
        ref.watch(inspectorFlowControllerProvider).requireValue;
    final InspectorPalette palette = InspectorPalette.of(context);
    final int scopeCount = draft.includedScopeIds.length;
    final String photoPath = draft.photoPath?.trim() ?? '';
    final bool hasPhoto = photoPath.isNotEmpty;

    return InspectorStepScaffold(
      step: 3,
      total: 4,
      title: 'Ready to go live?',
      subtitle: 'Double-check your services, rates, and details. Submitting approves you right away.',
      actionLabel: 'Go live',
      onAction: () => _submit(context, ref, draft),
      children: <Widget>[
        Row(
          children: <Widget>[
            CircleAvatar(
              radius: 24,
              backgroundColor: palette.orangeSoft,
              backgroundImage: hasPhoto ? FileImage(File(photoPath)) : null,
              child: hasPhoto
                  ? null
                  : Text(
                      _initials(draft.fullName),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    draft.fullName.isEmpty ? 'Your name' : draft.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    draft.businessName.isEmpty
                        ? 'Business name'
                        : draft.businessName,
                    style: TextStyle(color: palette.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ReviewRow(
          title: 'Business and credentials',
          detail: draft.licenseFileName != null && draft.insuranceFileName != null
              ? 'Profile complete · Documents uploaded'
              : 'Documents still needed',
          onEdit: () => editSection(ref, step: InspectorStep.business),
        ),
        _ReviewRow(
          title: 'Coverage',
          detail: draft.serviceAreas.isEmpty
              ? 'No service areas yet'
              : draft.serviceAreas.join(', '),
          onEdit: () => editSection(ref, step: InspectorStep.coverage),
        ),
        _ReviewRow(
          title: 'Base inspection scope',
          detail: '$scopeCount items confirmed',
          onEdit: () => editSection(ref, step: InspectorStep.scopeStructure),
        ),
        _ReviewRow(
          title: 'Base pricing',
          detail: draft.pricingComplete
              ? '${draft.selectedHomeTypes.length} home types · 2 year groups'
              : 'Finish every home type',
          onEdit: () => editSection(ref, step: InspectorStep.pricingTypes),
        ),
        _ReviewRow(
          title: 'Optional add-ons',
          detail: '${draft.enabledAddOnCount} configured · Separate prices',
          onEdit: () => editSection(ref, step: InspectorStep.addonsPest),
        ),
        _ReviewRow(
          title: 'Availability',
          detail: _availability(draft),
          onEdit: () => editSection(ref, step: InspectorStep.availability),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: draft.confirmedAccurate,
          activeColor: AppColors.primary,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('I confirm my services and prices are accurate.'),
          onChanged: (bool? value) {
            ref.read(inspectorFlowControllerProvider.notifier).patch(
                  (InspectorDraft current) =>
                      current.copyWith(confirmedAccurate: value ?? false),
                );
          },
        ),
        const InspectorNote(
          text: 'There is no review wait. Submitting approves your profile so buyers can book you.',
        ),
      ],
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    InspectorDraft draft,
  ) async {
    if (!draft.confirmedAccurate) {
      _snack(context, 'Confirm that your services and prices are accurate.');
      return;
    }
    if (draft.fullName.trim().isEmpty || draft.businessName.trim().isEmpty) {
      _snack(context, 'Add your name and business before submitting.');
      return;
    }
    if (draft.licenseFileName == null || draft.insuranceFileName == null) {
      _snack(context, 'Upload your license and insurance before submitting.');
      return;
    }
    if (draft.serviceAreas.isEmpty || draft.homeTypes.isEmpty) {
      _snack(context, 'Add a service area and at least one home type.');
      return;
    }
    if (!draft.pricingComplete) {
      _snack(context, 'Finish base pricing for every home type before submitting.');
      return;
    }
    if (draft.includedScopeIds.isEmpty) {
      _snack(context, 'Include at least one base inspection item.');
      return;
    }
    if (draft.password.length < 8) {
      _snack(context, 'Set a password of at least 8 characters on the first step.');
      return;
    }
    if (draft.mobile.replaceAll(RegExp(r'\D'), '').length != 10) {
      _snack(context, 'Enter a 10-digit mobile number on the first step.');
      return;
    }
    try {
      await ref.read(inspectorFlowControllerProvider.notifier).submit();
    } catch (error) {
      if (!context.mounted) return;
      final String message = error is DioException
          ? ExceptionMapper.fromDio(error).message
          : error.toString().replaceFirst('Exception: ', '');
      _snack(
        context,
        message.isEmpty ? 'Could not publish your inspector profile.' : message,
      );
    }
  }
}

class ApplicationStatusStep extends ConsumerWidget {
  const ApplicationStatusStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InspectorDraft draft =
        ref.watch(inspectorFlowControllerProvider).requireValue;
    final InspectorPalette palette = InspectorPalette.of(context);
    final String received = draft.submittedAt == null
        ? 'Just now'
        : DateFormat('MMM d, y, h:mm a').format(draft.submittedAt!.toLocal());

    final bool live = draft.status == ApplicationStatus.live;
    return InspectorStepScaffold(
      step: 4,
      total: 4,
      title: live ? 'You’re approved' : 'Application submitted',
      actionLabel: live ? 'Open requests inbox' : 'View application',
      onAction: () {
        if (live) {
          context.go(AppRoutes.inspectorHome);
          return;
        }
        ref
            .read(inspectorFlowControllerProvider.notifier)
            .go(InspectorStep.review);
      },
      secondaryLabel: 'Edit application',
      onSecondary: () {
        ref.read(inspectorFlowControllerProvider.notifier).patch(
              (InspectorDraft current) => current.copyWith(
                status: ApplicationStatus.draft,
                step: InspectorStep.review,
                confirmedAccurate: false,
                clearReturnTo: true,
              ),
            );
      },
      children: <Widget>[
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: const Icon(Icons.check, color: AppColors.primary, size: 40),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.orangeSoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                draft.status == ApplicationStatus.live ? 'Approved' : 'Under review',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          draft.status == ApplicationStatus.live
              ? 'Your inspector profile is approved. Buyers can see you in the shortlist and send requests now.'
              : "We'll notify you when your application is approved or needs an update.",
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.muted, height: 1.4),
        ),
        const SizedBox(height: 20),
        _StatusRow(
          title: 'Application received',
          detail: received,
          caption: draft.status == ApplicationStatus.live
              ? 'Your profile was saved to MangoLiving.'
              : 'Your application has been submitted.',
          state: _StatusState.done,
        ),
        _StatusRow(
          title: draft.status == ApplicationStatus.live
              ? 'Visible in buyer booking'
              : 'Credentials, services and pricing review',
          detail: draft.status == ApplicationStatus.live ? 'Live' : 'In progress',
          caption: draft.status == ApplicationStatus.live
              ? 'Eligible buyers in your service area can request you.'
              : "We're reviewing your information.",
          state: _StatusState.current,
        ),
        _StatusRow(
          title: draft.status == ApplicationStatus.live
              ? 'Ready for requests'
              : 'Ready to activate',
          detail: draft.status == ApplicationStatus.live ? 'Done' : 'Pending',
          caption: draft.status == ApplicationStatus.live
              ? 'Keep your availability and prices up to date.'
              : "You'll be notified once approved.",
          state: draft.status == ApplicationStatus.live
              ? _StatusState.done
              : _StatusState.pending,
        ),
        InspectorNote(
          text: draft.status == ApplicationStatus.live
              ? 'Buyers can request you now. Connect payouts before you accept paid bookings.'
              : 'Your profile is not live yet.',
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_balance_outlined),
          title: const Text('Prepare payout details'),
          subtitle: const Text('Complete before receiving payments'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Payout setup comes next after inspector login.',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.title,
    required this.amount,
    this.detail,
  });

  final String title;
  final String amount;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final InspectorPalette palette = InspectorPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (detail != null)
                  Text(detail!, style: TextStyle(color: palette.muted)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.primary : const Color(0xFFF3F3F5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.title,
    required this.detail,
    required this.onEdit,
  });

  final String title;
  final String detail;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final InspectorPalette palette = InspectorPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, color: Color(0xFF16803C), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(detail, style: TextStyle(color: palette.muted)),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text('Edit')),
        ],
      ),
    );
  }
}

enum _StatusState { done, current, pending }

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.title,
    required this.detail,
    required this.caption,
    required this.state,
  });

  final String title;
  final String detail;
  final String caption;
  final _StatusState state;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (state) {
      _StatusState.done => const Color(0xFF16803C),
      _StatusState.current => AppColors.primary,
      _StatusState.pending => const Color(0xFFB4B4B4),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            state == _StatusState.pending
                ? Icons.circle_outlined
                : Icons.check_circle,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(detail, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                Text(caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _initials(String name) {
  final List<String> parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((String part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'ML';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _availability(InspectorDraft draft) {
  const List<String> names = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final List<int> days = draft.availableDays.toList()..sort();
  final String dayLabel = days.length == 5 &&
          days.every((int day) => day < 5)
      ? 'Mon–Fri'
      : days.map((int day) => names[day]).join(', ');
  return '$dayLabel, ${draft.startTime}–${draft.endTime}';
}
