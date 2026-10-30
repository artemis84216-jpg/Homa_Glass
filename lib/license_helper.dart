import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'database_helper.dart';

class LicenseHelper {
  static const String _licenseKey = 'glass_license';

  // تولید کد لایسنس در پنل توسعه‌دهنده
  static String generateLicenseCode(String deviceId, int planId, int days) {
    String payload = '$deviceId:$planId:$days';
    String encoded = base64Url.encode(utf8.encode(payload)).replaceAll('=', '');
    int checksum = encoded.hashCode.abs();
    return 'HOMA-$encoded-$checksum';
  }

  // اعتبارسنجی کد لایسنس در اپلیکیشن
  static Future<Map<String, dynamic>> validateAndSaveLicense(String code, String currentDeviceId) async {
    try {
      if (!code.trim().startsWith('HOMA-')) {
        return {'success': false, 'message': 'کد باید با HOMA- شروع شود'};
      }
      
      String withoutPrefix = code.trim().substring(5);
      int lastDashIndex = withoutPrefix.lastIndexOf('-');
      if (lastDashIndex == -1) {
        return {'success': false, 'message': 'فرمت کد نامعتبر است'};
      }
      
      String encoded = withoutPrefix.substring(0, lastDashIndex);
      String checksumStr = withoutPrefix.substring(lastDashIndex + 1);
      
      int checksum;
      try {
        checksum = int.parse(checksumStr);
      } catch (e) {
        return {'success': false, 'message': 'checksum نامعتبر است'};
      }
      
      if (encoded.hashCode.abs() != checksum) {
        return {'success': false, 'message': 'کد لایسنس دستکاری شده است'};
      }

      String decoded;
      try {
        String padded = encoded;
        while (padded.length % 4 != 0) {
          padded += '=';
        }
        decoded = utf8.decode(base64Url.decode(padded));
      } catch (e) {
        return {'success': false, 'message': 'decode ناموفق بود'};
      }

      List<String> payload = decoded.split(':');
      if (payload.length != 3) {
        return {'success': false, 'message': 'payload نامعتبر است'};
      }
      
      String devId = payload[0];
      int planId;
      int days;
      try {
        planId = int.parse(payload[1]);
        days = int.parse(payload[2]);
      } catch (e) {
        return {'success': false, 'message': 'اعداد payload نامعتبر هستند'};
      }

      if (devId != currentDeviceId) {
        return {
          'success': false, 
          'message': 'این کد برای دستگاه دیگری است!\n\nشناسه دستگاه شما: $currentDeviceId\nشناسه کد: $devId'
        };
      }

      // دریافت نام پلن از دیتابیس
      final plans = await DatabaseHelper.instance.getAllPlans();
      final plan = plans.firstWhere((p) => p['id'] == planId, orElse: () => {'name': 'پلن $planId'});
      final planName = plan['name'] ?? 'پلن $planId';

      // ذخیره لایسنس در SharedPreferences
      final expiryDate = DateTime.now().add(Duration(days: days));
      await saveLicense(code, planId, expiryDate);
      
      // ذخیره سابقه لایسنس در جدول licenses برای ردیابی
      try {
        await DatabaseHelper.instance.insertLicense({
          'shop_name': 'Homa_Glass',
          'device_id': currentDeviceId,
          'license_code': code,
          'plan_id': planId,
          'plan_name': planName,
          'expiry_date': expiryDate.toIso8601String(),
          'issued_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('Error saving license record: $e');
      }
      
      return {'success': true, 'planId': planId, 'planName': planName, 'days': days};
    } catch (e) {
      return {'success': false, 'message': 'خطای نامشخص: $e'};
    }
  }

  static Future<Map<String, dynamic>?> getLicense() async {
    final prefs = await SharedPreferences.getInstance();
    final licenseJson = prefs.getString(_licenseKey);
    if (licenseJson == null) return null;

    try {
      final license = jsonDecode(licenseJson);
      final expiryDate = DateTime.parse(license['expiry_date']);
      final now = DateTime.now();
      final daysRemaining = expiryDate.difference(now).inDays;

      return {
        ...license,
        'daysRemaining': daysRemaining,
        'isActive': daysRemaining >= 0,
      };
    } catch (e) {
      print('License parse error: $e');
      return null;
    }
  }

  static Future<void> saveLicense(String code, int planId, DateTime expiry) async {
    final prefs = await SharedPreferences.getInstance();
    final license = {
      'license_code': code,
      'planId': planId,
      'expiry_date': expiry.toIso8601String(),
    };
    await prefs.setString(_licenseKey, jsonEncode(license));
  }

  static Future<void> clearLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_licenseKey);
  }
}