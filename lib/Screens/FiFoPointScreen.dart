// lib/screens/points/fifo_points_screen.dart
//
// Riverpod မသုံး — Provider (ChangeNotifier / Consumer) သာ သုံးသည်
// import လိုသည်:  provider: ^6.x.x,  intl: ^0.19.x

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Models + Service တစ်ဖိုင်တည်းမှ import — fifo_models.dart မလိုဘူး
import '../../services/fifo_service.dart';
import '../../providers/fifo_points_provider.dart';

// ─────────────────────────────────────────────────────────────
// Entry point
// Navigator.push(context, MaterialPageRoute(
//   builder: (_) => const FifoPointsPage()));
// ─────────────────────────────────────────────────────────────
class FifoPointsPage extends StatelessWidget {
  const FifoPointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FifoPointsProvider()..loadAll(),
      child: const _FifoPointsScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class _FifoPointsScreen extends StatelessWidget {
  const _FifoPointsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: const Text('Points မှတ်တမ်း'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () => _showInfo(context)),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<FifoPointsProvider>().refresh(),
          ),
        ],
      ),
      body: Consumer<FifoPointsProvider>(
        builder: (context, prov, _) {
          if (prov.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (prov.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    prov.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: prov.refresh, child: const Text('ပြန်လည်ကြိုးစားမည်')),
                ],
              ),
            );
          }

          // ── expiringSoon ကို prov မှ တိုက်ရိုက်ယူ
          final List<PointsBatch> expiring = prov.expiringSoon;

          return RefreshIndicator(
            onRefresh: prov.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Summary card
                if (prov.summary != null) _SummaryCard(summary: prov.summary!),

                const SizedBox(height: 12),

                // 2. Expiry warning
                if (expiring.isNotEmpty) _ExpiryWarning(batches: expiring),

                // 3. Spend simulator
                const _SpendSimulator(),

                const SizedBox(height: 12),

                // 4. Header
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Points Batches (FIFO)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),

                // 5. Batch list
                if (prov.batches.isEmpty)
                  const _EmptyState()
                else
                  // b = PointsBatch  (PointsBatch.fromJson ဖြင့် ဆောက်ထားသည်)
                  ...prov.batches.map((b) => _BatchCard(batch: b)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('FIFO Points ဆိုတာ ဘာလဲ?'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'First In, First Out',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SizedBox(height: 8),
              Text('ဆီဖြည့်တိုင်း Points batch တစ်ခု ဖန်တီးပါသည်။'),
              SizedBox(height: 4),
              Text('Points သုံးသောအခါ အဟောင်းဆုံး batch မှ အရင် နုတ်ပါသည်။'),
              SizedBox(height: 4),
              Text('သက်တမ်းကုန်ပါက ထို batch ပျောက်သွားသည်။'),
              SizedBox(height: 14),
              Text('Tier အလိုက် သက်တမ်း:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              _TierRow('SILVER', '1 နှစ် (365 ရက်)'),
              _TierRow('GOLD', '2 နှစ် (730 ရက်)'),
              _TierRow('PLATINUM', '3 နှစ် (1095 ရက်)'),
              _TierRow('DIAMOND', '5 နှစ် (1825 ရက်)'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _SummaryCard
// ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final UserPointsSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('လက်ကျန် Points', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            NumberFormat('#,###').format(summary.totalPoints),
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatDot(
                label: 'Active',
                value: NumberFormat('#,###').format(summary.activePoints),
                color: Colors.greenAccent,
              ),
              const SizedBox(width: 20),
              if (summary.expiringSoonPoints > 0)
                _StatDot(
                  label: '30ရက်အတွင်း ကုန်မည်',
                  value: NumberFormat('#,###').format(summary.expiringSoonPoints),
                  color: Colors.orangeAccent,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${summary.totalBatches} batches  ·  1 pt = 10 ကျပ်',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatDot extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatDot({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            Text(
              '$value pts',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _ExpiryWarning
// ─────────────────────────────────────────────────────────────
class _ExpiryWarning extends StatelessWidget {
  final List<PointsBatch> batches;
  const _ExpiryWarning({required this.batches});

  @override
  Widget build(BuildContext context) {
    final int totalPts = batches.fold(0, (s, b) => s + b.remainingPoints);
    final DateTime earliest = batches.first.expiresAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        border: Border.all(color: Colors.orange, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Points သက်တမ်းကုန်ရန် နီးနေသည်!',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormat('#,###').format(totalPts)} pts သည် '
                  '${DateFormat('dd/MM/yyyy').format(earliest)} မတိုင်မီ ကုန်မည်',
                  style: const TextStyle(fontSize: 11, color: Colors.orange),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Reward လဲ သို့မဟုတ် ဆီဖြည့်ရာတွင် အသုံးပြုပါ',
                  style: TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _SpendSimulator  (StatefulWidget — local state သာ)
// ─────────────────────────────────────────────────────────────
class _SpendSimulator extends StatefulWidget {
  const _SpendSimulator();

  @override
  State<_SpendSimulator> createState() => _SpendSimulatorState();
}

class _SpendSimulatorState extends State<_SpendSimulator> {
  final _ctrl = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // p = FifoPointsProvider
    final FifoPointsProvider p = context.watch<FifoPointsProvider>();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — tap to expand
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  const Icon(Icons.calculate_outlined, color: Color(0xFF1B5E20), size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'FIFO Spend Simulator',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                ],
              ),
            ),

            if (_expanded) ...[
              const SizedBox(height: 6),
              const Text(
                'Points သုံးမည်ဆိုရင် ဘယ် batch မှ ကုန်မည်ကြိုကြည့်မည်',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'သုံးမည့် Points',
                        suffixText: 'pts',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: p.simulateLoading
                        ? null
                        : () {
                            final int n = int.tryParse(_ctrl.text) ?? 0;
                            context.read<FifoPointsProvider>().simulateSpend(n);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      minimumSize: const Size(72, 48),
                    ),
                    child: p.simulateLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('စစ်မည်', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),

              // Preview rows
              if (p.spendPreview.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(),
                const Text(
                  'ကုန်မည့် Batches (FIFO order):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                // p.spendPreview = List<BatchUsed>
                ...p.spendPreview.map((bu) => _PreviewRow(batchUsed: bu)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _PreviewRow  (BatchUsed တစ်ခုချင်းစီ)
// ─────────────────────────────────────────────────────────────
class _PreviewRow extends StatelessWidget {
  final BatchUsed batchUsed; // variable name: batchUsed  (bu မဟုတ်)
  const _PreviewRow({required this.batchUsed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batchUsed.source ?? 'Fuel Transaction',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Text(
                  'ရ: ${DateFormat("dd/MM/yy").format(batchUsed.earnedAt)}'
                  '  ·  ကုန်: ${DateFormat("dd/MM/yy").format(batchUsed.expiresAt)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '${NumberFormat('#,###').format(batchUsed.pointsTaken)} pts',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _BatchCard  (PointsBatch တစ်ခုချင်းစီ)
// ─────────────────────────────────────────────────────────────
class _BatchCard extends StatelessWidget {
  final PointsBatch batch; // variable name: batch  (b မဟုတ်)
  const _BatchCard({required this.batch});

  Color get _statusColor => switch (batch.status) {
    BatchStatus.active => const Color(0xFF1B5E20),
    BatchStatus.expiringSoon => Colors.orange,
    BatchStatus.expired => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Top row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 56,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // sourceLabel = stationName + fuelType
                        // PointsBatch.sourceLabel getter (fifo_service.dart ထဲတွင် ရှိသည်)
                        //batch.sourceLabel.isEmpty ? 'Fuel Transaction' : batch.sourceLabel,
                        "Batch SourceLabel Error", //batch.sourceLabel.isEmpty ? 'Fuel Transaction' : batch.sourceLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        // formattedEarnedAt = DateFormat('dd/MM/yyyy').format(earnedAt)
                        'ရ: ${batch.formattedEarnedAt}'
                        '${batch.vocNo != null ? "  ·  #${batch.vocNo}" : ""}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat('#,###').format(batch.remainingPoints),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _statusColor,
                        height: 1,
                      ),
                    ),
                    Text(
                      '/ ${NumberFormat('#,###').format(batch.earnedPoints)} pts',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Progress bar  — usageRatio = usedPoints / earnedPoints
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: batch.usageRatio,
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(_statusColor),
              ),
            ),

            const SizedBox(height: 8),

            // Expiry row  — expiryLabel, formattedExpiresAt, status.label
            Row(
              children: [
                Icon(Icons.schedule, size: 13, color: _statusColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${batch.formattedExpiresAt} (${batch.expiryLabel})',
                    style: TextStyle(fontSize: 11, color: _statusColor),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    batch.status.label,
                    style: TextStyle(fontSize: 9, color: _statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────
class _TierRow extends StatelessWidget {
  final String tier, duration;
  const _TierRow(this.tier, this.duration);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(tier, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Text(duration),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Text('Points Batch မရှိသေးပါ', style: TextStyle(color: Colors.grey, fontSize: 14)),
          SizedBox(height: 4),
          Text('ဆီဖြည့်ပြီး Points ရယူပါ', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    ),
  );
}
