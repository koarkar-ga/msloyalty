import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:msloyalty/Screens/receipt_voucher_screen.dart';
import 'package:provider/provider.dart';
import 'package:msloyalty/Providers/point_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FuelTransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const FuelTransactionDetailScreen({super.key, required this.data});

  @override
  State<FuelTransactionDetailScreen> createState() =>
      _FuelTransactionDetailScreenState();
}

class _FuelTransactionDetailScreenState
    extends State<FuelTransactionDetailScreen> {
  final TextEditingController _remarkController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;
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
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) return;

    setState(() => _isSubmitting = true);
    try {
      final provider = Provider.of<PointProvider>(context, listen: false);
      final txnId = widget.data['id'];
      if (txnId != null) {
        await provider.submitFeedback(txnId, _rating, _remarkController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('မှတ်ချက် ပေးပို့ပြီးပါပြီ။ ကျေးဇူးတင်ပါသည်။'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyTransactionId(BuildContext context) {
    // Ensuring ID is a string to avoid type error
    final String transactionId =
        widget.data['voc_no']?.toString() ?? widget.data['id'].toString();
    Clipboard.setData(ClipboardData(text: transactionId)).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction ID ($transactionId) copied'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.iconTheme,
        title: Text(
          'Fuel Transaction',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy transaction ID',
            onPressed: () => _copyTransactionId(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              context,
              'Date & Time',
              widget.data['created_at'] != null
                  ? DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(DateTime.parse(widget.data['created_at']))
                  : '-',
            ),
            _buildDetailRow(
              context,
              'Station',
              _stationName ??
                  widget.data['station_name'] ??
                  widget.data['station_id'] ??
                  '-',
            ),
            _buildDetailRow(
              context,
              'Fuel Type',
              widget.data['fuel_type'] ?? '-',
            ),
            _buildDetailRow(
              context,
              'Liters',
              '${(() {
                final amount = double.tryParse(widget.data['amount_mmk']?.toString() ?? '0') ?? 0.0;
                final unitPrice = double.tryParse(widget.data['unit_price']?.toString() ?? '1') ?? 1.0;
                final liter = double.tryParse(widget.data['sale_liter']?.toString() ?? '');
                return (liter ?? (amount / (unitPrice > 0 ? unitPrice : 1))).toStringAsFixed(2);
              })()} L',
            ),
            _buildDetailRow(
              context,
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
            ),
            _buildDetailRow(
              context,
              'Total Amount',
              '${widget.data['amount_mmk'] ?? '0'} MMK',
            ),
            _buildDetailRow(
              context,
              'Points Earned',
              '${widget.data['points_earned'] ?? '0'} Points',
            ),
            if (widget.data['vehicle_no'] != null)
              _buildDetailRow(context, 'Vehicle', widget.data['vehicle_no']),
            if (widget.data['extra_info'] != null)
              _buildDetailRow(context, 'Notes', widget.data['extra_info']),

            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ReceiptVoucherScreen(data: widget.data),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text(
                  'View Receipt Voucher',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 20),

            // Customer Feedback Section
            Text(
              'ဝန်ဆောင်မှုအပေါ် သင့်အမြင်ကို ပြောပြပေးပါ',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Rating Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 40,
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),

            // Remark Box
            TextField(
              controller: _remarkController,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'မှတ်ချက် (စိတ်ကြိုက်) ...',
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _rating > 0
                      ? colorScheme.primary
                      : Colors.grey,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _rating > 0 && !_isSubmitting
                    ? _submitFeedback
                    : null,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'ပေးပို့မည်',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
