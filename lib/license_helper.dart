import 'package:shared_preferences/shared_preferences.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'dart:convert';

class LicenseHelper {
  static const String _licenseKey = 'glass_license';

  // تولید کد لایسنس در پنل توسعه‌دهنده
  static String generateLicenseCode(String deviceId, int planId, int days) {
    String payload = '$deviceId:$planId:$days';
    // استفاده از base64Url برای جلوگیری از کاراکترهای مشکل‌دار
    String encoded = base64Url.encode(utf8.encode(payload)).replaceAll('=', '');
    // استفاده از abs() برای جلوگیری از منفی شدن checksum
    int checksum = encoded.hashCode.abs();
    return 'HOMA-$encoded-$checksum';
  }

  // اعتبارسنجی کد لایسنس در اپلیکیشن
  static Future<Map<String, dynamic>> validateAndSaveLicense(String code, String currentDeviceId) async {
    try {
      // چک فرمت کلی
      if (!code.trim().startsWith('HOMA-')) {
        return {'success': false, 'message': 'کد باید با HOMA- شروع شود'};
      }
      
      // حذف پیشوند HOMA- و split کردن
      String withoutPrefix = code.trim().substring(5);
      
      // پیدا کردن آخرین - برای جدا کردن checksum
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
      
      // بررسی checksum
      if (encoded.hashCode.abs() != checksum) {
        return {'success': false, 'message': 'کد لایسنس دستکاری شده است'};
      }

      // decode کردن payload
      String decoded;
      try {
        // اضافه کردن padding برای base64Url
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

      // بررسی شناسه دستگاه
      if (devId != currentDeviceId) {
        return {
          'success': false, 
          'message': 'این کد برای دستگاه دیگری است!\n\nشناسه دستگاه شما: $currentDeviceId\nشناسه کد: $devId'
        };
      }

      // ذخیره لایسنس
      Jalali expiry = Jalali.now().addDays(days);
      await saveLicense(code, planId, expiry);
      return {'success': true, 'planId': planId, 'days': days};
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