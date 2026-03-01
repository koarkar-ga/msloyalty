import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms & Conditions', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange[800], // MOONSUN Energy Theme Color
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Center(
              child: Column(
                children: [
                  Icon(Icons.card_giftcard, size: 60, color: Colors.orange[800]),
                  SizedBox(height: 10),
                  Text(
                    'MOONSUN x G&G Gift Voucher',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text('Gift Voucher Policy & Usage Guidelines'),
                ],
              ),
            ),
            Divider(height: 30, thickness: 1),

            // Terms Content
            _buildTermSection(
              "၁။ အစီအစဉ်၏ ရည်ရွယ်ချက်",
              "MOONSUN Energy စက်သုံးဆီဆိုင်များတွင် သတ်မှတ်ထားသော ပမာဏအတိုင်း ဆီဖြည့်တင်းသူများကို G&G Convenience Store တွင် အသုံးပြုနိုင်သည့် Gift Voucher များ လက်ဆောင်ပေးအပ်ခြင်း ဖြစ်ပါသည်။",
            ),
            _buildTermSection(
              "၂။ အသုံးပြုနိုင်သည့် နေရာ",
              "ဤ Voucher ကို သတ်မှတ်ထားသော G&G Convenience Store ဆိုင်ခွဲများတွင်သာ ပစ္စည်းဝယ်ယူရာတွင် အသုံးပြုနိုင်ပါသည်။ MOONSUN Energy ဆီဆိုင်များတွင် ပြန်လည်အသုံးပြု၍ မရပါ။",
            ),
            _buildTermSection(
              "၃။ ကန့်သတ်ချက်များ",
              "• Voucher ကို ငွေသားအဖြစ် ပြန်လည်လဲလှယ်၍ မရပါ။\n• တစ်ကြိမ်ဝယ်ယူလျှင် Voucher (၁) စောင်သာ အသုံးပြုနိုင်ပါသည်။\n• အရက်၊ ဘီယာ နှင့် ဆေးလိပ် အမျိုးမျိုး ဝယ်ယူရာတွင် အသုံးပြုခွင့်မရှိပါ။",
            ),
            _buildTermSection(
              "၄။ သက်တမ်းသတ်မှတ်ချက်",
              "Voucher တွင် ဖော်ပြထားသော သက်တမ်းကုန်ဆုံးရက်အတွင်းသာ အသုံးပြုရမည် ဖြစ်ပြီး သက်တမ်းကုန်ဆုံးပါက အသုံးပြုခွင့် မရှိပါ။",
            ),
            _buildTermSection(
              "၅။ ပျောက်ဆုံးခြင်းနှင့် ပျက်စီးခြင်း",
              "စုတ်ပြဲနေသော Voucher များ သို့မဟုတ် မိတ္တူကူးထားသော Voucher များကို လက်ခံမည်မဟုတ်ပါ။ ပျောက်ဆုံးသွားပါကလည်း အသစ်ပြန်လည် ထုတ်ပေးမည်မဟုတ်ပါ။",
            ),

            SizedBox(height: 20),

            // Accept Button (Optional)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('နားလည်ပါပြီ', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom Widget for each section
  Widget _buildTermSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[900]),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey[800]),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
