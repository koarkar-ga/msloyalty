import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DOBPickerScreen extends StatefulWidget {
  const DOBPickerScreen({super.key});

  @override
  State<DOBPickerScreen> createState() => _DOBPickerScreenState();
}

class _DOBPickerScreenState extends State<DOBPickerScreen> {
  DateTime? _selectedDate;
  int? _age;

  // ပြက္ခဒိန်ရွေးချယ်မှုကို ခေါ်ယူခြင်း
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), // စတင်ပြသမည့် ခုနှစ်
      firstDate: DateTime(1900), // ရွေးချယ်နိုင်သော အစောဆုံး ခုနှစ်
      lastDate: DateTime.now(), // ယနေ့ထက် ကျော်လွန်၍ ရွေးမရအောင် ကန့်သတ်ခြင်း
      helpText: 'မွေးသက္ကရာဇ် ရွေးချယ်ပါ',
      cancelText: 'ပယ်ဖျက်',
      confirmText: 'အတည်ပြု',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _calculateAge(picked);
      });
    }
  }

  // အသက်ကို တွက်ချက်ခြင်း
  void _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    _age = age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('မွေးသက္ကရာဇ် ရွေးချယ်မှု'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ကိုယ်ရေးအချက်အလက်',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'သင်၏ မွေးနေ့ ရက်၊ လ၊ နှစ် ကို ရွေးချယ်ပေးပါရန်။',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // ရက်စွဲရွေးချယ်မည့် နေရာ
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedDate != null ? Colors.indigo : Colors.grey.shade300,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: _selectedDate != null ? Colors.indigo : Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _selectedDate == null
                          ? 'ရက်စွဲရွေးချယ်ရန် နှိပ်ပါ'
                          : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate == null ? Colors.grey : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ရွေးချယ်ပြီးပါက အသက်ကို ပြသပေးခြင်း
            if (_selectedDate != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cake, color: Colors.indigo, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'လက်ရှိအသက် - $_age နှစ်',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // အတည်ပြုခလုတ်
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _selectedDate == null
                    ? null
                    : () {
                        // ရှေ့ဆက်လုပ်ဆောင်မည့် လုပ်ငန်းစဉ်
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: const Text(
                  'ရှေ့သို့ဆက်သွားမည်',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
