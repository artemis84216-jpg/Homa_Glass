import 'database_helper.dart';
import 'license_helper.dart';

class LicenseManager {
  static Future<Map<String, dynamic>> getUsageStats() async {
    final license = await LicenseHelper.getLicense();
    if (license == null || !license['isActive']) {
      return {'hasLicense': false};
    }

    final plans = await DatabaseHelper.instance.getAllPlans();
    final plan = plans.firstWhere((p) => p['id'] == license['planId'], orElse: () => {});
    if (plan.isEmpty) return {'hasLicense': false};

    final customers = await DatabaseHelper.instance.getAllCustomers();
    final employees = await DatabaseHelper.instance.getAllEmployees();

    return {
      'hasLicense': true,
      'planName': plan['name'],
      'customers': {
        'current': customers.length,
        'max': plan['max_customers'] ?? 999999,
        'isUnlimited': (plan['max_customers'] ?? 999999) >= 999999,
      },
      'employees': {
        'current': employees.length,
        'max': plan['max_employees'] ?? 999999,
        'isUnlimited': (plan['max_employees'] ?? 999999) >= 999999,
      },
    };
  }

  static Future<Map<String, dynamic>> canAddCustomer() async {
    final stats = await getUsageStats();
    if (!stats['hasLicense']) {
      return {'allowed': false, 'message': 'لطفاً ابتدا لایسنس را فعال کنید'};
    }
    final current = stats['customers']['current'];
    final max = stats['customers']['max'];
    final isUnlimited = stats['customers']['isUnlimited'];
    if (isUnlimited || current < max) {
      return {'allowed': true};
    }
    return {'allowed': false, 'message': 'محدودیت تعداد مشتریان پلن شما پر شده است'};
  }

  static Future<Map<String, dynamic>> canAddEmployee() async {
    final stats = await getUsageStats();
    if (!stats['hasLicense']) {
      return {'allowed': false, 'message': 'لطفاً ابتدا لایسنس را فعال کنید'};
    }
    final current = stats['employees']['current'];
    final max = stats['employees']['max'];
    final isUnlimited = stats['employees']['isUnlimited'];
    if (isUnlimited || current < max) {
      return {'allowed': true};
    }
    return {'allowed': false, 'message': 'محدودیت تعداد کارمندان پلن شما پر شده است'};
  }
}