import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/models/property_action.dart';

class OfferFormFields extends StatefulWidget {
  const OfferFormFields({
    super.key,
    required this.form,
    required this.onChanged,
    this.documentPath,
    this.documentLabel,
    this.onDocumentChanged,
    this.pdfHelper =
        "Attach Jane’s offer file if you have one. We’ll also create a MangoLiving branded PDF.",
  });

  final OfferPdfForm form;
  final ValueChanged<OfferPdfForm> onChanged;
  final String? documentPath;
  final String? documentLabel;
  final ValueChanged<String?>? onDocumentChanged;
  final String pdfHelper;

  @override
  State<OfferFormFields> createState() => _OfferFormFieldsState();
}

class _OfferFormFieldsState extends State<OfferFormFields> {
  late final TextEditingController _buyer;
  late final TextEditingController _prepared;
  late final TextEditingController _street;
  late final TextEditingController _city;
  late final TextEditingController _province;
  late final TextEditingController _postal;
  late final TextEditingController _amount;
  late final TextEditingController _list;
  late final TextEditingController _days;
  late final TextEditingController _inspection;
  late final TextEditingController _notes;
  late final TextEditingController _closing;

  @override
  void initState() {
    super.initState();
    final OfferPdfForm form = widget.form;
    _buyer = TextEditingController(text: form.buyerName);
    _prepared = TextEditingController(text: form.preparedByName);
    _street = TextEditingController(text: form.streetAddress);
    _city = TextEditingController(text: form.city);
    _province = TextEditingController(text: form.province);
    _postal = TextEditingController(text: form.postalCode);
    _amount = TextEditingController(text: form.offerAmount);
    _list = TextEditingController(text: form.listPrice);
    _days = TextEditingController(text: form.inspectionPeriodDays);
    _inspection = TextEditingController(text: form.inspectionText);
    _notes = TextEditingController(text: form.notes);
    _closing = TextEditingController(text: form.closingText);
  }

  @override
  void dispose() {
    _buyer.dispose();
    _prepared.dispose();
    _street.dispose();
    _city.dispose();
    _province.dispose();
    _postal.dispose();
    _amount.dispose();
    _list.dispose();
    _days.dispose();
    _inspection.dispose();
    _notes.dispose();
    _closing.dispose();
    super.dispose();
  }

  void _emit(OfferPdfForm next) {
    if (next.inspectionText != _inspection.text) {
      _inspection.text = next.inspectionText;
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? section = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('PEOPLE', style: section),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _buyer,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Buyer name'),
          onChanged: (String v) => _emit(widget.form.copyWith(buyerName: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _prepared,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Prepared by'),
          onChanged: (String v) => _emit(widget.form.copyWith(preparedByName: v)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('PROPERTY', style: section),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _street,
          decoration: const InputDecoration(labelText: 'Street'),
          onChanged: (String v) => _emit(widget.form.copyWith(streetAddress: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _city,
          decoration: const InputDecoration(labelText: 'City'),
          onChanged: (String v) => _emit(widget.form.copyWith(city: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _province,
          decoration: const InputDecoration(labelText: 'State'),
          onChanged: (String v) => _emit(widget.form.copyWith(province: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _postal,
          decoration: const InputDecoration(labelText: 'ZIP'),
          onChanged: (String v) => _emit(widget.form.copyWith(postalCode: v)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('PRICE AND DATE', style: section),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Offer amount'),
          onChanged: (String v) => _emit(widget.form.copyWith(offerAmount: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _list,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'List price'),
          onChanged: (String v) => _emit(widget.form.copyWith(listPrice: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Effective date'),
          subtitle: Text(
            widget.form.effectiveDate.isEmpty
                ? 'Not set'
                : widget.form.effectiveDate,
          ),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: () async {
            final DateTime now = DateTime.now();
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(widget.form.effectiveDate) ?? now,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 3),
            );
            if (picked == null) return;
            _emit(
              widget.form.copyWith(
                effectiveDate: picked.toIso8601String().substring(0, 10),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _days,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Inspection period days'),
          onChanged: (String v) => _emit(widget.form.withInspectionDays(v)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('TERMS', style: section),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _inspection,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Inspection text'),
          onChanged: (String v) => _emit(widget.form.copyWith(inspectionText: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _notes,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Notes'),
          onChanged: (String v) => _emit(widget.form.copyWith(notes: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _closing,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Closing text'),
          onChanged: (String v) => _emit(widget.form.copyWith(closingText: v)),
        ),
        if (widget.onDocumentChanged != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: theme.colorScheme.outline,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Offer PDF (optional)'),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Attach PDF'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _fileHelper,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String get _fileHelper {
    final String selected = widget.documentPath?.split('/').last ?? '';
    if (selected.isNotEmpty) {
      return '${widget.pdfHelper} Selected: $selected';
    }
    if ((widget.documentLabel ?? '').isNotEmpty) {
      return '${widget.pdfHelper} Current file: ${widget.documentLabel}';
    }
    return widget.pdfHelper;
  }

  Future<void> _pickPdf() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
    );
    final String? path = result?.files.single.path;
    widget.onDocumentChanged?.call(path);
  }
}
