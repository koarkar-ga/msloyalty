import 'package:flutter/material.dart';

// Notification Model အချက်အလက်များ
class AppNotification {
  final String title;
  final String message;
  final String type; // 'promotion', 'alert', 'system'
  final String createdAt;
  final String sender;

  AppNotification({
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.sender,
  });
}

class NotificationDetailScreen extends StatefulWidget {
  final AppNotification notification;
  const NotificationDetailScreen({super.key, required this.notification});

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  @override
  Widget build(BuildContext context) {
    // စမ်းသပ်ရန် Data (Mock Data)
    final notification = widget.notification;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "အသေးစိတ်",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // အပေါ်ပိုင်း Visual Header
            _buildHeaderVisual(notification.type),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Tag and Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTypeTag(notification.type),
                      Text(
                        notification.createdAt,
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Notification Title
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Divider(height: 32, thickness: 1),

                  // Message Body
                  Text(
                    notification.message,
                    style: TextStyle(fontSize: 16, height: 1.6, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 32),

                  // Sender Card
                  _buildSenderCard(notification),
                ],
              ),
            ),
          ],
        ),
      ),
      // Action Button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text(
              "လုပ်ဆောင်ချက် ကြည့်ရန်",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // Notification Type အလိုက် Icon နှင့် အရောင်ပြောင်းရန်
  Widget _buildHeaderVisual(String type) {
    Color bgColor;
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'earn point':
        bgColor = Colors.white.withOpacity(0.8);
        icon = Icons.redeem;
        iconColor = Colors.orange.shade700;
        break;
      case 'reward point':
        bgColor = Colors.red.shade50;
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.red.shade700;
        break;
      case 'announce':
        bgColor = Colors.red.shade50;
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.blue.shade50;
        icon = Icons.info_outline_rounded;
        iconColor = Colors.blue.shade700;
    }

    return Container(
      width: double.infinity,
      height: 160,
      color: bgColor,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Icon(icon, size: 32, color: iconColor),
        ),
      ),
    );
  }

  // Type Tag လေးများ
  Widget _buildTypeTag(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: type == 'promotion' ? Colors.orange.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: type == 'promotion' ? Colors.orange.shade700 : Colors.blue.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  // Sender Profile Card
  Widget _buildSenderCard(AppNotification notification) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person_outline, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ပို့ဆောင်သူ", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              Text(
                notification.sender,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
