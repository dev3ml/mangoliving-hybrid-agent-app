import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/mango_living_logo.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../controllers/inspector_flow_controller.dart';
import '../inspector_navigation.dart';

class InspectorPalette {
  InspectorPalette.of(BuildContext context)
      : dark = Theme.of(context).brightness == Brightness.dark {
    canvas = dark ? const Color(0xFF14110F) : Colors.white;
    ink = dark ? Colors.white : AppColors.ink;
    muted = dark ? const Color(0xFFB4B4B4) : AppColors.muted;
    line = dark ? const Color(0xFF3A302A) : const Color(0xFFE7E5E4);
    field = dark ? const Color(0xFF241C18) : Colors.white;
    soft = dark ? const Color(0xFF2A221E) : const Color(0xFFF6F3F0);
    green = const Color(0xFF16803C);
    greenSoft = dark ? const Color(0xFF14301F) : const Color(0xFFECFDF3);
    orangeSoft = dark ? const Color(0xFF3A2410) : const Color(0xFFFFF1E6);
  }

  final bool dark;
  late final Color canvas;
  late final Color ink;
  late final Color muted;
  late final Color line;
  late final Color field;
  late final Color soft;
  late final Color green;
  late final Color greenSoft;
  late final Color orangeSoft;
}

class InspectorStepScaffold extends ConsumerWidget {
  const InspectorStepScaffold({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    required this.children,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
    this.error,
    this.secondaryLabel,
    this.onSecondary,
  });

  final int step;
  final int total;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String actionLabel;
  final VoidCallback onAction;
  final String? error;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InspectorPalette palette = InspectorPalette.of(context);
    final bool canReturn =
        ref.watch(inspectorFlowControllerProvider).valueOrNull?.returnTo !=
            null;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => inspectorBack(context, ref),
                    icon: Icon(Icons.arrow_back, color: palette.ink),
                  ),
                  const Expanded(
                    child: Column(
                      children: <Widget>[
                        MangoLivingLogo(fontSize: 22),
                        SizedBox(height: 2),
                        Text(
                          'FOR PROVIDERS',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const ThemeToggleButton(),
                  TextButton(
                    onPressed: () => inspectorSaveAndExit(context, ref),
                    child: Text(
                      'Save & exit',
                      style: TextStyle(
                        color: palette.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : step / total,
                        minHeight: 6,
                        backgroundColor: palette.line,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$step of $total',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: palette.ink,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: palette.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ...children,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (canReturn)
                    TextButton(
                    onPressed: () => inspectorReturnToReview(ref),
                    child: const Text('Back to review'),
                    ),
                  if (error != null) ...<Widget>[
                    Text(
                      error!,
                      style: const TextStyle(
                        color: AppColors.destructive,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  InspectorPrimaryButton(
                    label: actionLabel,
                    onPressed: onAction,
                  ),
                  if (secondaryLabel != null && onSecondary != null)
                    TextButton(
                      onPressed: onSecondary,
                      child: Text(secondaryLabel!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InspectorPrimaryButton extends StatelessWidget {
  const InspectorPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        key: const Key('inspector-primary-action'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class InspectorField extends StatelessWidget {
  const InspectorField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.onToggleObscure,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.helper,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? maxLength;
  final String? helper;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final InspectorPalette palette = InspectorPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            maxLines: obscure ? 1 : maxLines,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            style: TextStyle(color: palette.ink),
            decoration: InputDecoration(
              hintText: hint,
              counterText: maxLength == null ? null : null,
              filled: true,
              fillColor: palette.field,
              suffixIcon: onToggleObscure == null
                  ? null
                  : IconButton(
                      onPressed: onToggleObscure,
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                helper!,
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class InspectorDropdown<T> extends StatelessWidget {
  const InspectorDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    this.fieldKey,
    this.itemLabel,
  });

  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String hint;
  final Key? fieldKey;
  final String Function(T item)? itemLabel;

  @override
  Widget build(BuildContext context) {
    final InspectorPalette palette = InspectorPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w700, color: palette.ink),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            key: fieldKey,
            isExpanded: true,
            initialValue: items.contains(value) ? value : null,
            hint: Text(hint),
            items: <DropdownMenuItem<T>>[
              for (final T item in items)
                DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel?.call(item) ?? '$item'),
                ),
            ],
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.field,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InspectorNote extends StatelessWidget {
  const InspectorNote({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
    this.tone = InspectorNoteTone.neutral,
  });

  final String text;
  final IconData icon;
  final InspectorNoteTone tone;

  @override
  Widget build(BuildContext context) {
    final InspectorPalette palette = InspectorPalette.of(context);
    final Color background = switch (tone) {
      InspectorNoteTone.neutral => palette.soft,
      InspectorNoteTone.green => palette.greenSoft,
      InspectorNoteTone.orange => palette.orangeSoft,
    };
    final Color foreground = switch (tone) {
      InspectorNoteTone.neutral => palette.muted,
      InspectorNoteTone.green => palette.green,
      InspectorNoteTone.orange => AppColors.primary,
    };
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: palette.ink, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

enum InspectorNoteTone { neutral, green, orange }

class InspectorChoiceCard extends StatelessWidget {
  const InspectorChoiceCard({
    super.key,
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final InspectorPalette palette = InspectorPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? palette.orangeSoft : palette.field,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.primary : palette.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppColors.primary : palette.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(detail, style: TextStyle(color: palette.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showInspectorNoteDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
