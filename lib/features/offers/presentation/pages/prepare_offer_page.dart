import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../domain/models/property_action.dart';
import '../controllers/offers_controller.dart';
import '../widgets/offer_form_fields.dart';

class PrepareOfferPage extends ConsumerStatefulWidget {
  const PrepareOfferPage({super.key, required this.actionId});

  final String actionId;

  @override
  ConsumerState<PrepareOfferPage> createState() => _PrepareOfferPageState();
}

class _PrepareOfferPageState extends ConsumerState<PrepareOfferPage> {
  OfferPdfForm? _form;
  String? _documentPath;
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<OffersViewData> async = ref.watch(offersControllerProvider);
    final PropertyAction? row = async.valueOrNull?.byId(widget.actionId);
    final OfferPdfForm form = _form ??
        (row == null ? OfferPdfForm.empty() : OfferPdfForm.fromRow(row));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prepare offer'),
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
                  '${row.streetLine} · ${row.buyerName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OfferFormFields(
                  key: ValueKey<String>('prepare-${row.id}'),
                  form: form,
                  documentPath: _documentPath,
                  documentLabel: row.offer?.documentName,
                  onChanged: (OfferPdfForm next) => setState(() => _form = next),
                  onDocumentChanged: (String? path) =>
                      setState(() => _documentPath = path),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _sending ? null : () => _send(row, form),
                  child: Text(_sending ? 'Sending…' : 'Send offer'),
                ),
              ],
            ),
    );
  }

  Future<void> _send(PropertyAction row, OfferPdfForm form) async {
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
    final num amount = num.parse(form.offerAmount.trim());
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Send this offer to ${row.buyerName}?'),
          content: Text(
            "We'll share ${OfferMoney.format(amount)} for ${row.streetLine} so they can review it.",
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send offer'),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    setState(() => _sending = true);
    try {
      await ref.read(offersControllerProvider.notifier).sendOffer(
            id: row.id,
            form: form,
            documentPath: _documentPath,
          );
      if (!mounted) return;
      _toast('Offer sent');
      context.pop();
    } on Object catch (error) {
      if (mounted) _toast(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
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
