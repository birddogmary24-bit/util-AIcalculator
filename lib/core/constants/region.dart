enum RegionMode { kr, global }

class AppStrings {
  AppStrings._();

  static Map<String, String> of(RegionMode region) {
    switch (region) {
      case RegionMode.kr:
        return _kr;
      case RegionMode.global:
        return _en;
    }
  }

  static const Map<String, String> _kr = {
    // Main app
    'app_title': 'AI 계산기',
    'app_title_display': '알뜰계산기.AI',

    // Calculator screen
    'tools_tooltip': '도구 모음',
    'settings_tooltip': '설정',
    'api_key_tooltip': 'API 키 설정',
    'history_tooltip': '기록',
    'api_key_dialog_title': 'Gemini API 키 설정',
    'api_key_dialog_desc':
        'AI 기능(자연어 계산, 맥락 해석, 스마트 기록)을 사용하려면 Google Gemini API 키가 필요합니다.',
    'api_key_hint': 'Gemini API 키를 입력하세요',

    // Common
    'cancel': '취소',
    'save': '저장',
    'delete': '삭제',
    'reset': '초기화',
    'confirm': '확인',

    // Natural language bar
    'listening': '듣고 있습니다...',
    'ai_loading': '계산하는 중.....',
    'ask_ai': 'AI한테 물어서 계산하세요',
    'set_api_key_hint': 'AI 기능을 위해 API 키를 설정하세요',

    // Display panel
    'copy': '복사',
    'copied': '복사됨',
    'calc_error': '계산 오류',

    // Button grid
    'button_hint': '버튼을 길게 누르면 설정/변경 가능',

    // Button swap modal
    'select_button': '버튼 선택',
    'button_swap_hint': '계산기 화면에서 버튼을 길게 누를 경우 재설정이 가능합니다.',
    'reset_layout': '버튼 설정 초기화',

    // Button categories
    'bcat_digits': '숫자',
    'bcat_operators': '연산',
    'bcat_functions': '기능',
    'bcat_tools': '도구',

    // Utility row placeholders
    'util_advanced': '고급계산',
    'util_slot': '설정',

    // History screen
    'calc_history': '계산 기록',
    'delete_all': '전체 삭제',
    'search_hint': '기록 검색 (레이블, 숫자)',
    'today': '오늘',
    'yesterday': '어제',
    'no_results': '검색 결과가 없습니다',
    'no_history': '아직 계산 기록이 없습니다',
    'auto_save_hint': '계산기 탭에서 계산하면\n자동으로 저장됩니다',
    'confirm_delete_all_title': '전체 삭제',
    'confirm_delete_all': '모든 계산 기록을 삭제할까요?',

    // AI Chat screen
    'ai_assistant': 'AI 도우미',
    'reset_chat': '대화 초기화',
    'chat_welcome':
        '안녕하세요! AI 계산 도우미입니다.\n\n계산에 관한 무엇이든 물어보세요.\n예: "15만원짜리 물건을 30% 할인하면 얼마야?"',
    'chat_error': '죄송해요, 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
    'ai_limit_reached': '오늘 AI 사용 한도에 도달했습니다. 내일 다시 시도해주세요.',
    'chat_reset_msg': '대화가 초기화되었습니다. 새로운 계산 질문을 해보세요!',
    'api_key_banner': 'AI 기능을 사용하려면 계산기 탭에서 API 키를 설정하세요',
    'go_settings': '설정하기',
    'to_calculator': '계산기로',
    'chat_input_hint': '계산 질문을 입력하세요...',
    'set_api_first': 'API 키를 먼저 설정하세요',

    // Settings screen
    'settings_title': '설정',
    'reset_layout_title': '버튼 배치 초기화',
    'reset_layout_desc': '계산기 버튼을 기본 배치로 되돌립니다',
    'reset_confirm': '버튼 배치를 기본값으로 되돌리시겠습니까?',
    'reset_done': '버튼 배치가 초기화되었습니다',
    'region_title': '지역 설정',
    'region_kr': '한국',
    'region_global': '해외',
    'region_change_title': '지역 변경',
    'region_change_desc': '지역을 변경하면 언어와 도구가 변경됩니다. 변경하시겠습니까?',
    'language_title': '언어',
    'currency_title': '기본 통화',
    'units_title': '단위 시스템',
    'units_metric': '미터법 (cm/kg)',
    'units_imperial': '야드파운드법 (in/lb)',
    'date_format_title': '날짜 형식',

    // Tools menu
    'tools_title': '계산기 더보기',
    'cat_finance': '금융',
    'cat_realestate': '부동산/세금',
    'cat_datetime': '날짜/시간',
    'cat_lifestyle': '생활',
    'cat_other': '기타',

    // Tool labels
    'tool_currency': '환율',
    'tool_crypto': '코인',
    'tool_discount': '할인',
    'tool_vat': '부가세',
    'tool_loan': '대출 이자',
    'tool_capital_gains_tax': '양도세',
    'tool_brokerage_fee': '부동산/복비',
    'tool_dday': 'D-day',
    'tool_birthday': '생일 기억',
    'tool_world_clock': '세계시간',
    'tool_unit': '단위',
    'tool_bmi': '비만도(BMI)',
    'tool_fuel': '연비',
    'tool_period': '생리주기',
    'tool_base_converter': '진수 변환',
    'tool_tip': '팁 계산',
    'tool_sales_tax': '판매세',
    'tool_split_bill': '더치페이',

    // Tool descriptions
    'tool_currency_desc': '실시간 환율 계산',
    'tool_crypto_desc': '암호화폐 시세',
    'tool_discount_desc': '할인가 계산',
    'tool_vat_desc': '부가세 역산',
    'tool_loan_desc': '대출 상환 계산',
    'tool_capital_gains_tax_desc': '양도소득세 계산',
    'tool_brokerage_fee_desc': '중개수수료 계산',
    'tool_dday_desc': '날짜 계산',
    'tool_birthday_desc': '생일 알림',
    'tool_world_clock_desc': '세계 시간 변환',
    'tool_unit_desc': '단위 변환',
    'tool_bmi_desc': 'BMI·기초대사량',
    'tool_fuel_desc': '연료 효율 계산',
    'tool_period_desc': '생리주기 예측',
    'tool_base_converter_desc': '2·8·10·16진수',
    'tool_tip_desc': '팁 계산기',
    'tool_sales_tax_desc': '판매세 계산',
    'tool_split_bill_desc': '더치페이 계산',

    // Button labels for tool buttons
    'btn_currency': '환율',
    'btn_crypto': '코인',
    'btn_discount': '할인',
    'btn_vat': '부가세',
    'btn_loan': '대출',
    'btn_capital_gains_tax': '양도세',
    'btn_brokerage_fee': '복비',
    'btn_dday': 'D-day',
    'btn_birthday': '생일',
    'btn_world_clock': '시계',
    'btn_unit': '단위',
    'btn_bmi': 'BMI',
    'btn_fuel': '연비',
    'btn_period': '생리',
    'btn_base_converter': '진법',
    'btn_tip': '팁',
    'btn_sales_tax': '세금',
    'btn_split_bill': '더치',

    // Onboarding
    'onboarding_title': '지역을 선택해주세요',
    'onboarding_subtitle': '선택에 따라 언어와 기능이 맞춤 설정됩니다',
    'onboarding_kr': '한국',
    'onboarding_kr_desc': '한국어 UI, 부동산/세금 계산기 포함',
    'onboarding_global': '해외',
    'onboarding_global_desc': '영어 UI, 팁/판매세 계산기 포함',
  };

