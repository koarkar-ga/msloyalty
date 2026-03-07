// lib/services/fifo_service.dart
//
// Models + Service တစ်ဖိုင်တည်းတွင် ရှိသည်
// fifo_models.dart ခွဲဖိုင် မလိုဘူး
//
// import 'package:your_app/services/fifo_service.dart'; တစ်ကြောင်းတည်းနဲ့ ရသည်

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════
// ENUM: BatchStatus
// ═══════════════════════════════════════════════════════════
enum BatchStatus {
  active,
  expiringSoon,
  expired;

  static BatchStatus fromString(String s) {
    switch (s) {
      case 'EXPIRING_SOON':
        return BatchStatus.expiringSoon;
      case 'EXPIRED':
        return BatchStatus.expired;
      default:
        return BatchStatus.active;
    }
  }

  String get label {
    switch (this) {
      case BatchStatus.active:
        return 'Active';
      case BatchStatus.expiringSoon:
        return '30 ရက်အတွင်း ကုန်မည်';
      case BatchStatus.expired:
        return 'သက်တမ်းကုန်';
    }
  }
}

// ═══════════════════════════════════════════════════════════
// MODEL: PointsBatch
// v_user_points_fifo view row တစ်ခု = PointsBatch တစ်ခု
// ═══════════════════════════════════════════════════════════
class PointsBatch {
  final int id;
  final String userId;
  final int? fuelTxnId;
  final String? stationName;
  final String? fuelType;
  final String? vocNo;
  final int earnedPoints;
  final int remainingPoints;
  final int usedPoints;
  final DateTime earnedAt;
  final DateTime expiresAt;
  final int daysUntilExpiry;
  final BatchStatus status;

  const PointsBatch({
    required this.id,
    required this.userId,
    this.fuelTxnId,
    this.stationName,
    this.fuelType,
    this.vocNo,
    required this.earnedPoints,
    required this.remainingPoints,
    required this.usedPoints,
    required this.earnedAt,
    required this.expiresAt,
    required this.daysUntilExpiry,
    required this.status,
  });

  factory PointsBatch.fromJson(Map<String, dynamic> j) {
    return PointsBatch(
      id: (j['ledger_id'] as num).toInt(),
      userId: j['user_id'] as String,
      fuelTxnId: (j['fuel_txn_id'] as num?)?.toInt(),
      stationName: j['station_name'] as String?,
      fuelType: j['fuel_type'] as String?,
      vocNo: j['voc_no'] as String?,
      earnedPoints: (j['earned_points'] as num).toInt(),
      remainingPoints: (j['remaining_points'] as num).toInt(),
      usedPoints: (j['used_points'] as num? ?? 0).toInt(),
      earnedAt: DateTime.parse(j['earned_at'] as String),
      expiresAt: DateTime.parse(j['expires_at'] as String),
      daysUntilExpiry: (j['days_until_expiry'] as num? ?? 0).toInt(),
      status: BatchStatus.fromString(j['status'] as String? ?? 'ACTIVE'),
    );
  }

  // ── Computed getters ──────────────────────────────────────

  /// usedPoints / earnedPoints  (0.0 – 1.0)
  double get usageRatio => earnedPoints == 0 ? 0.0 : (usedPoints / earnedPoints).clamp(0.0, 1.0);

  /// "stationName · fuelType"  — batch card title
  String get sourceLabel => [stationName, fuelType].whereType<String>().join(' · ');

  /// မည်နှစ်ရက် ကျန်သည်
  String get expiryLabel {
    if (status == BatchStatus.expired) return 'သက်တမ်းကုန်ပြီ';
    if (daysUntilExpiry <= 0) return 'ယနေ့ ကုန်မည်';
    return '$daysUntilExpiry ရက်အတွင်း ကုန်မည်';
  }

  String get formattedEarnedAt => DateFormat('dd/MM/yyyy').format(earnedAt);
  String get formattedExpiresAt => DateFormat('dd/MM/yyyy').format(expiresAt);
}

// ═══════════════════════════════════════════════════════════
// MODEL: BatchUsed
// FIFO loop တွင် တစ်ခုချင်းစီ နုတ်ယူသော batch ၏ audit record
// ═══════════════════════════════════════════════════════════
class BatchUsed {
  final int ledgerId;
  final int? fuelTxnId;
  final DateTime earnedAt;
  final DateTime expiresAt;
  final int pointsTaken;
  final String? source;

  const BatchUsed({
    required this.ledgerId,
    this.fuelTxnId,
    required this.earnedAt,
    required this.expiresAt,
    required this.pointsTaken,
    this.source,
  });

