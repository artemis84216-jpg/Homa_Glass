import 'package:shared_preferences/shared_preferences.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'dart:convert';
import 'database_helper.dart';

class LicenseHelper {
  static const String _licenseKey = 'glass_license';

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