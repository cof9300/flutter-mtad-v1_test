import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_template/config/service_locator.dart';

class Config {
  static String get baseUrl => dotenv.get('BASE_URL', fallback: '');

  static Future<String?> getKioskId() async {
    return await ServiceLocator().kioskIdStorage.getKioskId();
  }

  static const Duration timeout = Duration(seconds: 30);

  static const bool enableLogRequestInfo = true;
}
