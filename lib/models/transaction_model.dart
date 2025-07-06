// lib/models/transaction_model.dart
class Transaction {
  final int id;
  final double amount;
  final String category;
  final String description;
  final String type; // 'income' or 'expense'
  final DateTime transactionDate;

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.type,
    required this.transactionDate,
  });

  // Konversi dari JSON (data dari Supabase) ke objek Transaction
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      description: json['description'],
      type: json['type'],
      transactionDate: DateTime.parse(json['transaction_date']),
    );
  }

  // Konversi dari objek Transaction ke JSON (untuk dikirim ke Supabase)
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'category': category,
      'description': description,
      'type': type,
      'transaction_date': transactionDate.toIso8601String(),
    };
  }
}