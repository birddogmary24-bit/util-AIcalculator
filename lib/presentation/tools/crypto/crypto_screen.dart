import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/thousands_input_formatter.dart';

import '../../../core/constants/region.dart';
import '../../../providers/region_provider.dart';
import '../../common/widgets/labeled_input_field.dart';
import '../../common/widgets/result_display_card.dart';
import '../../common/widgets/styled_dropdown.dart';
import 'crypto_provider.dart';

final _krwFmt = NumberFormat('#,##0');
final _coinFmt = NumberFormat('#,##0.########');
final _percentFmt = NumberFormat('+#,##0.##;-#,##0.##');

class CryptoScreen extends ConsumerStatefulWidget {
  const CryptoScreen({super.key});

  @override
  ConsumerState<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends ConsumerState<CryptoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController();
  final _simAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(cryptoProvider.notifier).setTabIndex(_tabController.index);
      }
    });
    // Auto-fetch prices
    Future.microtask(() {
      ref.read(cryptoProvider.notifier).fetchPrices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _simAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(cryptoProvider);
    final region = ref.watch(regionProvider);
    final isKr = region == RegionMode.kr;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(isKr ? '코인 계산기' : 'Crypto Calculator',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: cs.surfaceTint,
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.onSurface,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: isKr ? '시세 변환' : 'Conversion'),
            Tab(text: isKr ? '과거 시뮬레이션' : 'Simulation'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversionTab(state, region),
          _buildSimulationTab(state, region),
        ],
      ),
    );
  }

  // --- Tab 1: Conversion ---

  Widget _buildConversionTab(CryptoState state, RegionMode region) {
    final cs = Theme.of(context).colorScheme;
    final isKr = region == RegionMode.kr;
    final currencyUnit = isKr ? '원' : 'KRW';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Coin selector
        StyledDropdown<String>(
          label: isKr ? '코인 선택' : 'Select Coin',
          value: state.selectedCoin,
          items: coinLabels.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontSize: 16)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              ref.read(cryptoProvider.notifier).setSelectedCoin(v);
            }
          },
        ),

        const SizedBox(height: 16),

        // Current price display
        if (state.currentCoinPrice != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isKr
                      ? '현재 ${coinSymbols[state.selectedCoin] ?? ''} 시세'
                      : 'Current ${coinSymbols[state.selectedCoin] ?? ''} Price',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${_krwFmt.format(state.currentCoinPrice!)} $currencyUnit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Direction toggle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKr ? '변환 방향' : 'Direction',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text(
                      isKr
                          ? '원화 → ${coinSymbols[state.selectedCoin] ?? '코인'}'
                          : 'KRW → ${coinSymbols[state.selectedCoin] ?? 'Coin'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text(
                      isKr
                          ? '${coinSymbols[state.selectedCoin] ?? '코인'} → 원화'
                          : '${coinSymbols[state.selectedCoin] ?? 'Coin'} → KRW',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
                selected: {state.isKrwToCoin},
                onSelectionChanged: (v) {
                  ref.read(cryptoProvider.notifier).toggleDirection();
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: cs.surfaceContainerLow,
                  selectedBackgroundColor: cs.primary,
                  selectedForegroundColor: cs.onPrimary,
                  foregroundColor: cs.onSurface,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Amount input
        LabeledInputField(
          label: state.isKrwToCoin
              ? (isKr ? '금액 (원)' : 'Amount (KRW)')
              : (isKr ? '코인 수량' : 'Coin Quantity'),
          hint: state.isKrwToCoin
              ? (isKr ? '원화 금액을 입력하세요' : 'Enter KRW amount')
              : (isKr ? '코인 수량을 입력하세요' : 'Enter coin quantity'),
          suffix: state.isKrwToCoin
              ? currencyUnit
              : coinSymbols[state.selectedCoin] ?? '',
          controller: _amountController,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(cryptoProvider.notifier).setAmount(parsed);
          },
        ),

        const SizedBox(height: 24),

        // Loading
        if (state.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: cs.primary),
            ),
          ),

        // Error
        if (state.error != null) _buildErrorBox(state.error!),

        // Result
        if (state.result != null && !state.isLoading)
          ResultDisplayCard(
            label: isKr ? '변환 결과' : 'Conversion Result',
            value: state.isKrwToCoin
                ? _coinFmt.format(state.result!)
                : _krwFmt.format(state.result!),
            unit: state.isKrwToCoin
                ? coinSymbols[state.selectedCoin] ?? ''
                : currencyUnit,
            accentColor: cs.primary,
          ),
      ],
    );
  }

  // --- Tab 2: Past Simulation (BTC only) ---

  Widget _buildSimulationTab(CryptoState state, RegionMode region) {
    final cs = Theme.of(context).colorScheme;
    final isKr = region == RegionMode.kr;
    final currencyUnit = isKr ? '원' : 'KRW';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: cs.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isKr
                      ? '과거 특정 날짜에 비트코인에 투자했다면 현재 얼마가 되었을지 계산합니다.'
                      : 'Calculate how much your Bitcoin investment on a past date would be worth today.',
                  style: TextStyle(fontSize: 14, color: cs.onPrimaryContainer),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Date picker
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKr ? '투자한 날짜' : 'Investment Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      state.simulationDate ?? DateTime(2020, 1, 1),
                  firstDate: DateTime(2013, 1, 1),
                  lastDate:
                      DateTime.now().subtract(const Duration(days: 1)),
                  helpText: isKr ? '투자 날짜 선택' : 'Select Investment Date',
                  cancelText: isKr ? '취소' : 'Cancel',
                  confirmText: isKr ? '선택' : 'Select',
                );
                if (picked != null) {
                  ref
                      .read(cryptoProvider.notifier)
                      .setSimulationDate(picked);
                }
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.simulationDate != null
                          ? (isKr
                              ? DateFormat('yyyy년 MM월 dd일')
                                  .format(state.simulationDate!)
                              : DateFormat('MMM dd, yyyy')
                                  .format(state.simulationDate!))
                          : (isKr ? '날짜를 선택하세요' : 'Select a date'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: state.simulationDate != null
                            ? cs.onSurface
                            : cs.onSurfaceVariant.withAlpha(120),
                      ),
                    ),
                    Icon(Icons.calendar_today,
                        color: cs.primary, size: 22),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Amount input
        LabeledInputField(
          label: isKr ? '투자 금액' : 'Investment Amount',
          hint: isKr ? '원화 금액을 입력하세요' : 'Enter KRW amount',
          suffix: currencyUnit,
          controller: _simAmountController,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(cryptoProvider.notifier).setSimulationAmount(parsed);
          },
        ),

        const SizedBox(height: 20),

        // Calculate button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: state.isSimulationLoading
                ? null
                : () {
                    ref.read(cryptoProvider.notifier).runSimulation();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            child: state.isSimulationLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(isKr ? '시뮬레이션 실행' : 'Run Simulation'),
          ),
        ),

        const SizedBox(height: 24),

        // Simulation error
        if (state.simulationError != null)
          _buildErrorBox(state.simulationError!),

        // Simulation results
        if (state.historicalPrice != null && !state.isSimulationLoading) ...[
          ResultDisplayCard(
            label: isKr ? '당시 비트코인 가격' : 'BTC Price at That Time',
            value: _krwFmt.format(state.historicalPrice!),
            unit: currencyUnit,
          ),
          const SizedBox(height: 12),
          ResultDisplayCard(
            label: isKr ? '구매한 BTC 수량' : 'BTC Purchased',
            value: _coinFmt.format(state.btcBought ?? 0),
            unit: 'BTC',
          ),
          const SizedBox(height: 12),
          ResultDisplayCard(
            label: isKr ? '현재 가치' : 'Current Value',
            value: _krwFmt.format(state.currentValue ?? 0),
            unit: currencyUnit,
            accentColor: cs.primary,
          ),
          const SizedBox(height: 12),
          ResultDisplayCard(
            label: isKr ? '수익률' : 'Return Rate',
            value: _percentFmt.format(state.profitPercent ?? 0),
            unit: '%',
            accentColor: (state.profitPercent ?? 0) >= 0
                ? const Color(0xFF43A047)
                : cs.error,
          ),
        ],
      ],
    );
  }

  // --- Shared error box ---

  Widget _buildErrorBox(String message) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 15, color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