  static const Map<String, String> _en = {
    // Main app
    'app_title': 'SmartCalc.AI',
    'app_title_display': 'SmartCalc.AI',

    // Calculator screen
    'tools_tooltip': 'Tools',
    'settings_tooltip': 'Settings',
    'api_key_tooltip': 'API Key',
    'history_tooltip': 'History',
    'api_key_dialog_title': 'Gemini API Key',
    'api_key_dialog_desc':
        'You need a Google Gemini API key to use AI features (NLP calculations, context tips, smart history).',
    'api_key_hint': 'Enter your Gemini API key',

    // Common
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'reset': 'Reset',
    'confirm': 'Confirm',

    // Natural language bar
    'listening': 'Listening...',
    'ai_loading': 'Calculating.....',
    'ask_ai': 'Ask AI to calculate',
    'set_api_key_hint': 'Set API key for AI features',

    // Display panel
    'copy': 'Copy',
    'copied': 'Copied',
    'calc_error': 'Error',

    // Button grid
    'button_hint': 'Long press to configure/change buttons',

    // Button swap modal
    'select_button': 'Select Button',
    'button_swap_hint': 'Long press any button on the calculator to reassign it.',
    'reset_layout': 'Reset Button Settings',

    // Button categories
    'bcat_digits': 'Digits',
    'bcat_operators': 'Operators',
    'bcat_functions': 'Functions',
    'bcat_tools': 'Tools',

    // Utility row placeholders
    'util_advanced': 'Advanced',
    'util_slot': 'Slot',

    // History screen
    'calc_history': 'History',
    'delete_all': 'Delete All',
    'search_hint': 'Search history (labels, numbers)',
    'today': 'Today',
    'yesterday': 'Yesterday',
    'no_results': 'No results found',
    'no_history': 'No calculation history yet',
    'auto_save_hint': 'Calculations are\nautomatically saved',
    'confirm_delete_all_title': 'Delete All',
    'confirm_delete_all': 'Delete all calculation history?',

    // AI Chat screen
    'ai_assistant': 'AI Assistant',
    'reset_chat': 'Reset Chat',
    'chat_welcome':
        'Hello! I\'m your AI calculator assistant.\n\nAsk me anything about calculations.\nEx: "What is 30% off a \$150 item?"',
    'chat_error': 'Sorry, an error occurred. Please try again.',
    'ai_limit_reached': 'Daily AI limit reached. Please try again tomorrow.',
    'chat_reset_msg': 'Chat has been reset. Ask a new calculation question!',
    'api_key_banner':
        'Set your API key in the calculator tab to use AI features',
    'go_settings': 'Set Up',
    'to_calculator': 'To Calc',
    'chat_input_hint': 'Ask a calculation question...',
    'set_api_first': 'Set API key first',

    // Settings screen
    'settings_title': 'Settings',
    'reset_layout_title': 'Reset Button Layout',
    'reset_layout_desc': 'Restore calculator buttons to default',
    'reset_confirm': 'Reset button layout to default?',
    'reset_done': 'Button layout has been reset',
    'region_title': 'Region',
    'region_kr': 'Korea',
    'region_global': 'Global',
    'region_change_title': 'Change Region',
    'region_change_desc':
        'Changing region will update language and tools. Continue?',
    'language_title': 'Language',
    'currency_title': 'Default Currency',
    'units_title': 'Unit System',
    'units_metric': 'Metric (cm/kg)',
    'units_imperial': 'Imperial (in/lb)',
    'date_format_title': 'Date Format',

    // Tools menu
    'tools_title': 'More Calculators',
    'cat_finance': 'Finance',
    'cat_realestate': 'Real Estate / Tax',
    'cat_datetime': 'Date & Time',
    'cat_lifestyle': 'Lifestyle',
    'cat_other': 'Other',

    // Tool labels
    'tool_currency': 'Exchange',
    'tool_crypto': 'Crypto',
    'tool_discount': 'Discount',
    'tool_vat': 'VAT',
    'tool_loan': 'Loan',
    'tool_capital_gains_tax': 'Cap. Gains',
    'tool_brokerage_fee': 'Brokerage',
    'tool_dday': 'D-day',
    'tool_birthday': 'Birthday',
    'tool_world_clock': 'World Clock',
    'tool_unit': 'Units',
    'tool_bmi': 'BMI',
    'tool_fuel': 'Fuel',
    'tool_period': 'Period',
    'tool_base_converter': 'Base Conv.',
    'tool_tip': 'Tip Calc',
    'tool_sales_tax': 'Sales Tax',
    'tool_split_bill': 'Split Bill',

    // Tool descriptions
    'tool_currency_desc': 'Real-time exchange rates',
    'tool_crypto_desc': 'Cryptocurrency prices',
    'tool_discount_desc': 'Discount calculator',
    'tool_vat_desc': 'VAT calculator',
    'tool_loan_desc': 'Loan repayment',
    'tool_capital_gains_tax_desc': 'Capital gains tax',
    'tool_brokerage_fee_desc': 'Brokerage fee',
    'tool_dday_desc': 'Date calculator',
    'tool_birthday_desc': 'Birthday reminder',
    'tool_world_clock_desc': 'World time conversion',
    'tool_unit_desc': 'Unit conversion',
    'tool_bmi_desc': 'BMI & Metabolic rate',
    'tool_fuel_desc': 'Fuel efficiency',
    'tool_period_desc': 'Period prediction',
    'tool_base_converter_desc': '2·8·10·16 base',
    'tool_tip_desc': 'Tip calculator',
    'tool_sales_tax_desc': 'Sales tax calculator',
    'tool_split_bill_desc': 'Split the bill',

    // Button labels for tool buttons
    'btn_currency': 'FX',
    'btn_crypto': 'Crypto',
    'btn_discount': 'Disc.',
    'btn_vat': 'VAT',
    'btn_loan': 'Loan',
    'btn_capital_gains_tax': 'CGT',
    'btn_brokerage_fee': 'Brkrg',
    'btn_dday': 'D-day',
    'btn_birthday': 'B-day',
    'btn_world_clock': 'Clock',
    'btn_unit': 'Unit',
    'btn_bmi': 'BMI',
    'btn_fuel': 'Fuel',
    'btn_period': 'Period',
    'btn_base_converter': 'Base',
    'btn_tip': 'Tip',
    'btn_sales_tax': 'Tax',
    'btn_split_bill': 'Split',

    // Onboarding
    'onboarding_title': 'Select your region',
    'onboarding_subtitle': 'Language and features will be customized',
    'onboarding_kr': 'Korea',
    'onboarding_kr_desc': 'Korean UI with real estate & tax tools',
    'onboarding_global': 'Global',
    'onboarding_global_desc': 'English UI with tip & sales tax tools',
  };
}
