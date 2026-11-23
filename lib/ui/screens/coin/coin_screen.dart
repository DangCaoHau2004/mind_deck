import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/data/models/coin_models.dart';
import 'package:mind_deck/ui/commons/ads/watch_video_coin_button.dart';
import 'package:mind_deck/ui/screens/coin/bloc/coin_cubit.dart';

/// Số dư xu, kiếm xu bằng video và lịch sử giao dịch.
class CoinScreen extends StatelessWidget {
  const CoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => DI().sl<CoinCubit>()..load(), child: const _CoinView());
  }
}

class _CoinView extends StatefulWidget {
  const _CoinView();

  @override
  State<_CoinView> createState() => _CoinViewState();
}

class _CoinViewState extends State<_CoinView> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        context.read<CoinCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static String reasonLabel(String reason) {
    return switch (reason) {
      'ad_video' => 'coin_reason_ad_video'.tr,
      'ai_import' => 'coin_reason_ai_import'.tr,
      'refund' => 'coin_reason_refund'.tr,
      'admin_adjust' => 'coin_reason_admin_adjust'.tr,
      _ => 'coin_reason_other'.tr,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('coin_title'.tr), centerTitle: true),
      body: BlocBuilder<CoinCubit, CoinState>(
        builder: (context, state) {
          if (state.isLoading && state.info == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.info == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.error ?? 'common_error_occurred'.tr,
                    style: TextStyle(color: cs.error),
                  ),
                  TextButton(
                    onPressed: context.read<CoinCubit>().load,
                    child: Text('common_retry'.tr),
                  ),
                ],
              ),
            );
          }
          final info = state.info!;
          return RefreshIndicator(
            onRefresh: context.read<CoinCubit>().load,
            child: ListView.builder(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: state.history.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) return _BalanceCard(info: info);
                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
                    child: Text(
                      state.history.isEmpty ? 'coin_history_empty'.tr : 'coin_history'.tr,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }
                return _TransactionTile(item: state.history[index - 2]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final CoinInfo info;
  const _BalanceCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final earn = info.earn;
    final reset = earn.resetsAt == null ? null : DateFormat('HH:mm dd/MM').format(earn.resetsAt!);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('coin_balance'.tr, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.monetization_on_rounded, color: cs.primary, size: 32),
              const SizedBox(width: 8),
              Text(
                '${info.balance}',
                style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'coin_earned_today'.tr
                .replaceAll('{n}', '${earn.earnedToday}')
                .replaceAll('{max}', '${earn.dailyCap}'),
            style: theme.textTheme.bodyMedium,
          ),
          if (reset != null && earn.capReached)
            Text(
              'coin_resets_at'.tr.replaceAll('{time}', reset),
              style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
          const SizedBox(height: 8),
          WatchVideoForCoinButton(
            placement: 'coin_screen',
            filled: true,
            onRewarded: (_) => context.read<CoinCubit>().load(),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final CoinTransaction item;
  const _TransactionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final positive = item.amount > 0;
    final date = item.createdAt == null
        ? ''
        : DateFormat('HH:mm dd/MM/yyyy').format(item.createdAt!);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(_CoinViewState.reasonLabel(item.reason)),
      subtitle: Text(date),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${positive ? '+' : ''}${item.amount}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: positive ? Colors.green : cs.error,
            ),
          ),
          Text(
            'coin_balance_after'.tr.replaceAll('{n}', '${item.balanceAfter}'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}
