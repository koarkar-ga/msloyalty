import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// class FuelTransaction {
//   final String id;
//   final String stationName;
//   final String fuelType;
//   final DateTime date;
//   final double liters;
//   final double pricePerLiter;
//   final int odometer;
//   final String pumpNumber;
//   final String vehicle;
//   final String notes;

//   FuelTransaction({
//     required this.id,
//     required this.stationName,
//     required this.fuelType,
//     required this.date,
//     required this.liters,
//     required this.pricePerLiter,
//     required this.odometer,
//     required this.pumpNumber,
//     required this.vehicle,
//     this.notes = '',
//   });

//   double get total => liters * pricePerLiter;
//   String get formattedDate =>
//       '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
//       '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
//   String formatCurrency(double value) => '\$${value.toStringAsFixed(2)}';
// }

class FuelTransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const FuelTransactionDetailScreen({Key? key, required this.data}) : super(key: key);
  //String formatCurrency(double value) => '\$${value.toStringAsFixed(2)}';

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  void _copyTransactionId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: data['id'])).then((_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction ID copied to clipboard')));
    });
  }

  void _showReceiptPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Receipt'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              // Placeholder for receipt image or detail
              Icon(Icons.receipt_long, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('Receipt preview is not available.'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Fuel Transaction', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
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
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(Icons.local_gas_station, size: 28, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['voc_no'],
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${data['fuel_type']}",
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${data['amount_mmk']} Ks",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${data['points_earned']} Pts",
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow('Transaction ID', data['voc_no']),
                    const Divider(),
                    _buildDetailRow('Payment Method', data['sale_type']),
                    _buildDetailRow('Fuel Type', data['fuel_type']),
                    _buildDetailRow('Amount', data['amount_mmk'].toString()),
                    _buildDetailRow('Points', '${data['points_earned']} Pts'),
                    // _buildDetailRow('Price/L', formatCurrency(data['price_per_liter'])),
                    _buildDetailRow(
                      'Date',
                      DateFormat('dd MMM yyyy hh:mm:ss').format(DateTime.parse(data['created_at'])),
                    ),
                    // if (data['notes'].isNotEmpty) ...[
                    //   const Divider(),
                    //   // _buildDetailRow('Notes', data['notes']),
                    // ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.receipt),
                    label: const Text('View Receipt'),
                    onPressed: () => _showReceiptPreview(context),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  onPressed: () {
                    // Placeholder: implement sharing integration in your app.
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Share action not implemented')));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
