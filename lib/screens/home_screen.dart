import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart' as app; // Menggunakan alias untuk menghindari konflik nama
import '../services/supabase_service.dart';

// Definisikan konstanta di luar kelas agar mudah diakses
const List<String> categories = ['Makanan', 'Transportasi', 'Tagihan', 'Gaji', 'Hiburan', 'Lainnya'];
const List<String> transactionTypes = ['expense', 'income'];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<app.Transaction>> _transactionsFuture;

  // State untuk data dinamis
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshData(); // Memuat data saat pertama kali layar dibuka
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fungsi untuk memuat ulang semua data dari Supabase dan menghitung total
  Future<void> _refreshData() async {
    setState(() {
      _transactionsFuture = _supabaseService.getTransactions();
    });
    // Tunggu data selesai diambil, lalu hitung totalnya
    await _calculateTotals();
  }

  Future<void> _calculateTotals() async {
    // Mengambil data dari future yang sedang berjalan
    List<app.Transaction> transactions = await _transactionsFuture;
    double income = 0;
    double expense = 0;

    for (var trx in transactions) {
      if (trx.type == 'income') {
        income += trx.amount;
      } else {
        expense += trx.amount;
      }
    }

    // Update state agar UI ikut berubah
    setState(() {
      _totalIncome = income;
      _totalExpense = expense;
      _totalBalance = income - expense;
    });
  }

  // Form untuk Tambah/Edit Transaksi (dari kode lama)
  void _showForm(app.Transaction? transaction) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(text: transaction?.amount.toString());
    final descriptionController = TextEditingController(text: transaction?.description);
    String selectedCategory = transaction?.category ?? categories.first;
    String selectedType = transaction?.type ?? 'expense'; // Default ke pengeluaran
    DateTime selectedDate = transaction?.transactionDate ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(transaction == null ? 'Tambah Transaksi' : 'Edit Transaksi', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center,),
              const SizedBox(height: 20),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah (Rp)', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.isEmpty || double.tryParse(value) == null) ? 'Masukkan jumlah yang valid' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (value) => selectedCategory = value!,
                      decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedType,
                      items: transactionTypes.map((t) => DropdownMenuItem(value: t, child: Text(t == 'income' ? 'Pemasukan' : 'Pengeluaran'))).toList(),
                      onChanged: (value) => selectedType = value!,
                      decoration: const InputDecoration(labelText: 'Tipe', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF4A56E2),
                    foregroundColor: Colors.white
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newTransaction = app.Transaction(
                      id: transaction?.id ?? 0,
                      amount: double.parse(amountController.text),
                      category: selectedCategory,
                      description: descriptionController.text,
                      type: selectedType,
                      transactionDate: selectedDate,
                    );
                    try {
                      if (transaction == null) {
                        await _supabaseService.addTransaction(newTransaction);
                      } else {
                        await _supabaseService.updateTransaction(newTransaction);
                      }
                      Navigator.pop(context);
                      _refreshData(); // Panggil refresh data setelah berhasil
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red,));
                    }
                  }
                },
                child: Text(transaction == null ? 'Simpan' : 'Update'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: RefreshIndicator( // Menambahkan fitur pull-to-refresh
          onRefresh: _refreshData,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 30),
              _buildBalanceCard(), // Kartu saldo sekarang dinamis
              const SizedBox(height: 30),
              _buildTabBar(),
              SizedBox(
                // Batasi tinggi agar tidak error
                height: MediaQuery.of(context).size.height * 0.4,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionList('expense'), // Tab untuk Pengeluaran
                    _buildTransactionList('income'),  // Tab untuk Pemasukan
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(null), // Memanggil form tambah
        backgroundColor: const Color(0xFF4A56E2),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // --- WIDGET-WIDGET UNTUK UI BARU ---

  Widget _buildHeader() {
    return const Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage('https://i.imgur.com/r3n2zEw.png'),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rafi Naufal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('raffnr265', style: TextStyle(color: Colors.grey)),
          ],
        )
      ],
    );
  }

  Widget _buildBalanceCard() {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF4A56E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total saldo', style: TextStyle(color: Colors.white70, fontSize: 16)),
              // Persentase bisa ditambahkan nanti jika ada datanya
            ],
          ),
          const SizedBox(height: 8),
          Text(currencyFormatter.format(_totalBalance), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.grey,
      indicatorColor: const Color(0xFF4A56E2),
      indicatorWeight: 3,
      tabs: const [
        Tab(text: 'Pengeluaran'),
        Tab(text: 'Pemasukan'),
      ],
    );
  }

  // Daftar transaksi sekarang menggunakan FutureBuilder
  Widget _buildTransactionList(String type) {
    return FutureBuilder<List<app.Transaction>>(
      future: _transactionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Belum ada transaksi.'));
        }

        // Filter transaksi berdasarkan tipe (income/expense)
        final transactions = snapshot.data!.where((trx) => trx.type == type).toList();

        if (transactions.isEmpty) {
          return Center(child: Text('Tidak ada data ${type == 'expense' ? 'pengeluaran' : 'pemasukan'}.'));
        }

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionItem(transaction);
          },
        );
      },
    );
  }

  // Item transaksi sekarang menerima objek Transaction
  Widget _buildTransactionItem(app.Transaction transaction) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            transaction.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
            color: transaction.type == 'income' ? Colors.green : Colors.red,
          ),
        ),
        title: Text(transaction.description, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(transaction.category),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                currencyFormatter.format(transaction.amount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            Text(
                dateFormatter.format(transaction.transactionDate),
                style: const TextStyle(color: Colors.grey, fontSize: 12)
            ),
          ],
        ),
        onTap: () => _showForm(transaction), // Edit on tap

        // --- PERUBAHAN UTAMA ADA DI SINI ---
        onLongPress: () {
          // Menampilkan dialog konfirmasi
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Konfirmasi Hapus'),
                content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
                actions: <Widget>[
                  // Tombol Batal
                  TextButton(
                    child: const Text('Batal'),
                    onPressed: () {
                      Navigator.of(context).pop(); // Tutup dialog
                    },
                  ),
                  // Tombol Hapus
                  TextButton(
                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                    onPressed: () async {
                      // Logika penghapusan dipindahkan ke sini
                      await _supabaseService.deleteTransaction(transaction.id);
                      Navigator.of(context).pop(); // Tutup dialog setelah menghapus
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaksi berhasil dihapus'))
                      );
                      _refreshData(); // Refresh data untuk memperbarui UI
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: const Icon(Icons.home, color: Color(0xFF4A56E2)), onPressed: () {}),
          IconButton(icon: const Icon(Icons.calendar_today, color: Colors.grey), onPressed: () {}),
          const SizedBox(width: 48), // Ruang untuk FAB
          IconButton(icon: const Icon(Icons.account_balance_wallet, color: Colors.grey), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person, color: Colors.grey), onPressed: () {}),
        ],
      ),
    );
  }
}