import 'dart:async';
import 'package:flutter/material.dart';
import 'package:msloyalty/Services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationProvider with ChangeNotifier {
  int _unreadCount = 0;
  bool _isListening = false;
  final Set<String> _seenBroadcastIds = {};
  final Set<int> _seenNotificationIds = {};
  final Set<int> _locallyDeletedIds = {};

  StreamSubscription? _subscription;
  bool _initialLoadDone = false;
  StreamSubscription? _broadcastSubscription;

  bool isLocallyDeleted(int id) => _locallyDeletedIds.contains(id);

  int get unreadCount => _unreadCount;
  final supabase = Supabase.instance.client;

  String? _userTier;
  bool _localNotificationsEnabled = true;

  void updateNotificationPreference(bool enabled) {
    _localNotificationsEnabled = enabled;
  }

  Future<void> startListening() async {
    if (_isListening) return;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _isListening = true;

    // Pre-fetch user tier once
    try {
      final profileRes = await supabase
          .from('profiles')
          .select('member_types(name)')
          .eq('id', user.id)
          .maybeSingle();
      _userTier =
          profileRes?['member_types']?['name']?.toString().toUpperCase() ??
          'BRONZE';
    } catch (e) {
      debugPrint("Error fetching user tier: $e");
      _userTier = 'BRONZE';
    }

    // --- Standard Notifications ---
    _subscription = supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((List<Map<String, dynamic>> data) {
          try {
            final userNotifications = data.where((n) {
              final isMatch = n['user_id'] == user.id;
              // Robust check for is_deleted to handle cases where column might be missing from some rows or schema
              bool isDeleted = false;
              try {
                isDeleted = n['is_deleted'] == true || _locallyDeletedIds.contains(n['id']);
              } catch (_) {}
              return isMatch && !isDeleted;
            }).toList();
            _unreadCount = userNotifications
                .where((n) => n['is_read'] == false)
                .length;

            for (var notification in userNotifications) {
              final id = notification['id'] as int;
              if (!_seenNotificationIds.contains(id)) {
                if (_initialLoadDone && notification['is_read'] == false) {
                  final title = notification['title'] ?? '';
                  if (title != 'Points Collected' &&
                      title != 'Redemption Successful' &&
                      notification['type'] != 'system') {
                    if (_localNotificationsEnabled) {
                      NotificationService().showNotification(
                        id: id,
                        title: title,
                        body: notification['message'] ?? '',
                      );
                    }
                  }
                }
                _seenNotificationIds.add(id);
              }
            }
            _initialLoadDone = true;
            notifyListeners();
          } catch (e) {
            debugPrint("Error listening to notifications: $e");
          }
        });

    // --- Broadcast Notifications ---
    _broadcastSubscription = supabase
        .from('mobile_notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isEmpty) return;

          for (var item in data) {
            final id = item['id'].toString();
            final target =
                item['target_type']?.toString().toUpperCase() ?? 'ALL';

            if (!_seenBroadcastIds.contains(id)) {
              // Check if it matches user tier
              if (target == 'ALL' || target == _userTier) {
                // PERSIST: Always save to history if it's for this user
                _persistBroadcast(item, user.id);

                // NOTIFY: Only show banner if it's a live update (after initial load)
                if (_initialLoadDone && _localNotificationsEnabled) {
                  NotificationService().showNotification(
                    id: id.hashCode,
                    title: item['title'] ?? 'MS Loyalty',
                    body: item['body'] ?? '',
                  );
                }
              }
              _seenBroadcastIds.add(id);
            }
          }
        });
  }

  Future<void> _persistBroadcast(
    Map<String, dynamic> item,
    String userId,
  ) async {
    try {
      // Check if it already exists in notifications table to prevent duplicates
      final existing = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('title', item['title'] ?? '')
          .eq('message', item['body'] ?? '')
          .maybeSingle();

      if (existing == null) {
        final insertData = {
          'user_id': userId,
          'title': item['title'] ?? 'System Update',
          'message': item['body'] ?? '',
          'is_read': false,
          'type': 'system', // Use system type for broadcasts
        };

        try {
          // Attempt to insert with is_deleted if possible
          await supabase.from('notifications').insert({
            ...insertData,
            'is_deleted': false,
          });
        } catch (e) {
          // Fallback if column missing
          await supabase.from('notifications').insert(insertData);
        }
      }
    } catch (e) {
      debugPrint("Error persisting broadcast notification: $e");
    }
  }

  Future<void> markAllAsRead() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Try with is_deleted filter first
      try {
        await supabase
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', user.id)
            .eq('is_read', false)
            .or('is_deleted.eq.false,is_deleted.is.null');
      } catch (e) {
        // Fallback if column missing
        await supabase
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', user.id)
            .eq('is_read', false);
      }

      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  Future<void> deleteNotifications(List<int> ids, List<String> types) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      for (int i = 0; i < ids.length; i++) {
        final id = ids[i];
        final type = types[i];

        if (type == 'system') {
          // Add to local set immediately for instant UI feedback
          _locallyDeletedIds.add(id);
          
          // Attempt soft delete for system - mark as is_deleted = true
          try {
            await supabase
                .from('notifications')
                .update({'is_deleted': true})
                .eq('id', id);
          } catch (e) {
            debugPrint("Soft-delete fail (likely column missing): $e");
          }
        } else {
          // Hard delete - also add to local set just in case stream reflects late
          _locallyDeletedIds.add(id);
          await supabase.from('notifications').delete().eq('id', id);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Delete Error: $e");
      rethrow;
    }
  }

  Future<void> deleteAllNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      // Hard delete all non-system
      await supabase
          .from('notifications')
          .delete()
          .eq('user_id', user.id)
          .neq('type', 'system');

      // Soft delete all system notifications
      try {
        await supabase
            .from('notifications')
            .update({'is_deleted': true})
            .eq('user_id', user.id)
            .eq('type', 'system');
      } catch (e) {
        debugPrint("Soft-delete All Column missing: $e");
      }

      // We don't have an easy way to get all IDs here to add to _locallyDeletedIds 
      // without fetching first, but the stream/refresh will handle the UI 
      // for the hard-deleted ones. For system notifications, if column is missing,
      // they remain visible until SQL is run.
      
      notifyListeners();
    } catch (e) {
      debugPrint("Delete All Error: $e");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _broadcastSubscription?.cancel();
    super.dispose();
  }
}
