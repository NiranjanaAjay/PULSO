class BackendConfig {
  // 10.0.2.2 is for Android Emulator to access host localhost
  // But for physical device, we need the actual LAN IP
  static const String baseUrl = 'http://192.168.155.136:8000';

  static const String apiUrl = '$baseUrl/api/v1';
}
