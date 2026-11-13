import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../account/domain/models/agent_profile.dart';
import '../../domain/inspector_catalog.dart';
import '../../domain/models/inspector_draft.dart';
import '../controllers/inspector_flow_controller.dart';
import '../widgets/inspector_chrome.dart';

class JoinAccountStep extends ConsumerStatefulWidget {
  const JoinAccountStep({super.key});

  @override
  ConsumerState<JoinAccountStep> createState() => _JoinAccountStepState();
}

class _JoinAccountStepState extends ConsumerState<JoinAccountStep> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _mobile;
  late final TextEditingController _password;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final InspectorDraft draft =
        ref.read(inspectorFlowControllerProvider).requireValue;
    _name = TextEditingController(text: draft.fullName);
    _email = TextEditingController(text: draft.email);
    _mobile = TextEditingController(text: draft.mobile);
    _password = TextEditingController(text: draft.password);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _password.dispose();
    super.dispose();
  }

  void _continue() {
    final InspectorDraft? draft =
        ref.read(inspectorFlowControllerProvider).valueOrNull;
    if (draft == null) return;
    final String email = draft.email.trim();
    final String mobileDigits = draft.mobile.replaceAll(RegExp(r'\D'), '');
    if (draft.fullName.trim().isEmpty ||
        email.isEmpty ||
        !email.contains('@') ||
        draft.password.isEmpty) {
      setState(() => _error = 'Enter your name, email, mobile number, and password.');
      return;
    }
    if (mobileDigits.length != 10) {
      setState(() => _error = 'Enter a 10-digit mobile number.');
      return;
    }
    if (draft.password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (!draft.acceptedTerms) {
      setState(() => _error = 'Agree to the provider terms and privacy policy.');
      return;
    }
    if (draft.mobile != mobileDigits) {
      ref.read(inspectorFlowControllerProvider.notifier).patch(
            (InspectorDraft current) => current.copyWith(mobile: mobileDigits),
          );
    }
    ref.read(inspectorFlowControllerProvider.notifier).go(InspectorStep.business);
  }

  @override
  Widget build(BuildContext context) {
    final InspectorDraft draft =
        ref.watch(inspectorFlowControllerProvider).requireValue;
    final InspectorPalette palette = InspectorPalette.of(context);
    return InspectorStepScaffold(
      step: 1,
      total: 4,
      title: 'Join MangoLiving',
      subtitle: 'Offer home inspections to buyers in your area.',
      error: _error,
      actionLabel: 'Create account',
      onAction: _continue,
      secondaryLabel: 'Already registered? Sign in',
      onSecondary: () => context.go(AppRoutes.inspectorLogin),
      children: <Widget>[
        InspectorField(
          label: 'Full name',
          controller: _name,
          hint: 'Alex Morgan',
          onChanged: (String value) => ref
              .read(inspectorFlowControllerProvider.notifier)
              .patch((InspectorDraft current) => current.copyWith(fullName: value)),
        ),
        InspectorField(
          label: 'Work email',
          controller: _email,
          hint: 'alex@example.com',
          keyboardType: TextInputType.emailAddress,
          onChanged: (String value) => ref
              .read(inspectorFlowControllerProvider.notifier)
              .patch((InspectorDraft current) => current.copyWith(email: value)),
        ),
        InspectorField(
          label: 'Mobile number',
          controller: _mobile,
          hint: '(555) 010-2040',
          keyboardType: TextInputType.phone,
          maxLength: 10,
          helper: '10-digit mobile number.',
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (String value) => ref
              .read(inspectorFlowControllerProvider.notifier)
              .patch((InspectorDraft current) => current.copyWith(mobile: value)),
        ),
        InspectorField(
          label: 'Password',
          controller: _password,
          hint: '••••••••',
          obscure: _obscure,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
          helper: 'At least 8 characters. Used to sign in after you go live.',
          onChanged: (String value) => ref
              .read(inspectorFlowControllerProvider.notifier)
              .patch((InspectorDraft current) => current.copyWith(password: value)),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: draft.acceptedTerms,
          activeColor: AppColors.primary,
          onChanged: (bool? value) {
            ref.read(inspectorFlowControllerProvider.notifier).patch(
                  (InspectorDraft current) =>
                      current.copyWith(acceptedTerms: value ?? false),
                );
          },
          title: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text('I agree to the ', style: TextStyle(color: palette.ink)),
              GestureDetector(
                onTap: () => showInspectorNoteDialog(
                  context,
                  title: 'Provider terms',
                  message:
                      'Provider terms will open from the inspector API when it is connected.',
                ),
                child: const Text(
                  'provider terms',
                  style: TextStyle(
                    color: Color(0xFFF97316),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(' and ', style: TextStyle(color: palette.ink)),
              GestureDetector(
                onTap: () => showInspectorNoteDialog(
                  context,
                  title: 'Privacy policy',
                  message:
                      'The privacy policy will open from the inspector API when it is connected.',
                ),
                child: const Text(
                  'privacy policy',
                  style: TextStyle(
                    color: Color(0xFFF97316),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }
}

class BusinessProfileStep extends ConsumerStatefulWidget {
  const BusinessProfileStep({super.key});

  @override
  ConsumerState<BusinessProfileStep> createState() => _BusinessProfileStepState();
}

class _BusinessProfileStepState extends ConsumerState<BusinessProfileStep> {
  late final TextEditingController _business;
  late final TextEditingController _bio;
  String? _error;

  @override
  void initState() {
    super.initState();
    final InspectorDraft draft =
        ref.read(inspectorFlowControllerProvider).requireValue;
    _business = TextEditingController(text: draft.businessName);
    _bio = TextEditingController(text: draft.bio);
  }

  @override
  void dispose() {
    _business.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from library'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) return;
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final int bytes = await file.length();
      final String? problem = MediaRules.photo(file.path, bytes);
      if (problem != null) {
        setState(() => _error = problem);
        return;
      }
      ref.read(inspectorFlowControllerProvider.notifier).patch(
            (InspectorDraft current) => current.copyWith(
              photoPath: file.path,
              photoFileName: file.name,
            ),
          );
      setState(() => _error = null);
    } on Object {
      if (mounted) {
        setState(() => _error = 'The photo could not be opened.');
      }
    }
  }

  void _continue() {
    final InspectorDraft? draft =
        ref.read(inspectorFlowControllerProvider).valueOrNull;
    if (draft == null) return;
    if (draft.businessName.trim().isEmpty ||
        draft.yearsOfExperience.isEmpty ||
        draft.bio.trim().isEmpty) {
      setState(() {
        _error = 'Add your business name, years of experience, and a short bio.';
      });
      return;
    }
    ref
        .read(inspectorFlowControllerProvider.notifier)
        .go(InspectorStep.qualifications);
  }

  @override
  Widget build(BuildContext context) {
    final InspectorDraft draft =
        ref.watch(inspectorFlowControllerProvider).requireValue;
    final InspectorPalette palette = InspectorPalette.of(context);
    final String initials = _initials(draft.fullName);
    final String photoPath = draft.photoPath?.trim() ?? '';
    final bool hasPhoto = photoPath.isNotEmpty;
    return InspectorStepScaffold(
      step: 2,
      total: 4,
      title: 'Tell us about your business',
      error: _error,
      actionLabel: 'Continue',
      onAction: _continue,
      children: <Widget>[
        const InspectorNote(
          text: 'Account verified\nYour email and phone are verified.',
          icon: Icons.check_circle,
          tone: InspectorNoteTone.green,
        ),
        const SizedBox(height: 16),
        Text(
          'Business type',
          style: TextStyle(fontWeight: FontWeight.w700, color: palette.ink),
        ),
        const SizedBox(height: 8),
        for (final BusinessType type in BusinessType.values)
          InspectorChoiceCard(
            title: type.label,
            detail: type.detail,
            selected: draft.businessType == type,
            onTap: () => ref.read(inspectorFlowControllerProvider.notifier).patch(
                  (InspectorDraft current) => current.copyWith(businessType: type),
                ),
          ),
        InspectorField(
          label: 'Business name',
          controller: _business,
          hint: 'Morgan Home Inspections',
          onChanged: (String value) => ref
              .read(inspectorFlowControllerProvider.notifier)
              .patch(
                (InspectorDraft current) => current.copyWith(businessName: value),
              ),
        ),
        InspectorDropdown<String>(
          label: 'Years of experience',
          value: draft.yearsOfExperience.isEmpty ? null : draft.yearsOfExperience,
          hint: '8 years',
          items: experienceOptions,
          fieldKey: const Key('years-of-experience'),
          onChanged: (String? value) {
            if (value == null) return;
            ref.read(inspectorFlowControllerProvider.notifier).patch(
                  (InspectorDraft current) =>
                      current.copyWith(yearsOfExperience: value),
                );
          },
        ),
        InspectorField(
          label: 'Short bio',
          controller: _bio,
          hint:
              'Residential inspections with clear reports and a buyer walkthrough.',
          maxLines: 4,
          maxLength: 250,
          helper: '${draft.bio.length}/250',
          onChanged: (String value) => ref
              .read(inspectorFlowControllerProvider.notifier)
              .patch((InspectorDraft current) => current.copyWith(bio: value)),
        ),
        Text(
          'Profile photo',
          style: TextStyle(fontWeight: FontWeight.w700, color: palette.ink),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            CircleAvatar(
              radius: 28,
              backgroundColor: palette.orangeSoft,
              backgroundImage: hasPhoto ? FileImage(File(photoPath)) : null,
              child: hasPhoto
                  ? null
                  : Text(
                      initials,
                      style: const TextStyle(
                        color: Color(0xFFF97316),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.file_upload_outlined),
              label: Text(hasPhoto ? 'Replace photo' : 'Upload photo'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'JPG, PNG, GIF or WebP · Max 5MB',
          style: TextStyle(color: palette.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class QualificationsStep extends ConsumerStatefulWidget {
  const QualificationsStep({super.key});

  @override
  ConsumerState<QualificationsStep> createState() => _QualificationsStepState();
}

class _QualificationsStepState extends ConsumerState<QualificationsStep> {
  late final TextEditingController _license;
  String? _error;

  @override
  void initState() {
    super.initState();
    final InspectorDraft draft =
        ref.read(inspectorFlowControllerProvider).requireValue;
    _license = TextEditingController(text: draft.licenseNumber);
  }

  @override
  void dispose() {
    _license.dispose();
    super.dispose();
  }

  Future<void> _pick(
    InspectorDraft Function(InspectorDraft current, String name) apply,
  ) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (result == null || result.files.isEmpty) return;
      final String name = result.files.single.name;
      ref.read(inspectorFlowControllerProvider.notifier).patch(
            (InspectorDraft current) => apply(current, name),
          );
    } on Object {
      if (mounted) setState(() => _error = 'The file could not be opened.');
    }
  }

  void _continue() {
    final InspectorDraft? draft =
        ref.read(inspectorFlowControllerProvider).valueOrNull;
    if (draft == null) return;
    if (draft.licensingState.isEmpty || draft.licenseNumber.trim().isEmpty) {
      setState(() => _error = 'Add your licensing state and license number.');
      return;
    }
    if (draft.licenseFileName == null || draft.insuranceFileName == null) {
      setState(() => _error = 'Upload your inspector license and insurance certificate.');
      return;
    }
    ref.read(inspectorFlowControllerProvider.notifier).go(InspectorStep.coverage);
  }

  @override
  Widget build(BuildContext context) {
    final InspectorDraft draft =
        ref.watch(inspectorFlowControllerProvider).requireValue;
    final InspectorPalette palette = InspectorPalette.of(context);
    return InspectorStepScaffold(
      step: 3,
      total: 4,
      title: 'Show your qualifications',
      error: _error,
      actionLabel: 'Continue',
      onAction: _continue,
      children: <Widget>[
        InspectorDropdown<String>(
          label: 'Licensing state',
          value: draft.licensingState.isEmpty ? null : draft.licensingState,
          hint: 'Texas',
          items: usStates,
          fieldKey: const Key('licensing-state'),
          onChanged: (String? value) {
            if (value == null) return;
            ref.read(inspectorFlowControllerProvider.notifier).patch(
                  (InspectorDraft current) =>
                      current.copyWith(licensingState: value),
                );
          },
        ),
        InspectorField(
          label: 'Inspector license number',
          controller: _license,
          hint: 'Enter license number',
          onChanged: (String value) => ref
              .read(inspectorFlowControllerProvider.notifier)
              .patch(
                (InspectorDraft current) => current.copyWith(licenseNumber: value),
              ),
        ),
        Text(
          'Upload documents',
          style: TextStyle(fontWeight: FontWeight.w700, color: palette.ink),
        ),
        const SizedBox(height: 8),
        _DocumentRow(
          label: 'Inspector license',
          fileName: draft.licenseFileName,
          onPick: () => _pick(
            (InspectorDraft current, String name) =>
                current.copyWith(licenseFileName: name),
          ),
        ),
        _DocumentRow(
          label: 'Insurance certificate',
          fileName: draft.insuranceFileName,
          onPick: () => _pick(
            (InspectorDraft current, String name) =>
                current.copyWith(insuranceFileName: name),
          ),
        ),
        _DocumentRow(
          label: 'Sample report',
          fileName: draft.sampleReportFileName,
          optional: true,
          onPick: () => _pick(
            (InspectorDraft current, String name) =>
                current.copyWith(sampleReportFileName: name),
          ),
        ),
        const InspectorNote(
          text: 'No review wait. Your profile is approved as soon as you submit.',
        ),
        const SizedBox(height: 18),
        Text(
          'Core inspection includes',
          style: TextStyle(fontWeight: FontWeight.w700, color: palette.ink),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3.4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: <Widget>[
            for (final ({String id, String label}) category in coreCategories)
              _CheckChip(
                label: category.label,
                selected: draft.coreCategoryIds.contains(category.id),
                onTap: () {
                  final Set<String> next = <String>{...draft.coreCategoryIds};
                  if (!next.add(category.id)) next.remove(category.id);
                  ref.read(inspectorFlowControllerProvider.notifier).patch(
                        (InspectorDraft current) =>
                            current.copyWith(coreCategoryIds: next),
                      );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Report and buyer walkthrough included.',
          style: TextStyle(color: palette.muted),
        ),
      ],
    );
  }
}

class CoverageStep extends ConsumerStatefulWidget {
  const CoverageStep({super.key});

  @override
  ConsumerState<CoverageStep> createState() => _CoverageStepState();
}

class _CoverageStepState extends ConsumerState<CoverageStep> {
  String? _error;

  Future<void> _addArea() async {
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _ServiceAreaDialog(),
    );
    final String area = (value ?? '').trim();
    if (area.isEmpty) return;
    ref.read(inspectorFlowControllerProvider.notifier).patch(
          (InspectorDraft current) {
            if (current.serviceAreas
                .map((String item) => item.toLowerCase())
                .contains(area.toLowerCase())) {
              return current;
            }
            return current.copyWith(
              serviceAreas: <String>[...current.serviceAreas, area],
            );
          },
        );
  }

  void _continue() {
    final InspectorDraft? draft =
        ref.read(inspectorFlowControllerProvider).valueOrNull;
    if (draft == null) return;
    if (draft.serviceAreas.isEmpty) {
      setState(() => _error = 'Add at least one ZIP code or city.');
      return;
    }
    if (draft.homeTypes.isEmpty) {
      setState(() => _error = 'Choose at least one home type.');
      return;
    }
    ref
        .read(inspectorFlowControllerProvider.notifier)
        .go(InspectorStep.scopeStructure);
  }

  @override
  Widget build(BuildContext context) {
    final InspectorDraft draft =
        ref.watch(inspectorFlowControllerProvider).requireValue;
    final InspectorPalette palette = InspectorPalette.of(context);
    return InspectorStepScaffold(
      step: 4,
      total: 4,
      title: 'Where do you inspect?',
      error: _error,
      actionLabel: 'Set inspection pricing',
      onAction: _continue,
      children: <Widget>[
        const _CoverageMap(),
        const SizedBox(height: 16),
        Text(
          'Service areas (ZIP codes or cities)',
          style: TextStyle(fontWeight: FontWeight.w700, color: palette.ink),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String area in draft.serviceAreas)
              InputChip(
                label: Text(area),
                onDeleted: () {
                  ref.read(inspectorFlowControllerProvider.notifier).patch(
                        (InspectorDraft current) => current.copyWith(
                          serviceAreas: <String>[
                            for (final String item in current.serviceAreas)
                              if (item != area) item,
                          ],
                        ),
                      );
                },
              ),
            ActionChip(
              key: const Key('add-service-area'),
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Add ZIP code'),
              onPressed: _addArea,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Home types you inspect',
          style: TextStyle(fontWeight: FontWeight.w700, color: palette.ink),
        ),
        const SizedBox(height: 8),
        for (final HomeType type in HomeType.values)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: draft.homeTypes.contains(type),
            activeColor: const Color(0xFFF97316),
            secondary: Icon(_homeIcon(type), color: palette.ink),
            title: Text(type.label),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (bool? value) {
              final Set<HomeType> next = <HomeType>{...draft.homeTypes};
              if (value ?? false) {
                next.add(type);
              } else {
                next.remove(type);
              }
              ref.read(inspectorFlowControllerProvider.notifier).patch(
                    (InspectorDraft current) => current.copyWith(homeTypes: next),
                  );
            },
          ),
        Text(
          "You'll set prices for each selected home type.",
          style: TextStyle(color: palette.muted),
        ),
      ],
    );
  }
}

class _ServiceAreaDialog extends StatefulWidget {
  const _ServiceAreaDialog();

  @override
  State<_ServiceAreaDialog> createState() => _ServiceAreaDialogState();
}

class _ServiceAreaDialogState extends State<_ServiceAreaDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a service area'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Frisco',
          labelText: 'ZIP code or city',
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (String text) => Navigator.of(context).pop(text),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm-service-area'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.label,
    required this.fileName,
    required this.onPick,
    this.optional = false,
  });

  final String label;
  final String? fileName;
  final VoidCallback onPick;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final InspectorPalette palette = InspectorPalette.of(context);
    final bool uploaded = fileName != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(label),
        subtitle: Text(uploaded ? fileName! : (optional ? 'Optional' : 'Required')),
        trailing: uploaded
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.check_circle, color: Color(0xFF16803C), size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Uploaded',
                    style: TextStyle(
                      color: Color(0xFF16803C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : TextButton(
                onPressed: onPick,
                child: Text(optional ? 'Add file' : 'Upload'),
              ),
        onTap: onPick,
      ),
    );
  }
}

class _CheckChip extends StatelessWidget {
  const _CheckChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final InspectorPalette palette = InspectorPalette.of(context);
    return Material(
      color: selected ? palette.orangeSoft : palette.field,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? const Color(0xFFF97316) : palette.line,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: <Widget>[
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              color: selected ? const Color(0xFFF97316) : palette.muted,
              size: 20,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverageMap extends StatelessWidget {
  const _CoverageMap();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: const AspectRatio(
        aspectRatio: 1.55,
        child: CustomPaint(
          painter: _DfwMapPainter(),
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}

class _DfwMapPainter extends CustomPainter {
  const _DfwMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE7F2EA),
    );
    final Paint road = Paint()
      ..color = const Color(0xFFD5E3D8)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.42),
      Offset(size.width * 0.92, size.height * 0.58),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.48, size.height * 0.08),
      Offset(size.width * 0.62, size.height * 0.92),
      road,
    );
    final Offset center = Offset(size.width * 0.62, size.height * 0.42);
    canvas.drawCircle(
      center,
      size.width * 0.22,
      Paint()..color = const Color(0xFFF97316).withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      center,
      size.width * 0.22,
      Paint()
        ..color = const Color(0xFFF97316)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      center,
      6,
      Paint()..color = const Color(0xFFF97316),
    );
    _label(canvas, 'Denton', Offset(size.width * 0.18, size.height * 0.28));
    _label(canvas, 'Frisco', Offset(size.width * 0.48, size.height * 0.22));
    _label(canvas, 'McKinney', Offset(size.width * 0.78, size.height * 0.2));
    _label(canvas, 'Plano', Offset(size.width * 0.74, size.height * 0.48));
    _label(canvas, 'DFW', Offset(size.width * 0.22, size.height * 0.62));
    _label(canvas, 'Dallas', Offset(size.width * 0.58, size.height * 0.78));
  }

  void _label(Canvas canvas, String text, Offset offset) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF3F3F46),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _initials(String name) {
  final List<String> parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((String part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'ML';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

IconData _homeIcon(HomeType type) {
  return switch (type) {
    HomeType.singleFamily => Icons.house_outlined,
    HomeType.townhouse => Icons.holiday_village_outlined,
    HomeType.condo => Icons.apartment_outlined,
    HomeType.duplex => Icons.other_houses_outlined,
  };
}
