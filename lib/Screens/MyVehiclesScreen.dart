import 'package:flutter/material.dart';
import 'package:msloyalty/Models/VehicleModel.dart';
import 'package:msloyalty/Services/vehicle_service.dart';
import 'package:msloyalty/Services/notification_service.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:intl/intl.dart';
import 'package:msloyalty/Screens/VehicleDetailScreen.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final VehicleService _vehicleService = VehicleService();
  bool _isLoading = true;
  List<VehicleModel> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await _vehicleService.getVehicles();
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: MoonSunLoading())
          : _vehicles.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadVehicles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _vehicles[index];
                      return _buildVehicleCard(vehicle, cardColor, isDark);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VehicleDetailScreen()),
          );
          if (result == true) _loadVehicles();
        },
        backgroundColor: const Color(0xFF1B4F72),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No vehicles added yet',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VehicleDetailScreen()),
              );
              if (result == true) _loadVehicles();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4F72),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add Your First Vehicle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(VehicleModel vehicle, Color cardColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4F72).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car, color: Color(0xFF1B4F72)),
          ),
          title: Text(
            vehicle.licensePlate,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text('${vehicle.brand ?? ""} ${vehicle.model ?? ""}'.trim()),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _infoRowWithAction(
                    icon: Icons.opacity,
                    label: 'Last Oil Change',
                    date: vehicle.lastOilChangeDate,
                    onUpdate: () => _updateServiceDate(vehicle, isOilChange: true),
                  ),
                  const SizedBox(height: 8),
                  _infoRowWithAction(
                    icon: Icons.verified_user_outlined,
                    label: 'Insurance Expiry',
                    date: vehicle.insuranceExpiryDate,
                    onUpdate: () => _updateServiceDate(vehicle, isOilChange: false),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VehicleDetailScreen(vehicle: vehicle),
                            ),
                          );
                          if (result == true) _loadVehicles();
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _confirmDelete(vehicle),
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRowWithAction({
    required IconData icon,
    required String label,
    required DateTime? date,
    required VoidCallback onUpdate,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        GestureDetector(
          onTap: onUpdate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4F72).withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Text(
                  date != null ? DateFormat('dd MMM yyyy').format(date) : 'Not set',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF1B4F72)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.refresh, size: 14, color: Color(0xFF1B4F72)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateServiceDate(VehicleModel vehicle, {required bool isOilChange}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isOilChange ? 'Update Oil Change Date' : 'Update Insurance Expiry',
    );

    if (picked != null) {
      setState(() => _isLoading = true);
      try {
        final Map<String, dynamic> updateData = isOilChange
            ? {'last_oil_change_date': picked.toIso8601String().split('T')[0]}
            : {'insurance_expiry_date': picked.toIso8601String().split('T')[0]};
        
        updateData['updated_at'] = DateTime.now().toIso8601String();

        await _vehicleService.updateVehicle(vehicle.id, updateData);

        // Re-schedule notifications
        NotificationService.scheduleVehicleReminders(
          licensePlate: vehicle.licensePlate,
          lastOilChangeDate: isOilChange ? picked : vehicle.lastOilChangeDate,
          insuranceExpiryDate: isOilChange ? vehicle.insuranceExpiryDate : picked,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${isOilChange ? "Oil change" : "Insurance"} updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadVehicles();
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _confirmDelete(VehicleModel vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to remove vehicle ${vehicle.licensePlate}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _vehicleService.deleteVehicle(vehicle.id);
              _loadVehicles();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
