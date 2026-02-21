import 'package:flutter/material.dart';
import '../../domain/models/tool_definition.dart';
import 'region.dart';

/// Tool category keys for localization
const toolCategoryKeys = [
  'cat_finance',
  'cat_realestate',
  'cat_datetime',
  'cat_lifestyle',
  'cat_other',
];

/// Default (Korean) tool category names in display order
const toolCategories = ['금융', '부동산/세금', '날짜/시간', '생활', '기타'];

/// Get localized category names for a region
List<String> getToolCategories(RegionMode region) {
  final s = AppStrings.of(region);
  return toolCategoryKeys.map((key) => s[key] ?? key).toList();
}

const toolRegistry = <ToolDefinition>[
  // ── Finance ────────────────────────────────────────────────────
  ToolDefinition(
    id: 'currency',
    routePath: 'currency',
    label: '환율',
    labelKey: 'tool_currency',
    descriptionKey: 'tool_currency_desc',
    description: '실시간 환율 계산',
    icon: Icons.currency_exchange,
    color: Color(0xFF4A6FA5),
    category: '금융',
    categoryKey: 'cat_finance',
  ),
  ToolDefinition(
    id: 'crypto',
    routePath: 'crypto',
    label: '코인',
    labelKey: 'tool_crypto',
    descriptionKey: 'tool_crypto_desc',
    description: '암호화폐 시세',
    icon: Icons.currency_bitcoin,
    color: Color(0xFFF7931A),
    category: '금융',
    categoryKey: 'cat_finance',
  ),
  ToolDefinition(
    id: 'discount',
    routePath: 'discount',
    label: '할인',
    labelKey: 'tool_discount',
    descriptionKey: 'tool_discount_desc',
    description: '할인가 계산',
    icon: Icons.discount,
    color: Color(0xFFE91E63),
    category: '금융',
    categoryKey: 'cat_finance',
  ),
  ToolDefinition(
    id: 'vat',
    routePath: 'vat',
    label: '부가세',
    labelKey: 'tool_vat',
    descriptionKey: 'tool_vat_desc',
    description: '부가세 역산',
    icon: Icons.receipt_long,
    color: Color(0xFF00897B),
    category: '금융',
    categoryKey: 'cat_finance',
    regions: {RegionMode.kr},
  ),

  // ── Real Estate / Tax ──────────────────────────────────────────
  ToolDefinition(
    id: 'loan',
    routePath: 'loan',
    label: '대출 이자',
    labelKey: 'tool_loan',
    descriptionKey: 'tool_loan_desc',
    description: '대출 상환 계산',
    icon: Icons.account_balance,
    color: Color(0xFF6D4C41),
    category: '부동산/세금',
    categoryKey: 'cat_realestate',
  ),
  ToolDefinition(
    id: 'capital-gains-tax',
    routePath: 'capital-gains-tax',
    label: '양도세',
    labelKey: 'tool_capital_gains_tax',
    descriptionKey: 'tool_capital_gains_tax_desc',
    description: '양도소득세 계산',
    icon: Icons.gavel,
    color: Color(0xFF7B1FA2),
    category: '부동산/세금',
    categoryKey: 'cat_realestate',
    regions: {RegionMode.kr},
  ),
  ToolDefinition(
    id: 'brokerage-fee',
    routePath: 'brokerage-fee',
    label: '부동산/복비',
    labelKey: 'tool_brokerage_fee',
    descriptionKey: 'tool_brokerage_fee_desc',
    description: '중개수수료 계산',
    icon: Icons.home_work,
    color: Color(0xFF3E2723),
    category: '부동산/세금',
    categoryKey: 'cat_realestate',
    regions: {RegionMode.kr},
  ),

  // ── Global Finance ────────────────────────────────────────────
  ToolDefinition(
    id: 'tip',
    routePath: 'tip',
    label: 'Tip',
    labelKey: 'tool_tip',
    descriptionKey: 'tool_tip_desc',
    description: 'Tip calculator',
    icon: Icons.restaurant,
    color: Color(0xFF009688),
    category: '금융',
    categoryKey: 'cat_finance',
    regions: {RegionMode.global},
  ),
  ToolDefinition(
    id: 'sales-tax',
    routePath: 'sales-tax',
    label: 'Sales Tax',
    labelKey: 'tool_sales_tax',
    descriptionKey: 'tool_sales_tax_desc',
    description: 'Sales tax calculator',
    icon: Icons.receipt_long,
    color: Color(0xFF7C4DFF),
    category: '금융',
    categoryKey: 'cat_finance',
    regions: {RegionMode.global},
  ),

  // ── Date & Time ────────────────────────────────────────────────
  ToolDefinition(
    id: 'dday',
    routePath: 'dday',
    label: 'D-day',
    labelKey: 'tool_dday',
    descriptionKey: 'tool_dday_desc',
    description: '날짜 계산',
    icon: Icons.event,
    color: Color(0xFFFF6F00),
    category: '날짜/시간',
    categoryKey: 'cat_datetime',
  ),
  ToolDefinition(
    id: 'birthday',
    routePath: 'birthday',
    label: '생일 기억',
    labelKey: 'tool_birthday',
    descriptionKey: 'tool_birthday_desc',
    description: '생일 알림',
    icon: Icons.cake,
    color: Color(0xFFD81B60),
    category: '날짜/시간',
    categoryKey: 'cat_datetime',
  ),
  ToolDefinition(
    id: 'world-clock',
    routePath: 'world-clock',
    label: '세계시간',
    labelKey: 'tool_world_clock',
    descriptionKey: 'tool_world_clock_desc',
    description: '세계 시간 변환',
    icon: Icons.public,
    color: Color(0xFF0288D1),
    category: '날짜/시간',
    categoryKey: 'cat_datetime',
  ),

  // ── Lifestyle ─────────────────────────────────────────────────
  ToolDefinition(
    id: 'unit',
    routePath: 'unit',
    label: '단위',
    labelKey: 'tool_unit',
    descriptionKey: 'tool_unit_desc',
    description: '단위 변환',
    icon: Icons.straighten,
    color: Color(0xFF5C6BC0),
    category: '생활',
    categoryKey: 'cat_lifestyle',
  ),
  ToolDefinition(
    id: 'bmi',
    routePath: 'bmi',
    label: '비만도(BMI)',
    labelKey: 'tool_bmi',
    descriptionKey: 'tool_bmi_desc',
    description: 'BMI·기초대사량',
    icon: Icons.monitor_weight,
    color: Color(0xFF43A047),
    category: '생활',
    categoryKey: 'cat_lifestyle',
  ),
  ToolDefinition(
    id: 'fuel',
    routePath: 'fuel',
    label: '연비',
    labelKey: 'tool_fuel',
    descriptionKey: 'tool_fuel_desc',
    description: '연료 효율 계산',
    icon: Icons.local_gas_station,
    color: Color(0xFF455A64),
    category: '생활',
    categoryKey: 'cat_lifestyle',
  ),
  ToolDefinition(
    id: 'split-bill',
    routePath: 'split-bill',
    label: '더치페이',
    labelKey: 'tool_split_bill',
    descriptionKey: 'tool_split_bill_desc',
    description: '더치페이 계산',
    icon: Icons.group,
    color: Color(0xFFFF7043),
    category: '생활',
    categoryKey: 'cat_lifestyle',
  ),

  // ── Other ─────────────────────────────────────────────────────
  ToolDefinition(
    id: 'period',
    routePath: 'period',
    label: '생리주기',
    labelKey: 'tool_period',
    descriptionKey: 'tool_period_desc',
    description: '생리주기 예측',
    icon: Icons.favorite,
    color: Color(0xFFEC407A),
    category: '기타',
    categoryKey: 'cat_other',
  ),
  ToolDefinition(
    id: 'base-converter',
    routePath: 'base-converter',
    label: '진수 변환',
    labelKey: 'tool_base_converter',
    descriptionKey: 'tool_base_converter_desc',
    description: '2·8·10·16진수',
    icon: Icons.code,
    color: Color(0xFF37474F),
    category: '기타',
    categoryKey: 'cat_other',
  ),
];

/// Get tools filtered by region
List<ToolDefinition> getFilteredTools(RegionMode region) {
  return toolRegistry.where((t) => t.regions.contains(region)).toList();
}
