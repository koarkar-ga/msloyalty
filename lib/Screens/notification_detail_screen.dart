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
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardColor =
        Theme.of(context).cardTheme.color ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "အသေးစိတ်",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              // TODO: Implement single delete logic if needed
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header visual adapts slightly to dark mode
            _buildHeaderVisual(notification.type, isDark),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTypeTag(notification.type, isDark),
                      Text(
                        notification.createdAt,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Divider(
                    height: 32,
                    thickness: 1,
                    color: isDark ? Colors.white10 : Colors.grey[200],
                  ),

                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSenderCard(notification, isDark, cardColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Notification Type အလိုက် Icon နှင့် အရောင်ပြောင်းရန်
  Widget _buildHeaderVisual(String type, bool isDark) {
    Color bgColor;
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'earn point':
        bgColor = isDark
            ? Colors.orange.withOpacity(0.05)
            : Colors.orange.shade50;
        icon = Icons.redeem;
        iconColor = Colors.orange.shade700;
        break;
      case 'reward point':
      case 'announce':
        bgColor = isDark ? Colors.red.withOpacity(0.05) : Colors.red.shade50;
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.red.shade700;
        break;
      default:
        bgColor = isDark ? Colors.blue.withOpacity(0.05) : Colors.blue.shade50;
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
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 32, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildTypeTag(String type, bool isDark) {
    bool isPromotion = type == 'promotion' || type == 'earn point';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPromotion
            ? (isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50)
            : (isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.shade50),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: isPromotion ? Colors.orange.shade400 : Colors.blue.shade400,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSenderCard(
    AppNotification notification,
    bool isDark,
    Color cardColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white,
            child: Icon(
              Icons.person_outline,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ပို့ဆောင်သူ",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              Text(
                notification.sender,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
