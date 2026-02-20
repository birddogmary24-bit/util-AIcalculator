import 'package:flutter/material.dart';
import '../../domain/models/tool_definition.dart';

/// Category order for display
const toolCategories = ['금융', '부동산/세금', '날짜/시간', '생활', '기타'];

const toolRegistry = <ToolDefinition>[
  // ── 금융 ─────────────────────────────────────────────────────
  ToolDefinition(
    id: 'currency',
    routePath: 'currency',
    label: '환율',
    description: '실시간 환율 계산',
    icon: Icons.currency_exchange,
    color: Color(0xFF4A6FA5),
    category: '금융',
  ),
  ToolDefinition(
    id: 'crypto',
    routePath: 'crypto',
    label: '코인',
    description: '암호화폐 시세',
    icon: Icons.currency_bitcoin,
    color: Color(0xFFF7931A),
    category: '금융',
  ),
  ToolDefinition(
    id: 'discount',
    routePath: 'discount',
    label: '할인',
    description: '할인가 계산',
    icon: Icons.discount,
    color: Color(0xFFE91E63),
    category: '금융',
  ),
  ToolDefinition(
    id: 'vat',
    routePath: 'vat',
    label: '부가세',
    description: '부가세 역산',
    icon: Icons.receipt_long,
    color: Color(0xFF00897B),
    category: '금융',
  ),

  // ── 부동산/세금 ──────────────────────────────────────────────
  ToolDefinition(
    id: 'loan',
    routePath: 'loan',
    label: '대출 이자',
    description: '대출 상환 계산',
    icon: Icons.account_balance,
    color: Color(0xFF6D4C41),
    category: '부동산/세금',
  ),
  ToolDefinition(
    id: 'capital-gains-tax',
    routePath: 'capital-gains-tax',
    label: '양도세',
    description: '양도소득세 계산',
    icon: Icons.gavel,
    color: Color(0xFF7B1FA2),
    category: '부동산/세금',
  ),
  ToolDefinition(
    id: 'brokerage-fee',
    routePath: 'brokerage-fee',
    label: '부동산/복비',
    description: '중개수수료 계산',
    icon: Icons.home_work,
    color: Color(0xFF3E2723),
    category: '부동산/세금',
  ),

  // ── 날짜/시간 ────────────────────────────────────────────────
  ToolDefinition(
    id: 'dday',
    routePath: 'dday',
    label: 'D-day',
    description: '날짜 계산',
    icon: Icons.event,
    color: Color(0xFFFF6F00),
    category: '날짜/시간',
  ),
  ToolDefinition(
    id: 'birthday',
    routePath: 'birthday',
    label: '생일 기억',
    description: '생일 알림',
    icon: Icons.cake,
    color: Color(0xFFD81B60),
    category: '날짜/시간',
  ),
  ToolDefinition(
    id: 'world-clock',
    routePath: 'world-clock',
    label: '세계시간',
    description: '세계 시간 변환',
    icon: Icons.public,
    color: Color(0xFF0288D1),
    category: '날짜/시간',
  ),

  // ── 생활 ─────────────────────────────────────────────────────
  ToolDefinition(
    id: 'unit',
    routePath: 'unit',
    label: '단위',
    description: '단위 변환',
    icon: Icons.straighten,
    color: Color(0xFF5C6BC0),
    category: '생활',
  ),
  ToolDefinition(
    id: 'bmi',
    routePath: 'bmi',
    label: '비만도(BMI)',
    description: 'BMI·기초대사량',
    icon: Icons.monitor_weight,
    color: Color(0xFF43A047),
    category: '생활',
  ),
  ToolDefinition(
    id: 'fuel',
    routePath: 'fuel',
    label: '연비',
    description: '연료 효율 계산',
    icon: Icons.local_gas_station,
    color: Color(0xFF455A64),
    category: '생활',
  ),

  // ── 기타 ─────────────────────────────────────────────────────
  ToolDefinition(
    id: 'period',
    routePath: 'period',
    label: '생리주기',
    description: '생리주기 예측',
    icon: Icons.favorite,
    color: Color(0xFFEC407A),
    category: '기타',
  ),
  ToolDefinition(
    id: 'base-converter',
    routePath: 'base-converter',
    label: '진수 변환',
    description: '2·8·10·16진수',
    icon: Icons.code,
    color: Color(0xFF37474F),
    category: '기타',
  ),
];
