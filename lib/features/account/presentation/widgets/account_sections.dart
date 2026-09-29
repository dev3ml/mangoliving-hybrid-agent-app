import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/agent_profile.dart';
import '../controllers/account_controller.dart';
import '../controllers/theme_mode_controller.dart';

void showAccountSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

class AccountCompletionHeader extends StatelessWidget {
  const AccountCompletionHeader({super.key, required this.view});

  final AccountViewData view;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AgentProfile profile = view.profile;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.primary.withValues(alpha: 0.12),
            theme.colorScheme.surface,
          ],
        ),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 32,
                backgroundImage: profile.hasPhoto ? NetworkImage(profile.photoUrl!) : null,
                child: profile.hasPhoto
                    ? null
                    : Text(profile.initials, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      view.draft.name.isEmpty ? 'Agent' : view.draft.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      profile.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${view.completionPercent}% complete',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: view.completedChecks / 5,
              minHeight: 8,
              color: AppColors.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          if (profile.videoIntroStatus == VideoIntroStatus.rejected) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _Banner(
              color: theme.colorScheme.errorContainer,
              textColor: theme.colorScheme.onErrorContainer,
              text:
                  'Your last video introduction was rejected. Please upload a new one following the guidelines below.',
            ),
          ] else if (profile.videoIntroStatus == VideoIntroStatus.pending) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            const _Banner(
              text: 'Your intro video is under review.',
            ),
          ],
        ],
      ),
    );
  }
}

class AccountProfileSection extends ConsumerStatefulWidget {
  const AccountProfileSection({super.key, required this.view});

  final AccountViewData view;

  @override
  ConsumerState<AccountProfileSection> createState() =>
      _AccountProfileSectionState();
}

