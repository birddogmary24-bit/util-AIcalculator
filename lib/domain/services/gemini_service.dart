/// Shared model for NLP calculation results.
/// Used by IAiService implementations (ProxyAiService, etc.)
class NlpCalcResult {
  final String expression;
  final double value;
  final bool isError;
  final String? errorMessage;

  const NlpCalcResult({
    required this.expression,
    required this.value,
    this.isError = false,
    this.errorMessage,
  });
}
