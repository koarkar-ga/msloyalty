class Config {
  static String logoImage =
      "https://www.moonsungroup.com/wp-content/uploads/2024/11/moonsun_logo.png";
  static String bannerImage =
      'https://www.moonsungroup.com/wp-content/uploads/2024/12/88241740_1806356016162404_6870344400963108864_n.jpg';
  static String anonKey = 'sb_publishable_-AUTIjFF1f7h2X71pwgqGw_C7fXkQO3';
  static String supabaseUrl = 'https://zellqsyvjfgnlwredhtt.supabase.co';
  static String smspoh_api_key = 'FrDKw_6S2cu43gk9Vn548y8a1KKXlg-P';
  static String smsph_api_secret = 'hqjc5T7bu5GKEyqGr-kUVS0CQL7nznjd';
  static String smspoh_api_url = 'https://api.smsprovider.com/send';
  static String smspoh_access_token = 'accessToken=U01TUG9oVjNBUElLZXk6U01TUG9oVjNBUElTZWNyZXQ=';
  static String smspoh_bearer =
      'RnJES3dfNlMyY3U0M2drOVZuNTQ4eThhMUtLWGxnLVA6aHFqYzVUN2J1NUdLRXlxR3Ita1VWUzBDUUw3bnpuamQ';
  static String smspoh_v3_api_url = 'https://v3.smspoh.com/api/otp/';
  //base64encode(SMSPohV3APIKey:SMSPohV3APISecret)

  //Request OTP URL  SMS
  //This API allows you to request OTP code via SMS.
  // https://v3.smspoh.com/api/otp/request?from=SMSPoh&to=099*******&brand=SMSPoh&accessToken=U01TUG9oVjNBUElLZXk6U01TUG9oVjNBUElTZWNyZXQ=

  //This API allows you to request OTP code via Email.
  // https://v3.smspoh.com/api/otp/request?from=SMSPoh&to=user@domain.com&brand=SMSPoh&accessToken=U01TUG9oVjNBUElLZXk6U01TUG9oVjNBUElTZWNyZXQ=
}
