import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../domain/models/property_action.dart';
import '../controllers/offers_controller.dart';
import '../widgets/offer_form_fields.dart';

class OfferSummaryPage extends ConsumerStatefulWidget {
  const OfferSummaryPage({super.key, required this.actionId});

  final String actionId;

  @override
  ConsumerState<OfferSummaryPage> createState() => _OfferSummaryPageState();
}

class _OfferSummaryPageState extends ConsumerState<OfferSummaryPage> {
  bool _editing = false;
  bool _saving = false;
  OfferPdfForm? _form;
  String? _documentPath;
  OfferPdfKind _preview = OfferPdfKind.branded;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<OffersViewData> async = ref.watch(offersControllerProvider);
    final PropertyAction? row = async.valueOrNull?.byId(widget.actionId);
    final OfferPdfForm form = _form ??
        (row == null ? OfferPdfForm.empty() : OfferPdfForm.fromRow(row));

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit PDF' : 'Offer summary'),
        actions: DashboardAppBarActions.of(),
      ),
      body: row == null
          ? Center(
              child: async.isLoading
                  ? const Text('Loading offers…')
                  : const Text('Offer not found.'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: <Widget>[
                Text(
                  row.streetLine,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_editing)
                  OfferFormFields(
                    key: ValueKey<String>('edit-${row.id}'),
                    form: form,
                    documentPath: _documentPath,
                    documentLabel: row.offer?.documentName,
                    pdfHelper:
                        'Leave empty to regenerate the MangoLiving PDF from the fields above.',
                    onChanged: (OfferPdfForm next) => setState(() => _form = next),
                    onDocumentChanged: (String? path) =>
                        setState(() => _documentPath = path),
                  )
                else
                  _ReadFacts(row: row),
                const SizedBox(height: AppSpacing.lg),
                if (!_editing) _PdfSection(row: row, kind: _preview, onKind: (OfferPdfKind k) {
                  setState(() => _preview = k);
                }),
                const SizedBox(height: AppSpacing.lg),
                ..._footer(row, form),
              ],
            ),
    );
  }

  List<Widget> _footer(PropertyAction row, OfferPdfForm form) {
    if (_editing) {
      return <Widget>[
        OutlinedButton(
          onPressed: _saving ? null : () => setState(() => _editing = false),
          child: const Text('Cancel'),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          onPressed: _saving ? null : () => _save(row, form),
          child: Text(_saving ? 'Updating PDF…' : 'Save PDF'),
        ),
      ];
    }
    return <Widget>[
      if (row.canEditPdf)
        FilledButton(
          onPressed: () {
            setState(() {
              _form = OfferPdfForm.fromRow(row);
              _editing = true;
            });
          },
          child: const Text('Edit PDF'),
        ),
      if (row.canMarkDecision) ...<Widget>[
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: row.id.isEmpty ? null : () => _mark(row, accepted: false),
          child: const Text('Mark rejected'),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          onPressed: () => _mark(row, accepted: true),
          child: const Text('Mark accepted'),
        ),
      ] else ...<Widget>[
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => context.pop(),
          child: const Text('Close'),
        ),
      ],
    ];
  }

  Future<void> _save(PropertyAction row, OfferPdfForm form) async {
    final String? amountError = form.amountError;
    if (amountError != null) {
      _toast(amountError, error: true);
      return;
    }
    final String? daysError = form.daysError;
    if (daysError != null) {
      _toast(daysError, error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(offersControllerProvider.notifier).sendOffer(
            id: row.id,
            form: form,
            documentPath: _documentPath,
          );
      if (!mounted) return;
      setState(() {
        _editing = false;
        _documentPath = null;
      });
      _toast('PDF updated');
    } on Object catch (error) {
      if (mounted) _toast(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _mark(PropertyAction row, {required bool accepted}) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            accepted
                ? 'Tell ${row.buyerName} the offer was accepted?'
                : 'Let ${row.buyerName} know the offer was rejected?',
          ),
          content: Text(
            accepted
                ? "They'll see good news on ${row.streetLine}."
                : "They'll still see ${row.streetLine}, with a note that the offer didn't go through.",
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: accepted
                  ? null
                  : FilledButton.styleFrom(backgroundColor: AppColors.destructive),
              onPressed: () => Navigator.pop(context, true),
              child: Text(accepted ? 'Yes, accepted' : 'Yes, rejected'),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    try {
      if (accepted) {
        await ref.read(offersControllerProvider.notifier).markAccepted(row.id);
        if (mounted) _toast('Offer marked accepted');
      } else {
        await ref.read(offersControllerProvider.notifier).markRejected(row.id);
        if (mounted) _toast('Offer marked rejected');
      }
      if (mounted) context.pop();
    } on Object catch (error) {
      if (mounted) _toast(error.toString(), error: true);
    }
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.destructive : null,
      ),
    );
  }
}

class _ReadFacts extends StatelessWidget {
  const _ReadFacts({required this.row});

  final PropertyAction row;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            Chip(label: Text(row.amountLabel)),
            Chip(
              label: Text(row.offer?.offerStatus?.label ?? '—'),
              side: BorderSide(color: theme.colorScheme.outline),
              backgroundColor: Colors.transparent,
            ),
            Text(
              '${row.offer?.inspectionPeriodDays ?? 7}-day inspection',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _Fact(
          label: 'Buyer',
          value: row.offer?.pdfDocument?.buyerName ?? row.buyerName,
        ),
        _Fact(
          label: 'Prepared by',
          value: row.offer?.preparedByName ?? row.agentName ?? '—',
        ),
        _Fact(
          label: 'List price',
          value: OfferMoney.format(row.offer?.listPrice ?? row.property?.listPrice),
        ),
        _Fact(label: 'Sent', value: row.sentLabel),
        _Fact(label: 'Notes', value: row.offer?.notes ?? '—'),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfSection extends StatelessWidget {
  const _PdfSection({
    required this.row,
    required this.kind,
    required this.onKind,
  });

  final PropertyAction row;
  final OfferPdfKind kind;
  final ValueChanged<OfferPdfKind> onKind;

  @override
  Widget build(BuildContext context) {
    final String? branded = row.offer?.brandedResolvedUrl;
    final String? attached = row.offer?.attachedResolvedUrl;
    if (branded == null && attached == null) {
      return const Text('No PDF yet. Edit the PDF to create one.');
    }
    final String? url =
        kind == OfferPdfKind.attached ? (attached ?? branded) : (branded ?? attached);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (branded != null && attached != null)
          SegmentedButton<OfferPdfKind>(
            segments: const <ButtonSegment<OfferPdfKind>>[
              ButtonSegment<OfferPdfKind>(
                value: OfferPdfKind.branded,
                label: Text('MangoLiving PDF'),
              ),
              ButtonSegment<OfferPdfKind>(
                value: OfferPdfKind.attached,
                label: Text('Attached PDF'),
              ),
            ],
            selected: <OfferPdfKind>{kind},
            onSelectionChanged: (Set<OfferPdfKind> next) => onKind(next.first),
          ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.tonalIcon(
          onPressed: url == null
              ? null
              : () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(
            kind == OfferPdfKind.attached ? 'Open attached PDF' : 'Open MangoLiving PDF',
          ),
        ),
      ],
    );
  }
}
