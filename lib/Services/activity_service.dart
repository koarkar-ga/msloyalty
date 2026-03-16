import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> logActivity({
    required String actionType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get user name from profile if possible, otherwise use user id
      String? userName;
      try {
        final profile = await _supabase
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();
        userName = profile?['full_name'];
      } catch (_) {}

      await _supabase.from('activities').insert({
        'user_id': user.id,
        'user_name': userName ?? 'Member',
        'action_type': actionType,
        'description': description,
        'station_id': 'MOBILE_APP',
        'metadata': metadata ?? {},
      });
    } catch (e) {
      print('Failed to log activity: $e');
    }
  }
}
