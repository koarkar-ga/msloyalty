import 'package:flutter/material.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:msloyalty/Screens/notification_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:msloyalty/Providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // အသိပေးချက်များ ဖတ်ယူခြင်း
  Future<void> _fetchNotifications() async {
    try {
      final user = supabase.auth.currentUser;
      debugPrint("Fetching notifications for user: ${user?.id}");
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final data = await supabase
          .from('notifications')
          .select('*')
          .eq('user_id', user.id)
          .or('is_deleted.eq.false,is_deleted.is.null')
          .order('created_at', ascending: false);

      debugPrint("Notifications Fetch Success: ${data.length} items found");

      if (mounted) {
        final provider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        final filteredData = data
            .where((n) => !provider.isLocallyDeleted(n['id'] as int))
            .toList();

        setState(() {
          _notifications = List<Map<String, dynamic>>.from(filteredData);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Notification Fetch Error: $e");
      // Fallback query if is_deleted column doesn't exist yet
      if (e.toString().contains('is_deleted')) {
        debugPrint("Retrying without is_deleted filter...");
        try {
          final user = supabase.auth.currentUser;
          final data = await supabase
              .from('notifications')
              .select('*')
              .eq('user_id', user?.id ?? '')
              .order('created_at', ascending: false);
          if (mounted) {
            final provider = Provider.of<NotificationProvider>(
              context,
              listen: false,
            );
            final filteredData = data
                .where((n) => !provider.isLocallyDeleted(n['id'] as int))
                .toList();

            setState(() {
              _notifications = List<Map<String, dynamic>>.from(filteredData);
              _isLoading = false;
            });
          }
          return;
        } catch (e2) {
          debugPrint("Fallback Fetch Error: $e2");
        }
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds.clear();
      _selectedIds.addAll(_notifications.map((n) => n['id'] as int));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  // အသိပေးချက်ကို ဖတ်ပြီးကြောင်း မှတ်သားခြင်း
  Future<void> _markAsRead(int id, bool currentStatus) async {
    if (currentStatus) return;
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
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

  void _showManagementBottomSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text("Select"),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isSelectionMode = true;
                  _selectedIds.add(item['id']);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text("Delete", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteSelected([item['id']], [item['type'] ?? 'general']);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSelected(List<int> ids, List<String> types) async {
    try {
      final provider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      await provider.deleteNotifications(ids, types);
      _clearSelection();
      _fetchNotifications();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("ဖျက်ပြီးပါပြီ")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = Theme.of(context).appBarTheme.foregroundColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? "${_selectedIds.length} Selected"
              : "အသိပေးချက်များ",
          style: TextStyle(
            color: fgColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0.5,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        iconTheme: IconThemeData(color: fgColor),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                final selectedNotis = _notifications.where(
                  (n) => _selectedIds.contains(n['id']),
                );
                _deleteSelected(
                  _selectedIds.toList(),
                  selectedNotis
                      .map((n) => n['type']?.toString() ?? 'general')
                      .toList(),
                );
              },
            ),
          ] else ...[
            if (_notifications.any((n) => n['is_read'] == false))
              TextButton(
                onPressed: _markAllAsRead,
                child: Text("အားလုံးဖတ်ပြီး", style: TextStyle(color: fgColor)),
              ),
            PopupMenuButton(
              icon: Icon(Icons.more_vert, color: fgColor),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Text("Delete All"),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete_all') {
                  Provider.of<NotificationProvider>(
                    context,
                    listen: false,
                  ).deleteAllNotifications();
                  _fetchNotifications();
                }
              },
            ),
          ],
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
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 70),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = Theme.of(context).textTheme.bodyMedium?.color;

    return InkWell(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(item['id']);
        } else {
          _markAsRead(item['id'], isRead);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NotificationDetailScreen(
                notification: AppNotification(
                  title: item['title'] ?? "",
                  message: item['message'] ?? "",
                  type: type,
                  createdAt: DateFormat(
                    'dd MMM yyyy, hh:mm a',
                  ).format(createdAt),
                  sender: "System",
                ),
              ),
            ),
          );
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _showManagementBottomSheet(item);
        }
      },
      child: Container(
        color: _selectedIds.contains(item['id'])
            ? (isDark
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.05))
            : (isRead
                  ? Colors.transparent
                  : (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.blue.withOpacity(0.04))),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 10),
                child: Icon(
                  _selectedIds.contains(item['id'])
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: _selectedIds.contains(item['id'])
                      ? Colors.blue
                      : Colors.grey,
                  size: 20,
                ),
              ),
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
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead && !_isSelectionMode)
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
                      color: subColor,
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
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
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
