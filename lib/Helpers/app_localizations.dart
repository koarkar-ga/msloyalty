class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'home': 'Home',
      'profile': 'Profile',
      'reward': 'Rewards',
      'point_history': 'Point History',
      'fuel_price': 'Fuel Price',
      'station': 'Stations',
      'welcome': 'Hi! Welcome Back',
      'available_points': 'AVAILABLE POINTS',
      'maintain_tier': 'Fuel up to maintain or upgrade your tier',
      'recent_transactions': 'Recent Transactions',
      'claim': 'Claim',
      'scan_qr': 'Scan QR',
      'earn_points': 'Earn Points',
      'logout': 'Logout',
      'history_title': 'History',
      'tab_fuel': 'Fuel History',
      'tab_redeem': 'Redemptions',
      'pints_tracker': 'Points Tracker',
      'pints_status': 'Points Status',
      'fuel_price_title': "Today's Fuel Prices",
      'region_select': 'Select Region:',
      'updated_at': 'Last updated',
      'per_liter': 'Per Liter',
      'recent_transactions_title': 'Recent Transactions',
      'view_all': 'View All',
      'notification': 'Notifications',
      'near_me': 'Near Me',
      'duration': 'Duration',
      'minutes': 'mins',
      'no_station_data': 'No station data available',
      'show_detail': 'Show Detail',
      'away': 'away',
      'estimation_warning':
          'Travel time is estimated based on route conditions.',
    },
    'mm': {
      'settings': 'ဆက်တင်များ',
      'dark_mode': 'အမှောင်ရောင် (Dark Mode)',
      'language': 'ဘာသာစကား (Language)',
      'home': 'ပင်မ',
      'profile': 'ပရိုဖိုင်',
      'reward': 'ဆုလက်ဆောင်',
      'point_history': 'ပွိုင့်မှတ်တမ်း',
      'fuel_price': 'ဆီစျေးနှုန်း',
      'station': 'ဆိုင်များ',
      'welcome': 'မင်္ဂလာပါ ပြန်လည်ကြိုဆိုပါတယ်',
      'available_points': 'ရရှိနိုင်သော ပွိုင့်များ',
      'maintain_tier':
          'သင့်အဆင့်ကို ထိန်းသိမ်းရန် သို့မဟုတ် မြှင့်တင်ရန် ဆီဖြည့်ပါ',
      'recent_transactions': 'နောက်ဆုံး အရောင်းအဝယ်များ',
      'claim': 'ရယူမည်',
      'scan_qr': 'QR စကင်ဖတ်ရန်',
      'earn_points': 'ပွိုင့်ရယူရန်',
      'logout': 'အကောင့်ထွက်ရန်',
      'history_title': 'မှတ်တမ်း',
      'tab_fuel': 'ဆီဖြည့်မှတ်တမ်း',
      'tab_redeem': 'လက်ဆောင်လဲလှယ်မှု',
      'pints_tracker': 'ပွိုင့် ခြေရာခံစနစ်',
      'pints_status': 'ပွိုင့် အခြေအနေ',
      'fuel_price_title': 'ယနေ့ ဆီဈေးနှုန်းများ',
      'region_select': 'တိုင်းဒေသကြီး ရွေးရန်:',
      'updated_at': 'နောက်ဆုံးပြင်ဆင်ချိန်',
      'per_liter': 'တစ်လီတာလျှင်',
      'recent_transactions_title': 'နောက်ဆုံး ဆီဖြည့်မှတ်တမ်းများ',
      'view_all': 'အားလုံးကြည့်ရန်',
      'notification': 'အသိပေးချက်',
      'near_me': 'အနီးနားရှိ ဆိုင်',
      'duration': 'ကြာချိန်',
      'minutes': 'မိနစ်',
      'no_station_data': 'တည်နေရာ အချက်အလက်ရှိသော ဆိုင်မရှိသေးပါ',
      'show_detail': 'အသေးစိတ်ကြည့်ရန်',
      'away': 'အကွာအဝေး',
      'estimation_warning':
          'လမ်းကြောင်းအခြေအနေ အပေါ် မှုတည်ပြီး ကြာချိန်အား ခန့် မှန်း တွက်ချက်ထား ခြင်း ဖြစ်ပါသည်',
    },
  };

  static String translate(String key, String locale) {
    return _localizedValues[locale]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

extension AppLocaleExtension on String {
  String tr(String locale) {
    return AppLocalizations.translate(this, locale);
  }
}