  factory BatchUsed.fromJson(Map<String, dynamic> j) {
    return BatchUsed(
      ledgerId: (j['ledger_id'] as num).toInt(),
      fuelTxnId: (j['fuel_txn_id'] as num?)?.toInt(),
      earnedAt: DateTime.parse(j['earned_at'] as String),
      expiresAt: DateTime.parse(j['expires_at'] as String),
      pointsTaken: (j['points_taken'] as num).toInt(),
      source: j['source'] as String?,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MODEL: SpendResult
// spend_points_fifo() RPC ၏ return value
// ═══════════════════════════════════════════════════════════
class SpendResult {
  final bool success;
  final String message;
  final int pointsSpent;
  final int newBalance;
  final List<BatchUsed> batchesUsed;

  const SpendResult({
    required this.success,
    required this.message,
    this.pointsSpent = 0,
    this.newBalance = 0,
    this.batchesUsed = const [],
  });

  factory SpendResult.fromJson(Map<String, dynamic> j) {
    return SpendResult(
      success: j['success'] == true,
      message: j['message'] as String? ?? '',
      pointsSpent: (j['points_spent'] as num? ?? 0).toInt(),
      newBalance: (j['new_balance'] as num? ?? 0).toInt(),
      batchesUsed: (j['batches_used'] as List? ?? [])
          .map((b) => BatchUsed.fromJson(Map<String, dynamic>.from(b as Map)))
          .toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MODEL: UserPointsSummary
// ═══════════════════════════════════════════════════════════
class UserPointsSummary {
  final int totalPoints;
  final int activePoints;
  final int expiringSoonPoints;
  final DateTime? earliestExpiry;
  final int totalBatches;

  const UserPointsSummary({
    required this.totalPoints,
    required this.activePoints,
    required this.expiringSoonPoints,
    this.earliestExpiry,
    required this.totalBatches,
  });

  bool get hasExpiringSoon => expiringSoonPoints > 0;

  String get expiringSoonLabel {
    if (earliestExpiry == null) return '';
    return '${NumberFormat('#,###').format(expiringSoonPoints)} pts သည် '
        '${DateFormat('dd/MM/yyyy').format(earliestExpiry!)} တွင် ကုန်မည်';
  }
}

// ═══════════════════════════════════════════════════════════
// SERVICE: FifoService
// ═══════════════════════════════════════════════════════════
class FifoService {
  static SupabaseClient get _db => Supabase.instance.client;
  static String? get _uid => _db.auth.currentUser?.id;

  // ── READ: Batch list (FIFO order) ──────────────────────
  static Future<List<PointsBatch>> getMyBatches() async {
    final uid = _uid;
    if (uid == null) return [];

    final rows = await _db
        .from('v_user_points_fifo')
        .select()
        .eq('user_id', uid)
        .order('earned_at', ascending: true);

    return rows.map((r) => PointsBatch.fromJson(r)).toList();
  }

  // ── READ: Summary ───────────────────────────────────────
  static Future<UserPointsSummary> getMySummary() async {
    final uid = _uid;
    if (uid == null) {
      return const UserPointsSummary(
        totalPoints: 0,
        activePoints: 0,
        expiringSoonPoints: 0,
        totalBatches: 0,
      );
    }

    final profile = await _db.from('profiles').select('total_points').eq('id', uid).single();

    final batches = await getMyBatches();
    final active = batches.where((b) => b.status == BatchStatus.active);
    final expiring = batches.where((b) => b.status == BatchStatus.expiringSoon);

    return UserPointsSummary(
      totalPoints: (profile['total_points'] as num? ?? 0).toInt(),
      activePoints: active.fold(0, (s, b) => s + b.remainingPoints),
      expiringSoonPoints: expiring.fold(0, (s, b) => s + b.remainingPoints),
      earliestExpiry: batches.isNotEmpty ? batches.first.expiresAt : null,
      totalBatches: batches.length,
    );
  }

  // ── READ: Expiring soon only ────────────────────────────
  static Future<List<PointsBatch>> getExpiringSoon() async {
    final uid = _uid;
    if (uid == null) return [];

    final rows = await _db
        .from('v_user_points_fifo')
        .select()
        .eq('user_id', uid)
        .eq('status', 'EXPIRING_SOON')
        .order('expires_at', ascending: true);

    return rows.map((r) => PointsBatch.fromJson(r)).toList();
  }

  // ── SIMULATE: Preview FIFO spend (no DB write) ─────────
  static Future<List<BatchUsed>> simulateSpend(int pointsNeeded) async {
    final batches = await getMyBatches();
    final available = batches
        .where((b) => b.status != BatchStatus.expired && b.remainingPoints > 0)
        .toList();

    final List<BatchUsed> preview = [];
    int remaining = pointsNeeded;

    for (final b in available) {
      if (remaining <= 0) break;
      final int take = remaining.clamp(0, b.remainingPoints);
      preview.add(
        BatchUsed(
          ledgerId: b.id,
          fuelTxnId: b.fuelTxnId,
          earnedAt: b.earnedAt,
          expiresAt: b.expiresAt,
          pointsTaken: take,
          source: b.sourceLabel, // "stationName · fuelType"
        ),
      );
      remaining -= take;
    }

    return preview;
  }

  // ── WRITE: Spend via RPC ────────────────────────────────
  static Future<SpendResult> spendPoints({required int pointsNeeded, int? redemptionId}) async {
    final uid = _uid;
    if (uid == null) {
      return const SpendResult(success: false, message: 'Not logged in');
    }

    final result = await _db.rpc(
      'spend_points_fifo',
      params: {'p_user_id': uid, 'p_points_needed': pointsNeeded, 'p_redemption_id': redemptionId},
    );

    return SpendResult.fromJson(Map<String, dynamic>.from(result as Map));
  }

  // ── WRITE: Redeem reward ────────────────────────────────
  static Future<SpendResult> redeemReward({
    required int rewardId,
    required int pointsToSpend,
    String? stationId,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return const SpendResult(success: false, message: 'Not logged in');
    }

    final preview = await simulateSpend(pointsToSpend);
    if (preview.isEmpty) {
      return const SpendResult(success: false, message: 'Points မလုံလောက်ပါ');
    }

    try {
      await _db.from('redemption_history').insert({
        'user_id': uid,
        'reward_id': rewardId,
        'points_spent': pointsToSpend,
        'station_id': stationId,
        'status': true,
        'used': false,
      });

      final profile = await _db.from('profiles').select('total_points').eq('id', uid).single();

      return SpendResult(
        success: true,
        message: 'Reward လဲပြီးပါပြီ',
        pointsSpent: pointsToSpend,
        newBalance: (profile['total_points'] as num? ?? 0).toInt(),
        batchesUsed: preview,
      );
    } catch (e) {
      return SpendResult(success: false, message: 'Error: $e');
    }
  }
}
