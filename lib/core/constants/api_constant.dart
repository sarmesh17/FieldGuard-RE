class ApiConstant {
  // Base URL for API endpoints
  static const String baseUrl = "https://fieldguard-be.onrender.com";

  // The endpoint for user login
  static const String loginEndpoint = "$baseUrl/api/v1/auth/login";
  // PATCH (update own profile, EMPLOYEE) + base for profile ops.
  static const String profileEndpoint = "$baseUrl/api/v1/employees/profile";
  static const String authMeEndpoint = "$baseUrl/api/v1/auth/me";
  static const String shopsEndpoint = "$baseUrl/api/v1/shops";
  static String shopDetailEndpoint(int id) => "$baseUrl/api/v1/shops/$id";
  static const String tasksEndpoint = "$baseUrl/api/v1/tasks/my-tasks";
  static String taskDetailEndpoint(int id) => "$baseUrl/api/v1/tasks/$id";
  static String taskUpdateEndpoint(int id) => "$baseUrl/api/v1/tasks/$id";
  static const String taskHistoryEndpoint = "$baseUrl/api/v1/tasks/history";
  static const String presignedUrlEndpoint = "$baseUrl/api/v1/uploads/presigned-url";
  static const String geofenceVisitsEndpoint = "$baseUrl/api/v1/geofence-visits";

  // Cash/cheque collections — POST records a collection, GET returns the
  // shop's outstanding ledger summary.
  static const String collectionsEndpoint = "$baseUrl/api/v1/collections";
  static String shopOutstandingEndpoint(int shopId) =>
      "$baseUrl/api/v1/collections/shops/$shopId/outstanding";

  // The endpoint for refreshing tokens
  static const String refreshTokenEndpoint =
      "$baseUrl/api/v1/auth/refresh-token";

  // Timeouts (Good to keep centralized)

  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
}