class _AccountProfileSectionState extends ConsumerState<AccountProfileSection> {
  late final TextEditingController _name;
  late final TextEditingController _license;
  late final TextEditingController _phone;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.view.draft.name);
    _license = TextEditingController(text: widget.view.draft.license);
    _phone = TextEditingController(text: widget.view.draft.phone);
    _bio = TextEditingController(text: widget.view.draft.bio);
  }

  @override
  void didUpdateWidget(AccountProfileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.view.isDirty && oldWidget.view.isDirty) {
      _name.text = widget.view.draft.name;
      _license.text = widget.view.draft.license;
      _phone.text = widget.view.draft.phone;
      _bio.text = widget.view.draft.bio;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _license.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AccountDraft draft = widget.view.draft;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
      children: <Widget>[
        Text('Basic Information', style: theme.textTheme.titleMedium),
        Text(
          'How buyers see your contact details',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full Name'),
          onChanged: (String value) => ref
              .read(accountControllerProvider.notifier)
              .patchDraft((AccountDraft d) => d.copyWith(name: value)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _license,
          decoration: const InputDecoration(
            labelText: 'Real Estate License #',
            hintText: 'e.g., DRE 01234567',
          ),
          onChanged: (String value) => ref
              .read(accountControllerProvider.notifier)
              .patchDraft((AccountDraft d) => d.copyWith(license: value)),
        ),
        const SizedBox(height: AppSpacing.md),
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Email',
            helperText: 'Contact support to change your email',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Text(widget.view.profile.email),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '10-digit phone number',
          ),
          onChanged: (String value) => ref
              .read(accountControllerProvider.notifier)
              .patchDraft((AccountDraft d) => d.copyWith(phone: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Professional Bio', style: theme.textTheme.titleMedium),
        Text(
          'A short introduction that appears on your public profile',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _bio,
          maxLength: 500,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Tell buyers about your experience and specialties...',
            counterText: '',
          ),
          onChanged: (String value) => ref
              .read(accountControllerProvider.notifier)
              .patchDraft((AccountDraft d) => d.copyWith(bio: value)),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${draft.bio.length}/500',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Languages', style: theme.textTheme.titleMedium),
        Text(
          'Languages you speak — shown on your public profile. Nothing is selected by default.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => _pickLanguages(context, ref, draft),
          child: Text(
            draft.languages.isEmpty
                ? 'Select languages'
                : '${draft.languages.length} selected',
          ),
        ),
        if (draft.languages.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: draft.languages
                .map(
                  (String language) => InputChip(
                    label: Text(language),
                    onDeleted: () => ref
                        .read(accountControllerProvider.notifier)
                        .patchDraft(
                          (AccountDraft d) => d.copyWith(
                            languages: d.languages
                                .where((String l) => l != language)
                                .toList(),
                          ),
                        ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _pickLanguages(
    BuildContext context,
    WidgetRef ref,
    AccountDraft draft,
  ) async {
    final List<String> next = List<String>.from(draft.languages);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModal) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: profileLanguages.map((String language) {
                  final bool selected = next.contains(language);
                  return CheckboxListTile(
                    title: Text(language),
                    value: selected,
                    onChanged: (bool? value) {
                      setModal(() {
                        if (value == true) {
                          next.add(language);
                        } else {
                          next.remove(language);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
    if (!context.mounted) return;
    ref.read(accountControllerProvider.notifier).patchDraft(
          (AccountDraft d) => d.copyWith(languages: next),
        );
  }
}

class AccountMediaSection extends ConsumerWidget {
  const AccountMediaSection({super.key, required this.view});

  final AccountViewData view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AgentProfile profile = view.profile;
    final bool photoBusy = view.uploading == AccountUploadKind.photo;
    final bool videoBusy = view.uploading == AccountUploadKind.video;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
      children: <Widget>[
        Text('Profile Photo', style: theme.textTheme.titleMedium),
        Text(
          'Shown across the platform and public profile',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            CircleAvatar(
              radius: 36,
              backgroundImage: profile.hasPhoto ? NetworkImage(profile.photoUrl!) : null,
              child: profile.hasPhoto
                  ? null
                  : const Icon(Icons.person_outline, size: 32),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: photoBusy
                        ? null
                        : () => _pickMedia(
                              context,
                              ref,
                              image: true,
                              onPicked: (String path) => ref
                                  .read(accountControllerProvider.notifier)
                                  .uploadPhoto(path),
                              success: 'Photo uploaded',
                            ),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      photoBusy
                          ? 'Uploading…'
                          : profile.hasPhoto
                              ? 'Change photo'
                              : 'Upload photo',
                    ),
                  ),
                  Text(
                    'JPG, PNG, GIF or WebP · Max 5MB',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: <Widget>[
            Text('Video Introduction', style: theme.textTheme.titleMedium),
            const SizedBox(width: AppSpacing.sm),
            if (profile.videoIntroStatus == VideoIntroStatus.pending)
              const Chip(label: Text('Under review'), visualDensity: VisualDensity.compact)
            else if (profile.videoIntroStatus == VideoIntroStatus.approved &&
                profile.hasVideo)
              const Chip(label: Text('Approved'), visualDensity: VisualDensity.compact),
          ],
        ),
        Text(
          '20–30 second clip · MP4, MOV or WebM · Max 50MB',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (profile.hasVideo)
          _IntroVideoCard(
            url: profile.videoIntroUrl!,
            busy: view.saving || videoBusy,
            onRemove: () => _removeVideo(context, ref),
          )
        else
          OutlinedButton(
            onPressed: videoBusy
                ? null
                : () => _pickMedia(
                      context,
                      ref,
                      image: false,
                      onPicked: (String path) => ref
                          .read(accountControllerProvider.notifier)
                          .uploadVideo(path),
                      success: 'Video uploaded and submitted for review',
                    ),
            child: Text(videoBusy ? 'Uploading…' : 'Click to upload video'),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Video guidelines: Keep it professional, well-lit, and focused on introducing yourself and your expertise. Videos are reviewed before appearing on your public profile.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _removeVideo(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove intro video?'),
          content: const Text(
            'The video will be deleted from your public profile. You can upload a new one anytime.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove video'),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(accountControllerProvider.notifier).removeVideo();
      if (context.mounted) showAccountSnack(context, 'Video removed');
    } on Object catch (error) {
      if (context.mounted) showAccountSnack(context, error.toString(), error: true);
    }
  }
}

class AccountBrokerageSection extends ConsumerStatefulWidget {
  const AccountBrokerageSection({super.key, required this.view});

  final AccountViewData view;

  @override
  ConsumerState<AccountBrokerageSection> createState() =>
      _AccountBrokerageSectionState();
}

class _AccountBrokerageSectionState extends ConsumerState<AccountBrokerageSection> {
  late final TextEditingController _brokerage;

  @override
  void initState() {
    super.initState();
    _brokerage = TextEditingController(text: widget.view.draft.brokerageName);
  }

  @override
  void didUpdateWidget(AccountBrokerageSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.view.isDirty && oldWidget.view.isDirty) {
      _brokerage.text = widget.view.draft.brokerageName;
    }
  }

  @override
  void dispose() {
    _brokerage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AccountViewData view = widget.view;
    final bool busy = view.uploading == AccountUploadKind.logo;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
      children: <Widget>[
        Text('Brokerage Information', style: theme.textTheme.titleMedium),
        Text(
          'Adding your brokerage helps build trust with potential clients.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _brokerage,
          decoration: const InputDecoration(
            labelText: 'Brokerage / Company Name',
            hintText: 'e.g., Keller Williams Realty',
          ),
          onChanged: (String value) => ref
              .read(accountControllerProvider.notifier)
              .patchDraft((AccountDraft d) => d.copyWith(brokerageName: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Brokerage Logo', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: view.profile.brokerageLogoUrl == null ||
                      view.profile.brokerageLogoUrl!.isEmpty
                  ? const Icon(Icons.apartment_outlined)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Image.network(
                        view.profile.brokerageLogoUrl!,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => _pickMedia(
                              context,
                              ref,
                              image: true,
                              galleryOnly: true,
                              onPicked: (String path) => ref
                                  .read(accountControllerProvider.notifier)
                                  .uploadLogo(path),
                              success: 'Logo uploaded',
                            ),
                    icon: const Icon(Icons.upload_outlined),
                    label: Text(
                      busy
                          ? 'Uploading…'
                          : (view.profile.brokerageLogoUrl ?? '').isNotEmpty
                              ? 'Change logo'
                              : 'Upload logo',
                    ),
                  ),
                  Text(
                    'JPG, PNG or SVG · Max 2MB',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AccountPublicSection extends ConsumerStatefulWidget {
  const AccountPublicSection({super.key, required this.view});

  final AccountViewData view;

  @override
  ConsumerState<AccountPublicSection> createState() =>
      _AccountPublicSectionState();
}

class _AccountPublicSectionState extends ConsumerState<AccountPublicSection> {
  late final TextEditingController _mlsKey;
  late final TextEditingController _mlsId;

  @override
  void initState() {
    super.initState();
    _mlsKey = TextEditingController(text: widget.view.draft.listAgentKeyNumeric);
    _mlsId = TextEditingController(text: widget.view.draft.listAgentMlsId);
  }

  @override
  void didUpdateWidget(AccountPublicSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.view.isDirty && oldWidget.view.isDirty) {
      _mlsKey.text = widget.view.draft.listAgentKeyNumeric;
      _mlsId.text = widget.view.draft.listAgentMlsId;
    }
  }

  @override
  void dispose() {
    _mlsKey.dispose();
    _mlsId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AccountViewData view = widget.view;
    final bool visible = view.draft.publicProfileVisible;
    final String? url = view.profile.publicUrl;
    final bool actionsEnabled = visible && url != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
      children: <Widget>[
        Text('Your Public Profile', style: theme.textTheme.titleMedium),
        Text(
          'Buyers can find and contact you through this page.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Public profile visible'),
          subtitle: Text(
            visible
                ? 'Your profile is live and discoverable by buyers in the agent directory.'
                : 'Your profile is hidden. Buyers cannot view or find it in the directory.',
          ),
          value: visible,
          onChanged: (bool value) => ref
              .read(accountControllerProvider.notifier)
              .patchDraft((AccountDraft d) => d.copyWith(publicProfileVisible: value)),
        ),
        const SizedBox(height: AppSpacing.sm),
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Public URL'),
          child: Text(url ?? '', style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: actionsEnabled ? () => _copy(context, url) : null,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy link'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: actionsEnabled
                    ? () => launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        )
                    : null,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          visible
              ? 'Complete your profile to maximize visibility in the agent discovery directory. You\'re currently ${view.completionPercent}% complete.'
              : 'Your public profile is currently hidden. Turn on visibility and save to make it discoverable again.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('MLS Listing Linking', style: theme.textTheme.titleMedium),
        Text(
          'Enter your MLS agent identifiers to display your real listings on your public profile.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _mlsKey,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            labelText: 'List Agent Key (numeric)',
            hintText: 'e.g. 71234567',
          ),
          onChanged: (String value) => ref
              .read(accountControllerProvider.notifier)
              .patchDraft((AccountDraft d) => d.copyWith(listAgentKeyNumeric: value)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _mlsId,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            labelText: 'List Agent MLS ID',
            hintText: 'e.g. 567890',
          ),
          onChanged: (String value) => ref
              .read(accountControllerProvider.notifier)
              .patchDraft((AccountDraft d) => d.copyWith(listAgentMlsId: value)),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context, String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) showAccountSnack(context, 'Link copied');
    } on Object {
      if (context.mounted) {
        showAccountSnack(context, 'Could not copy link', error: true);
      }
    }
  }
}

class AccountSecuritySection extends ConsumerStatefulWidget {
  const AccountSecuritySection({super.key, required this.view});

  final AccountViewData view;

  @override
  ConsumerState<AccountSecuritySection> createState() =>
      _AccountSecuritySectionState();
}

class _AccountSecuritySectionState extends ConsumerState<AccountSecuritySection> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ThemeMode mode = ref.watch(themeModeControllerProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
      children: <Widget>[
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_outline),
          title: const Text('Change password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.changePassword),
        ),
        const Divider(),
        Text('Appearance', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
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
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Danger Zone',
          style: theme.textTheme.titleMedium?.copyWith(color: AppColors.destructive),
        ),
        Text(
          'Permanently delete your agent profile and all associated data. This action cannot be undone.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
          onPressed: widget.view.deleting ? null : () => _confirmDelete(context),
          child: Text(widget.view.deleting ? 'Deleting…' : 'Delete account'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: widget.view.busy ? null : () => _logout(context),
          child: const Text('Log out'),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.login);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final TextEditingController confirm = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModal) {
            return AlertDialog(
              title: const Text('Delete your agent account?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'This permanently deletes your profile and removes you from all buyer connections. This action cannot be undone. Type DELETE to confirm.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: confirm,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Type DELETE to confirm',
                    ),
                    onChanged: (_) => setModal(() {}),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: widget.view.deleting
                      ? null
                      : () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                  ),
                  onPressed: DeleteConfirm.matches(confirm.text) && !widget.view.deleting
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: Text(widget.view.deleting ? 'Deleting…' : 'Delete account'),
                ),
              ],
            );
          },
        );
      },
    );
    confirm.dispose();
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(accountControllerProvider.notifier).deleteAccount();
      if (context.mounted) {
        showAccountSnack(context, 'Your account has been deleted');
        context.go(AppRoutes.login);
      }
    } on Object catch (error) {
      if (context.mounted) {
        showAccountSnack(context, error.toString(), error: true);
      }
    }
  }
}

class _IntroVideoCard extends StatefulWidget {
  const _IntroVideoCard({
    required this.url,
    required this.busy,
    required this.onRemove,
  });

  final String url;
  final bool busy;
  final VoidCallback onRemove;

  @override
  State<_IntroVideoCard> createState() => _IntroVideoCardState();
}

class _IntroVideoCardState extends State<_IntroVideoCard> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? controller = _controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AspectRatio(
          aspectRatio: controller?.value.isInitialized == true
              ? controller!.value.aspectRatio
              : 16 / 9,
          child: controller?.value.isInitialized == true
              ? VideoPlayer(controller!)
              : const ColoredBox(
                  color: Colors.black12,
                  child: Center(child: CircularProgressIndicator()),
                ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: widget.busy ? null : widget.onRemove,
            child: const Text('Remove video'),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    this.color,
    this.textColor,
  });

  final String text;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(text, style: TextStyle(color: textColor)),
    );
  }
}

Future<void> _pickMedia(
  BuildContext context,
  WidgetRef ref, {
  required bool image,
  required Future<void> Function(String path) onPicked,
  required String success,
  bool galleryOnly = false,
}) async {
  final ImageSource? source = galleryOnly
      ? ImageSource.gallery
      : await showModalBottomSheet<ImageSource>(
          context: context,
          builder: (BuildContext context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('Choose from library'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: Text(image ? 'Take photo' : 'Record video'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ],
              ),
            );
          },
        );
  if (source == null) return;
  final ImagePicker picker = ImagePicker();
  final XFile? file = image
      ? await picker.pickImage(source: source)
      : await picker.pickVideo(source: source);
  if (file == null || !context.mounted) return;
  try {
    await onPicked(file.path);
    if (context.mounted) showAccountSnack(context, success);
  } on Object catch (error) {
    if (context.mounted) showAccountSnack(context, error.toString(), error: true);
  }
}
