// lib/providers/fifo_points_provider.dart
//
// Riverpod မသုံး — Provider (ChangeNotifier) သာ သုံးသည်
// pubspec.yaml:  provider: ^6.x.x

import 'package:flutter/foundation.dart';
import '../services/fifo_service.dart';
// PointsBatch, BatchStatus, BatchUsed, SpendResult,
// UserPointsSummary အားလုံး fifo_service.dart ထဲတွင် ရှိသည်

class FifoPointsProvider extends ChangeNotifier {
  // ── State ─────────────────────────────────────
  bool _loading = false;
  String? _error;
  UserPointsSummary? _summary;
  List<PointsBatch> _batches = [];
  List<BatchUsed> _spendPreview = [];
  bool _simulateLoading = false;

  // ── Getters ───────────────────────────────────
  bool get loading => _loading;
  String? get error => _error;
  UserPointsSummary? get summary => _summary;
  List<PointsBatch> get batches => _batches;
  List<BatchUsed> get spendPreview => _spendPreview;
  bool get simulateLoading => _simulateLoading;

  /// 30 ရက်အတွင်း ကုန်မည့် batches
  List<PointsBatch> get expiringSoon =>
      _batches.where((b) => b.status == BatchStatus.expiringSoon).toList();

  // ── Load all ──────────────────────────────────
  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([FifoService.getMySummary(), FifoService.getMyBatches()]);
      _summary = results[0] as UserPointsSummary;
      _batches = results[1] as List<PointsBatch>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadAll();

  // ── Simulate spend (preview only) ────────────
  Future<void> simulateSpend(int points) async {
    if (points <= 0) {
      _spendPreview = [];
      notifyListeners();
      return;
    }
    _simulateLoading = true;
    notifyListeners();
    try {
      _spendPreview = await FifoService.simulateSpend(points);
    } catch (_) {
      _spendPreview = [];
    } finally {
      _simulateLoading = false;
      notifyListeners();
    }
  }

  void clearPreview() {
    _spendPreview = [];
    notifyListeners();
  }

  // ── Redeem reward ─────────────────────────────
  Future<SpendResult> redeemReward({
    required int rewardId,
    required int pointsToSpend,
    String? stationId,
  }) async {
    final result = await FifoService.redeemReward(
      rewardId: rewardId,
      pointsToSpend: pointsToSpend,
      stationId: stationId,
    );
    if (result.success) await loadAll();
    return result;
  }
}
