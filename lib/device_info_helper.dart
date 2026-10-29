import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoHelper {
  static final DeviceInfoHelper instance = DeviceInfoHelper._init();
  DeviceInfoHelper._init();

  String? _deviceId;

  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    _deviceId = '${androidInfo.brand}_${androidInfo.model}_${androidInfo.id}';
    return _deviceId!;
  }
}