import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:msloyalty/Models/VehicleModel.dart';

class VehicleService {
  final _supabase = Supabase.instance.client;

  Future<List<VehicleModel>> getVehicles() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('user_vehicles')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((json) => VehicleModel.fromJson(json)).toList();
  }

  Future<void> addVehicle(VehicleModel vehicle) async {
    await _supabase.from('user_vehicles').insert(vehicle.toJson());
  }

  Future<void> updateVehicle(String id, Map<String, dynamic> data) async {
    await _supabase.from('user_vehicles').update(data).eq('id', id);
  }

  Future<void> deleteVehicle(String id) async {
    await _supabase.from('user_vehicles').delete().eq('id', id);
  }
}
