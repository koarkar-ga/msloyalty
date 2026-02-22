import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notification နှင့် Point update များကို ကိုင်တွယ်ပေးသည့် Service
class NotificationService {
  // SupabaseClient type သတ်မှတ်ချက်တွင် အမှားမတက်စေရန် final သာ အသုံးပြုခြင်း
  final _supabase = Supabase.instance.client;

  // Point အဟောင်းကို မှတ်ထားရန် variable
  int? _previousPoints;

  /// Point ပြောင်းလဲမှုကို နားထောင်ပြီး Alert ပြပေးမည့် function
  Future<void> listenToPointUpdates(BuildContext context, String myId) async {
    // Profiles table ကို stream လုပ်ပြီး point ပြောင်းလဲမှုကို စောင့်ကြည့်မည်
    _supabase.from('profiles').stream(primaryKey: ['id']).eq('id', myId).listen((
      List<Map<String, dynamic>> data,
    ) async {
      if (data.isEmpty) return;

      // လက်ရှိ point ကို column မှ ရယူခြင်း
      final int currentPoints = data.first['total_points'] ?? 0;

      // logic: ပထမဆုံးအကြိမ် stream ဝင်လာလျှင် _previousPoints က null ဖြစ်နေမည်။
      // ထိုအချိန်တွင် alert မပြသေးဘဲ လက်ရှိ point ကို သိမ်းရုံသာ သိမ်းထားမည်။
      if (_previousPoints == null) {
        _previousPoints = currentPoints;
        return;
      }

      // logic: အကယ်၍ အရင် point ထက် အခု point က ပိုများလာမှသာ Alert ပြမည်။
      // ဖွင့်ဖွင့်ချင်းတွင် Alert မတက်စေရန် ဤစစ်ဆေးမှုက ကာကွယ်ပေးပါသည်
      if (currentPoints > _previousPoints!) {
        _previousPoints = currentPoints; // point အသစ်ကို update လုပ်မည်

        // UI context ရှိမရှိ စစ်ဆေးပြီး Dialog ပြမည်
        if (!context.mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Row(
                children: [
                  Icon(Icons.stars, color: Colors.amber),
                  SizedBox(width: 10),
                  Text(
                    "Point Update",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              content: Text(
                "ဂုဏ်ယူပါသည်! Point $currentPoints မှတ် ရရှိပါပြီ။",
                style: const TextStyle(
                  color: Color.fromARGB(255, 29, 124, 32),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("OK", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      } else {
        // အကယ်၍ point မတိုးဘဲ တခြား data ပြောင်းလဲမှုကြောင့် stream တက်လာလျှင်လည်း
        // နောက်တစ်ကြိမ် နှိုင်းယှဉ်ရန် update လုပ်ထားမည်။
        _previousPoints = currentPoints;
      }
    });
  }
}
