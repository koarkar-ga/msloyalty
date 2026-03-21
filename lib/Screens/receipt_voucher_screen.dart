import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class ReceiptVoucherScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ReceiptVoucherScreen({super.key, required this.data});

  @override
  State<ReceiptVoucherScreen> createState() => _ReceiptVoucherScreenState();
}

class _ReceiptVoucherScreenState extends State<ReceiptVoucherScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  String? _stationName;

  @override
  void initState() {
    super.initState();
    _fetchStationName();
  }

  Future<void> _fetchStationName() async {
    final stationId = widget.data['station_id'];
    if (stationId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('stations')
          .select('name')
          .eq('station_id', stationId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _stationName = response['name'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching station name: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _shareReceipt() async {
    try {
      // Build the receipt widget for capture with Light Mode forced
      final capturedWidget = Container(
        padding: const EdgeInsets.all(24),
        color: const Color(0xFFF8F9FA),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildReceiptCard(false), // Force Light Mode
          ),
        ),
      );

      final image = await _screenshotController.captureFromWidget(
        capturedWidget,
        delay: const Duration(milliseconds: 100),
        context: context,
      );

      final directory = await getTemporaryDirectory();
      final sanitizedVocNo = (widget.data['voc_no'] ?? 'unknown')
          .toString()
          .replaceAll('/', '_');
      final imagePath = await File(
        '${directory.path}/ms_receipt_$sanitizedVocNo.png',
      ).create();
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles([
        XFile(imagePath.path),
      ], text: 'Moon Sun Energy Receipt - ${widget.data['voc_no']}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing receipt: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Receipt Voucher',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareReceipt,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildReceiptCard(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptCard(bool isDark) {
    final theme = Theme.of(context);
    final date = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(DateTime.parse(widget.data['created_at']));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Watermark Logo
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.05,
                child: Image.asset(
                  'assets/images/moonsun_logo.png',
                  width: 250,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top perforation aesthetic
              _buildPerforation(isDark),

              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Logo & Header
                    Image.network(
                      'https://www.moonsungroup.com/wp-content/uploads/2024/11/moonsun_logo.png',
                      height: 60,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.stars,
                        color: Color(0xFFFFD700),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'MOON SUN ENERGY',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1,
                        color: null, // Let theme handle it
                      ),
                    ),
                    Text(
                      'Premium Fuel & Services',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Success Indicator
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Fuel Received',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Details
                    _buildInfoRow(
                      'Station',
                      _stationName ??
                          widget.data['station_name'] ??
                          widget.data['station_id'] ??
                          '-',
                      isDark,
                    ),
                    _buildInfoRow(
                      'Voucher No',
                      widget.data['voc_no'] ?? '-',
                      isDark,
                    ),
                    _buildInfoRow('Date', date, isDark),
                    _buildInfoRow(
                      'Fuel Type',
                      widget.data['fuel_type'] ?? '-',
                      isDark,
                    ),
                    _buildInfoRow(
                      'Liters',
                      '${(() {
                        final amount = double.tryParse(widget.data['amount_mmk']?.toString() ?? '0') ?? 0.0;
                        final unitPrice = double.tryParse(widget.data['unit_price']?.toString() ?? '1') ?? 1.0;
                        final liter = double.tryParse(widget.data['sale_liter']?.toString() ?? '');
                        return (liter ?? (amount / (unitPrice > 0 ? unitPrice : 1))).toStringAsFixed(2);
                      })()} L',
                      isDark,
                    ),
                    _buildInfoRow(
                      'Price / Liter',
                      '${(() {
                        final amount = double.tryParse(widget.data['amount_mmk']?.toString() ?? '0') ?? 0.0;
                        final liter = double.tryParse(widget.data['sale_liter']?.toString() ?? '');
                        final unitPrice = double.tryParse(widget.data['unit_price']?.toString() ?? '0') ?? 0.0;
                        if (liter != null && liter > 0) {
                          return (amount / liter).toStringAsFixed(0);
                        }
                        return unitPrice.toStringAsFixed(0);
                      })()} MMK',
                      isDark,
                    ),
                    _buildInfoRow(
                      'Payment',
                      widget.data['sale_type'] ?? '-',
                      isDark,
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(thickness: 1, height: 1),
                    ),

                    // Pricing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '${NumberFormat('#,###').format(widget.data['amount_mmk'] ?? 0)} MMK',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Color(0xFF1B4F72),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Points Earned',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        Text(
                          '+ ${widget.data['points_earned']} Pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Visit again to earn more rewards!',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom perforation
              _buildPerforation(isDark, isBottom: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerforation(bool isDark, {bool isBottom = false}) {
    return Container(
      height: 20,
      width: double.infinity,
      color: Colors.transparent,
      child: Row(
        children: List.generate(
          20,
          (index) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: index.isEven ? 10 : 0,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF121212)
                    : const Color(0xFFF8F9FA),
                borderRadius: isBottom
                    ? const BorderRadius.vertical(top: Radius.circular(10))
                    : const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
