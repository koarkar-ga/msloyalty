import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import '../../services/fifo_service.dart';
import '../../providers/fifo_points_provider.dart';

// ─────────────────────────────────────────────────────────────
// Entry point
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

  static const _accentColor = Color(0xFF1B4F72); // Navy brand color

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = Theme.of(context).appBarTheme.foregroundColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Points မှတ်တမ်း',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fgColor),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: fgColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: fgColor),
            onPressed: () => _showInfo(context, isDark),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: fgColor),
            onPressed: () => context.read<FifoPointsProvider>().refresh(),
          ),
        ],
      ),
      body: Consumer<FifoPointsProvider>(
        builder: (context, prov, _) {
          if (prov.loading) {
            return Center(child: MoonSunLoading());
          }

          if (prov.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
                  const SizedBox(height: 14),
                  Text(
                    prov.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: prov.refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('ပြန်လည်ကြိုးစားမည်'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }

          final List<PointsBatch> expiring = prov.expiringSoon;

          return RefreshIndicator(
            onRefresh: prov.refresh,
            color: _accentColor,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (prov.summary != null) _SummaryCard(summary: prov.summary!),
                const SizedBox(height: 14),
                if (expiring.isNotEmpty) _ExpiryWarning(batches: expiring),
                _SpendSimulator(isDark: isDark),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(width: 4, height: 18, decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: BorderRadius.circular(2),
                      )),
                      const SizedBox(width: 8),
                      Text(
                        'Points Batches (FIFO)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (prov.batches.isEmpty)
                  const _EmptyState()
                else
                  ...prov.batches.map((b) => _BatchCard(batch: b)),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showInfo(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('FIFO Points ဆိုတာ ဘာလဲ?', style: TextStyle(fontSize: 15)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('First In, First Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4F72),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
          colors: [Color(0xFF1B4F72), Color(0xFF2980B9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4F72).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text('လက်ကျန် Points',
                  style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            NumberFormat('#,###').format(summary.totalPoints),
            style: const TextStyle(
              fontSize: 48,
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
              const SizedBox(width: 24),
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
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            Text('$value pts',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int totalPts = batches.fold(0, (s, b) => s + b.remainingPoints);
    final DateTime earliest = batches.first.expiresAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.orange.withValues(alpha: 0.12) : const Color(0xFFFFF3E0),
        border: Border.all(color: Colors.orange.shade400, width: 1.5),
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
                const Text('Points သက်တမ်းကုန်ရန် နီးနေသည်!',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormat('#,###').format(totalPts)} pts သည် '
                  '${DateFormat('dd/MM/yyyy').format(earliest)} မတိုင်မီ ကုန်မည်',
                  style: TextStyle(fontSize: 11, color: Colors.orange.shade600),
                ),
                const SizedBox(height: 3),
                Text('Reward လဲ သို့မဟုတ် ဆီဖြည့်ရာတွင် အသုံးပြုပါ',
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _SpendSimulator
// ─────────────────────────────────────────────────────────────
class _SpendSimulator extends StatefulWidget {
  final bool isDark;
  const _SpendSimulator({required this.isDark});

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
    final FifoPointsProvider p = context.watch<FifoPointsProvider>();
    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4F72).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.calculate_outlined, color: Color(0xFF1B4F72), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('FIFO Spend Simulator',
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: subColor,
                  ),
                ],
              ),
            ),

            if (_expanded) ...[
              const SizedBox(height: 10),
              Text('Points သုံးမည်ဆိုရင် ဘယ် batch မှ ကုန်မည်ကြိုကြည့်မည်',
                  style: TextStyle(fontSize: 11, color: subColor)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'သုံးမည့် Points',
                        suffixText: 'pts',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                      backgroundColor: const Color(0xFF1B4F72),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(72, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: p.simulateLoading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('စစ်မည်'),
                  ),
                ],
              ),

              if (p.spendPreview.isNotEmpty) ...[
                const SizedBox(height: 14),
                Divider(color: isDark ? Colors.white12 : Colors.black12),
                Text('ကုန်မည့် Batches (FIFO order):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 8),
                ...p.spendPreview.map((bu) => _PreviewRow(batchUsed: bu, isDark: isDark)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _PreviewRow
// ─────────────────────────────────────────────────────────────
class _PreviewRow extends StatelessWidget {
  final BatchUsed batchUsed;
  final bool isDark;
  const _PreviewRow({required this.batchUsed, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B4F72).withValues(alpha: 0.15)
            : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.subdirectory_arrow_right, size: 16, color: Color(0xFF1B4F72)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batchUsed.source ?? 'Fuel Transaction',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
                ),
                Text(
                  'ရ: ${DateFormat("dd/MM/yy").format(batchUsed.earnedAt)}'
                  '  ·  ကုန်: ${DateFormat("dd/MM/yy").format(batchUsed.expiresAt)}',
                  style: TextStyle(fontSize: 10, color: subColor),
                ),
              ],
            ),
          ),
          Text(
            '${NumberFormat('#,###').format(batchUsed.pointsTaken)} pts',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4F72),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _BatchCard
// ─────────────────────────────────────────────────────────────
class _BatchCard extends StatelessWidget {
  final PointsBatch batch;
  const _BatchCard({required this.batch});

  Color get _statusColor => switch (batch.status) {
        BatchStatus.active => const Color(0xFF1B4F72),
        BatchStatus.expiringSoon => Colors.orange,
        BatchStatus.expired => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4, height: 56,
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
                        'Fuel Transaction',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'ရ: ${batch.formattedEarnedAt}'
                        '${batch.vocNo != null ? "  ·  #${batch.vocNo}" : ""}',
                        style: TextStyle(fontSize: 10, color: subColor),
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
                      style: TextStyle(fontSize: 10, color: subColor),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: batch.usageRatio,
                minHeight: 7,
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(_statusColor),
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: _statusColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${batch.formattedExpiresAt} (${batch.expiryLabel})',
                    style: TextStyle(fontSize: 11, color: _statusColor),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    batch.status.label,
                    style: TextStyle(
                      fontSize: 9,
                      color: _statusColor,
                      fontWeight: FontWeight.bold,
                    ),
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
  Widget build(BuildContext context) {
    final subColor = Theme.of(context).textTheme.bodyMedium?.color;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_outlined, size: 60, color: subColor?.withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            Text('Points Batch မရှိသေးပါ',
                style: TextStyle(color: subColor, fontSize: 14)),
            const SizedBox(height: 4),
            Text('ဆီဖြည့်ပြီး Points ရယူပါ',
                style: TextStyle(color: subColor?.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
