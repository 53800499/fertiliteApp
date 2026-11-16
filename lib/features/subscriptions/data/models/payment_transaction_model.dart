class PaymentTransactionModel {
  final String transactionId;
  final String? token;
  final String checkoutUrl;
  final double amount;
  final String devise;
  final String plan;
  final String mode;
  final String message;

  const PaymentTransactionModel({
    required this.transactionId,
    this.token,
    required this.checkoutUrl,
    required this.amount,
    required this.devise,
    required this.plan,
    required this.mode,
    required this.message,
  });

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionModel(
      transactionId: (json['transactionId'] ?? json['id'] ?? '').toString(),
      token: json['token']?.toString(),
      checkoutUrl: (json['checkoutUrl'] ?? json['url'] ?? '').toString(),
      amount: _parseDouble(json['amount'] ?? json['montant']),
      devise: (json['devise'] ?? json['currency'] ?? 'XOF').toString(),
      plan: (json['plan'] ?? 'premium_mensuel').toString(),
      mode: (json['mode'] ?? 'fedapay').toString(),
      message: (json['message'] ?? 'Transaction FedaPay prête.').toString(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
