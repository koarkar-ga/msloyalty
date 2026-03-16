import 'package:supabase_flutter/supabase_flutter.dart';

class AdService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>?> getActiveSplashAd() async {
    try {
      final response = await _supabase
          .from('advertisements')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error fetching splash ad: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getActiveIntroVideo() async {
    try {
      final response = await _supabase
          .from('intro_videos')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error fetching intro video: $e');
      return null;
    }
  }
}
