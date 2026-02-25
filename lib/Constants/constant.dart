import 'package:flutter/material.dart';

Stream<int> notificationStream = Stream<int>.periodic(
  Duration(microseconds: 1),
  (count) {
    return 0; // Default value
  },
);

Widget buildTextField(
  TextEditingController controller,
  String label,
  IconData icon, {
  bool isPhone = false,
  bool isOtp = false,
  bool enabled = true,
}) {
  return TextFormField(
    controller: controller,
    enabled: enabled,
    keyboardType: isPhone || isOtp ? TextInputType.number : TextInputType.text,
    maxLength: isOtp ? 6 : (isPhone ? 11 : null),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1B4F72)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      filled: !enabled,
      fillColor: Colors.grey[100],
    ),
    validator: (value) {
      if (value == null || value.isEmpty) return "$label ဖြည့်သွင်းပါ";
      if (isPhone && value.length < 9) return "ဖုန်းနံပါတ် မှားယွင်းနေပါသည်";
      return null;
    },
  );
}

Widget buildEmailField(TextEditingController controller) {
  return TextFormField(
    controller: controller,
    keyboardType: TextInputType.emailAddress,
    decoration: InputDecoration(
      labelText: "Email Address",
      prefixIcon: const Icon(Icons.email, color: Color(0xFF1B4F72)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      hintText: "example@gmail.com",
    ),
    validator: (value) {
      if (value == null || value.isEmpty) return "Email ဖြည့်သွင်းပါ";

      // Email format validation logic
      final emailRegex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      );
      if (!emailRegex.hasMatch(value)) {
        return "Email ပုံစံ မှားယွင်းနေပါသည်";
      }
      return null;
    },
  );
}

Widget buildDateField(BuildContext context, TextEditingController controller) {
  return TextFormField(
    controller: controller,
    readOnly: true, // Keyboard မတက်စေရန်
    decoration: InputDecoration(
      labelText: "မွေးသက္ကရာဇ် (DOB)",
      prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF1B4F72)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      hintText: "ရက်စွဲ ရွေးချယ်ပါ",
    ),
    onTap: () async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime(2000), // စဖွင့်လျှင်ပြမည့်နှစ်
        firstDate: DateTime(1950), // ရွေးလို့ရမည့် အစောဆုံးနှစ်
        lastDate: DateTime.now(), // ရွေးလို့ရမည့် နောက်ဆုံးနှစ် (ယနေ့)
      );

      if (pickedDate != null) {
        // ရက်စွဲကို စာသားအဖြစ်ပြောင်းလဲခြင်း (yyyy-MM-dd)
        String formattedDate =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
        controller.text = formattedDate;
      }
    },
    validator: (value) {
      if (value == null || value.isEmpty) return "မွေးသက္ကရာဇ် ရွေးချယ်ပေးပါ";
      return null;
    },
  );
}

Widget buildSubmitButton(
  bool _isLoading,
  bool _isOtpSent,
  VoidCallback _requestOTP,
  VoidCallback _verifyAndNext,
) {
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      onPressed: _isLoading
          ? null
          : (_isOtpSent ? _verifyAndNext : _requestOTP),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFC62828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              _isOtpSent ? "ကုဒ်စစ်ဆေးမည်" : "OTP တောင်းဆိုမည်",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    ),
  );
}
