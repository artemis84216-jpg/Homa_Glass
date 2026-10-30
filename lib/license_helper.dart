import 'package:shared_preferences/shared_preferences.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'dart:convert';

class LicenseHelper {
  static const String _licenseKey = 'glass_license';

  // تولید کد لایسنس در پنل توسعه‌دهنده
  static String generateLicenseCode(String deviceId, int planId, int days) {
    String payload = '$deviceId:$planId:$days';
    String encoded = base64Encode(utf8.encode(payload));
    int checksum = encoded.hashCode;
    return 'HOMA-$encoded-$checksum';
  }

  // اعتبارسنجی کد لایسنس در اپلیکیشن
  static Future<bool> validateAndSaveLicense(String code, String currentDeviceId) async {
    try {
      List<String> parts = code.trim().split('-');
      if (parts.length != 3 || parts[0] != 'HOMA') return false;
      
      String encoded = parts[1];
      int checksum = int.parse(parts[2]);
      
      if (encoded.hashCode != checksum) return false;

      String decoded = utf8.decode(base64Decode(encoded));
      List<String> payload = decoded.split(':');
      
      String devId = payload[0];
      int planId = int.parse(payload[1]);
      int days = int.parse(payload[2]);

      if (devId != currentDeviceId) return false; // شناسه دستگاه مطابقت ندارد!

      Jalali expiry = Jalali.now().addDays(days);
      await saveLicense(code, planId, expiry);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getLicense() async {
    final prefs = await SharedPreferences.getInstance();
    final licenseJson = prefs.getString(_licenseKey);
    if (licenseJson == null) return null;

    try {
      final license = jsonDecode(licenseJson);
      final expiryDate = Jalali.fromDateTime(DateTime.parse(license['expiry_date']));
      final now = Jalali.now();
      final daysRemaining = expiryDate.toDateTime().difference(now.toDateTime()).inDays;

      return {
        ...license,
        'expiryJalali': expiryDate,
        'daysRemaining': daysRemaining,
        'isActive': daysRemaining >= 0,
      };
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveLicense(String code, int planId, Jalali expiry) async {
    final prefs = await SharedPreferences.getInstance();
    final license = {
      'license_code': code,
      'planId': planId,
      'expiry_date': expiry.toDateTime().toIso8601String(),
    };
    await prefs.setString(_licenseKey, jsonEncode(license));
  }

  static Future<void> clearLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_licenseKey);
  }
}