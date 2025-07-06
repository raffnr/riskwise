import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart' as app;

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // READ: Mengambil semua transaksi
  Future<List<app.Transaction>> getTransactions() async {
    final response = await _client
        .from('transactions')
        .select()
        .order('transaction_date', ascending: false);

    final List<app.Transaction> transactions = [];
    for (var record in response) {
      transactions.add(app.Transaction.fromJson(record));
    }
    return transactions;
  }

  // CREATE: Menambahkan transaksi baru
  Future<void> addTransaction(app.Transaction transaction) async {
    await _client.from('transactions').insert(transaction.toJson());
  }

  // UPDATE: Mengedit transaksi
  Future<void> updateTransaction(app.Transaction transaction) async {
    await _client
        .from('transactions')
        .update(transaction.toJson())
        .eq('id', transaction.id);
  }

  // DELETE: Menghapus transaksi
  Future<void> deleteTransaction(int id) async {
    await _client.from('transactions').delete().eq('id', id);
  }
}