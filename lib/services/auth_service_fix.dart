import 'dart:convert';
import '../services/auth_service.dart';

// AuthServiceのJSON処琁E��修正
extension AuthServiceJsonFix on AuthService {
  Map<String, dynamic> parseJsonSafe(String json) {
    return jsonDecode(json) as Map<String, dynamic>;
  }

  String jsonEncodeSafe(Map<String, dynamic> map) {
    return jsonEncode(map);
  }
}
