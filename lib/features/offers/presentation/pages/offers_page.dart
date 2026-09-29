import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dashboard_app_bar_actions.dart';
import '../../domain/models/property_action.dart';
import '../controllers/offers_controller.dart';

class OffersPage extends ConsumerWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<OffersViewData> async = ref.watch(offersControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers'),
        actions: DashboardAppBarActions.of(
          extra: <Widget>[
            IconButton(
              tooltip: 'Refresh',
              onPressed: () =>
                  ref.read(offersControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(offersControllerProvider.notifier).refresh(),
        child: async.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: Text('Loading offers…')),
          error: (Object error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              Text(
                'Failed to load offers.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(error.toString()),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () =>
                    ref.read(offersControllerProvider.notifier).refresh(),
                child: const Text('Refresh'),
              ),
            ],
          ),
          data: (OffersViewData view) => _OffersBody(view: view),
        ),
      ),
    );
  }
}

class _OffersBody extends ConsumerWidget {
  const _OffersBody({required this.view});

  final OffersViewData view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PropertyAction> visible = view.visible;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: <Widget>[
        Text(
          'Prepare, send, and update offers for buyers connected to you.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CountGrid(counts: view.counts),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: const Text('All'),
              selected: view.filter == null,
              onSelected: (_) =>
                  ref.read(offersControllerProvider.notifier).setFilter(null),
            ),
            ...OfferBoardState.values.map((OfferBoardState state) {
              return ChoiceChip(
                label: Text(state.label),
                selected: view.filter == state,
                onSelected: (_) {
                  ref.read(offersControllerProvider.notifier).setFilter(
                        view.filter == state ? null : state,
                      );
                },
              );
            }),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text('No offer-stage properties yet.'),
          )
        else
          ...visible.map((PropertyAction row) {
            return _OfferCard(
              row: row,
              busy: view.isBusy(row.id),
            );
          }),
      ],
    );
  }
}

class _CountGrid extends StatelessWidget {
  const _CountGrid({required this.counts});

  final OfferCounts counts;

  @override
  Widget build(BuildContext context) {
    final List<(String, int)> items = <(String, int)>[
      ('Total', counts.total),
      ('Visited', counts.visited),
      ('Offer Placed', counts.offerPlaced),
      ('Offer Accepted', counts.offerAccepted),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      children: items
          .map(
            ((String, int) item) => Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    item.$1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '${item.$2}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.row, required this.busy});

  final PropertyAction row;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${row.buyerName} · ${row.streetLine}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if ((row.buyer?.email ?? '').isNotEmpty)
              Text(
                row.buyer!.email!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (row.cityLine.isNotEmpty)
              Text(
                row.cityLine,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Chip(
                  label: Text(row.stageLabel),
                  backgroundColor: row.isRejected
                      ? AppColors.destructive.withValues(alpha: 0.12)
                      : theme.colorScheme.surfaceContainerHighest,
                  labelStyle: TextStyle(
                    color: row.isRejected ? AppColors.destructive : null,
                  ),
                ),
                if (row.offer?.offerAmount != null) Text(row.amountLabel),
              ],
            ),
            if (row.offer?.offerSentAt != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Sent ${row.sentLabel}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                if (row.canPrepare)
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => context.push(AppRoutes.offerPrepare(row.id)),
                    child: const Text('Prepare offer'),
                  ),
                if (row.canView)
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.offerSummary(row.id)),
                    child: const Text('View offer'),
                  ),
                if (row.canUpdate)
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => context.push(AppRoutes.offerPrepare(row.id)),
                    child: const Text('Update'),
                  ),
                if (row.canSendAgain)
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => context.push(AppRoutes.offerPrepare(row.id)),
                    child: const Text('Send again'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
