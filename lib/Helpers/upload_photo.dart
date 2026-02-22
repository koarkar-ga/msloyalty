import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<void> uploadImage(File imageFile) async {
  final fileName = DateTime.now().millisecondsSinceEpoch.toString();
  final path = 'avatars/$fileName';

  await supabase.storage.from('moonsun_assets').upload(path, imageFile);

  // Image URL ပြန်ယူခြင်း
  final String publicUrl = supabase.storage.from('moonsun_assets').getPublicUrl(path);
  print("Avatars Link: $publicUrl");
}
