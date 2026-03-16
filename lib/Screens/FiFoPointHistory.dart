import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Supabase Service Layer ---
class PointsService {
  final supabase = Supabase.instance.client;

  Future<List<PointLedgerBatch>> getUserPointsHistory() async {
    try {
      // v_user_points_fifo သည် သင်၏ Supabase SQL View ဖြစ်ရပါမည်
      // logic အနေနဲ့ လက်ရှိ login ဝင်ထားသော user ၏ data ကိုသာ ယူမည်
      final response = await supabase
          .from('v_user_points_fifo')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .order(
            'expires_at',
            ascending: true,
          ); // သက်တမ်းကုန်ခါနီးကို အပေါ်တင်သည်

      return (response as List)
          .map((data) => PointLedgerBatch.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Points အချက်အလက်များ ဖတ်၍မရပါ: $e');
    }
  }
}

// --- Data Model ---
class PointLedgerBatch {
  final int ledgerId;
  final String stationName;
  final String fuelType;
  final int earnedPoints;
  final int remainingPoints;
  final int usedPoints;
  final DateTime expiresAt;
  final DateTime earnedAt;
  final int daysUntilExpiry;
  final String status;

  PointLedgerBatch({
    required this.ledgerId,
    required this.stationName,
    required this.fuelType,
    required this.earnedPoints,
    required this.remainingPoints,
    required this.usedPoints,
    required this.expiresAt,
    required this.earnedAt,
    required this.daysUntilExpiry,
    required this.status,
  });

  factory PointLedgerBatch.fromMap(Map<String, dynamic> map) {
    return PointLedgerBatch(
      ledgerId: map['ledger_id'] ?? 0,
      stationName: map['station_name'] ?? 'Unknown Station',
      fuelType: map['fuel_type'] ?? 'Fuel',
      earnedPoints: map['earned_points'] ?? 0,
      remainingPoints: map['remaining_points'] ?? 0,
      usedPoints: map['used_points'] ?? 0,
      expiresAt: DateTime.parse(
        map['expires_at'] ?? DateTime.now().toIso8601String(),
      ),
      earnedAt: DateTime.parse(
        map['earned_at'] ?? DateTime.now().toIso8601String(),
      ),
      daysUntilExpiry: map['days_until_expiry'] ?? 0,
      status: map['status'] ?? 'ACTIVE',
    );
  }
}

// --- UI Layer ---
class FifoPointsScreen extends StatefulWidget {
  const FifoPointsScreen({super.key});

  @override
  State<FifoPointsScreen> createState() => _FifoPointsScreenState();
}

class _FifoPointsScreenState extends State<FifoPointsScreen> {
  final PointsService _pointsService = PointsService();
  late Future<List<PointLedgerBatch>> _pointsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _pointsFuture = _pointsService.getUserPointsHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'FIFO Points Tracker',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        elevation: 0,
        iconTheme: theme.iconTheme,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: Icon(Icons.refresh, color: colorScheme.primary),
          ),
        ],
      ),
      body: FutureBuilder<List<PointLedgerBatch>>(
        future: _pointsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(snapshot.error.toString()),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('ထပ်မံကြိုးစားမည်'),
                  ),
                ],
              ),
            );
          }

          final batches = snapshot.data ?? [];

          if (batches.isEmpty) {
            return const Center(child: Text('Points မရှိသေးပါ'));
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: batches.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildHeaderCard(batches);
                return _buildBatchCard(batches[index - 1]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(List<PointLedgerBatch> batches) {
    int totalRemaining = batches.fold(
      0,
      (sum, item) => sum + item.remainingPoints,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'စုစုပေါင်း လက်ကျန် Points',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat('#,###').format(totalRemaining),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const Text(
            'FIFO စနစ်ဖြင့် သက်တမ်းကုန်ခါနီးများကို အရင်နှုတ်ပါမည်။',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchCard(PointLedgerBatch batch) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isExpiringSoon = batch.status == 'EXPIRING_SOON';
    final Color statusColor = isExpiringSoon
        ? Colors.orange
        : colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: theme.brightness == Brightness.dark ? 2 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              batch.stationName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${batch.fuelType} | ရရှိရက်: ${DateFormat('dd-MM-yyyy').format(batch.earnedAt)}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${batch.remainingPoints}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  'Points ကျန်',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: batch.remainingPoints / batch.earnedPoints,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: isExpiringSoon ? Colors.orange : theme.hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'သက်တမ်းကုန်ရန်: ${batch.daysUntilExpiry} ရက်',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isExpiringSoon
                            ? Colors.orange[800]
                            : theme.hintColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Expired: ${DateFormat('dd MMM yyyy').format(batch.expiresAt)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
