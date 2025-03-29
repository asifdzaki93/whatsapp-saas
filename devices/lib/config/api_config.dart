class ApiConfig {
  // Ganti IP address sesuai dengan IP komputer Anda yang menjalankan backend
  static const String baseUrl =
      'http://192.168.100.164:9003'; // IP komputer Anda dengan port 9003

  // Environment Token untuk Signup
  static const String envToken = '123456'; // Sesuaikan dengan token di backend

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/signup';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String users = '/users';
  static const String tickets = '/tickets';
  static const String contacts = '/contacts';
  static const String whatsapp = '/whatsapp';
  static const String settings = '/settings';

  // WebSocket
  static const String wsUrl =
      'ws://192.168.100.164:9003'; // IP komputer Anda dengan port 9003
}
