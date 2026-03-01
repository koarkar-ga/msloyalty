import 'package:flutter/material.dart';
import 'package:msloyalty/Constants/constant.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:msloyalty/Screens/notification_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // အသိပေးချက်များ ဖတ်ယူခြင်း
  Future<void> _fetchNotifications() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('notifications')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      notificationStream = supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('is_read', false)
          .map((List<Map<String, dynamic>> data) => data.length);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Notification Fetch Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // အသိပေးချက်ကို ဖတ်ပြီးကြောင်း မှတ်သားခြင်း
  Future<void> _markAsRead(int id, bool currentStatus) async {
    if (currentStatus) return;

    try {
      await supabase.from('notifications').update({'is_read': true}).eq('id', id);

      _fetchNotifications();
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }

  // အားလုံးကို ဖတ်ပြီးကြောင်း မှတ်သားခြင်း
  Future<void> _markAllAsRead() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      _fetchNotifications();
    } catch (e) {
      debugPrint("Update All Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text(
          "အသိပေးချက်များ",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black87,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_notifications.any((n) => n['is_read'] == false))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text("အားလုံးဖတ်ပြီး", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: MoonSunLoading())
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: _notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  return _buildNotificationItem(item);
                },
              ),
            ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item) {
    final bool isRead = item['is_read'] ?? false;
    final String type = item['type'] ?? 'general';
    final DateTime createdAt = DateTime.parse(item['created_at']).toLocal();

    return InkWell(
      onTap: () {
        _markAsRead(item['id'], isRead);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NotificationDetailScreen(
              notification: AppNotification(
                title: item['title'] ?? "",
                message: item['message'] ?? "",
                type: type,
                createdAt: DateFormat('dd MMM yyyy, hh:mm a').format(createdAt),
                sender: "System",
              ),
            ),
          ),
        );
      },
      child: Container(
        color: isRead ? Colors.transparent : Colors.black.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _getIconColor(type).withOpacity(0.1),
              child: Icon(_getIcon(type), color: _getIconColor(type), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] ?? "",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                            color: isRead ? Colors.grey[800] : Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['message'] ?? "",
                    style: TextStyle(
                      fontSize: 13,
                      color: isRead ? Colors.grey[600] : Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "အသိပေးချက်များ မရှိသေးပါ",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'promotion':
        return Icons.local_offer_outlined;
      case 'points':
        return Icons.stars_outlined;
      case 'system':
        return Icons.settings_suggest_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'promotion':
        return Colors.orange;
      case 'points':
        return Colors.purple;
      case 'system':
        return Colors.blue;
      default:
        return const Color(0xFF1B4F72);
    }
  }
}
