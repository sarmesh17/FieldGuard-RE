class ApiConstant {
  // Base URL for API endpoints
  static const String baseUrl = "https://fieldguard-be.onrender.com";

  // The endpoint for user login
  static const String loginEndpoint = "$baseUrl/api/v1/auth/login";

  // The endpoint for refreshing tokens
  static const String refreshTokenEndpoint =
      "$baseUrl/api/v1/auth/refresh-token";

  // Timeouts (Good to keep centralized)

  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
}
