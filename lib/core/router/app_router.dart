import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/calculator/calculator_screen.dart';
import '../../presentation/history/history_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/tools/tools_menu_screen.dart';

// Tool screens
import '../../presentation/tools/currency/currency_screen.dart';
import '../../presentation/tools/crypto/crypto_screen.dart';
import '../../presentation/tools/unit/unit_screen.dart';
import '../../presentation/tools/discount/discount_screen.dart';
import '../../presentation/tools/vat/vat_screen.dart';
import '../../presentation/tools/loan/loan_screen.dart';
import '../../presentation/tools/bmi/bmi_screen.dart';
import '../../presentation/tools/period/period_screen.dart';
import '../../presentation/tools/world_clock/world_clock_screen.dart';
import '../../presentation/tools/fuel/fuel_screen.dart';
import '../../presentation/tools/capital_gains_tax/capital_gains_tax_screen.dart';
import '../../presentation/tools/brokerage_fee/brokerage_fee_screen.dart';
import '../../presentation/tools/dday/dday_screen.dart';
import '../../presentation/tools/birthday/birthday_screen.dart';
import '../../presentation/tools/base_converter/base_converter_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const CalculatorScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),

    // Tools — separate routes
    GoRoute(
      path: '/tools',
      builder: (context, state) => const ToolsMenuScreen(),
      routes: [
        GoRoute(
          path: 'currency',
          builder: (_, __) => const CurrencyScreen(),
        ),
        GoRoute(
          path: 'crypto',
          builder: (_, __) => const CryptoScreen(),
        ),
        GoRoute(
          path: 'unit',
          builder: (_, __) => const UnitScreen(),
        ),
        GoRoute(
          path: 'discount',
          builder: (_, __) => const DiscountScreen(),
        ),
        GoRoute(
          path: 'vat',
          builder: (_, __) => const VatScreen(),
        ),
        GoRoute(
          path: 'loan',
          builder: (_, __) => const LoanScreen(),
        ),
        GoRoute(
          path: 'bmi',
          builder: (_, __) => const BmiScreen(),
        ),
        GoRoute(
          path: 'period',
          builder: (_, __) => const PeriodScreen(),
        ),
        GoRoute(
          path: 'world-clock',
          builder: (_, __) => const WorldClockScreen(),
        ),
        GoRoute(
          path: 'fuel',
          builder: (_, __) => const FuelScreen(),
        ),
        GoRoute(
          path: 'capital-gains-tax',
          builder: (_, __) => const CapitalGainsTaxScreen(),
        ),
        GoRoute(
          path: 'brokerage-fee',
          builder: (_, __) => const BrokerageFeeScreen(),
        ),
        GoRoute(
          path: 'dday',
          builder: (_, __) => const DdayScreen(),
        ),
        GoRoute(
          path: 'birthday',
          builder: (_, __) => const BirthdayScreen(),
        ),
        GoRoute(
          path: 'base-converter',
          builder: (_, __) => const BaseConverterScreen(),
        ),
      ],
    ),
  ],
);
