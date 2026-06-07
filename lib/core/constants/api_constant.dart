class ApiConstant {
  // Base URL for API endpoints
  static const String baseUrl = "https://fieldguard.duckdns.org";

  // The endpoint for user login
  static const String loginEndpoint = "$baseUrl/api/v1/auth/login";
  // Public — no auth. Returns { "version": "YYYY-MM-DD" }.
  static const String legalVersionEndpoint = "$baseUrl/api/v1/legal/version";
  // PATCH (update own profile, EMPLOYEE) + base for profile ops.
  static const String profileEndpoint = "$baseUrl/api/v1/employees/profile";
  static const String authMeEndpoint = "$baseUrl/api/v1/auth/me";
  // Current-month profile stats (EMPLOYEE only; 403 for ADMIN/MANAGER).
  static const String authMeStatsEndpoint = "$baseUrl/api/v1/auth/me/stats";
  // Consolidated home-screen dashboard: profile + one task per status + live
  // tracking summary. Single round-trip instead of 5 separate calls.
  static const String dashboardSummaryEndpoint =
      "$baseUrl/api/v1/dashboard/summary";
  static const String dashboardTodayTasksEndpoint =
      "$baseUrl/api/v1/dashboard/today-tasks";
  static const String shopsEndpoint = "$baseUrl/api/v1/shops";
  static String shopDetailEndpoint(int id) => "$baseUrl/api/v1/shops/$id";
  static const String tasksEndpoint = "$baseUrl/api/v1/tasks/my-tasks";
  static String taskDetailEndpoint(int id) => "$baseUrl/api/v1/tasks/$id";
  static String taskUpdateEndpoint(int id) => "$baseUrl/api/v1/tasks/$id";
  // Toggle a single checklist item's done-state (assignee only). Body:
  // { "done": bool }. Returns the updated task with items + itemsProgress.
  static String taskItemUpdateEndpoint(int taskId, int itemId) =>
      "$baseUrl/api/v1/tasks/$taskId/items/$itemId";
  static const String taskHistoryEndpoint = "$baseUrl/api/v1/tasks/history";
  static const String presignedUrlEndpoint = "$baseUrl/api/v1/uploads/presigned-url";
  static const String geofenceVisitsEndpoint = "$baseUrl/api/v1/geofence-visits";

  // Cash/cheque collections — POST records a collection, GET returns the
  // shop's outstanding ledger summary.
  static const String collectionsEndpoint = "$baseUrl/api/v1/collections";
  static String shopOutstandingEndpoint(int shopId) =>
      "$baseUrl/api/v1/collections/shops/$shopId/outstanding";

  // Registers/updates this device's FCM push token for the signed-in user.
  // Body: { deviceId, pushToken, platform, appVersion }. Requires auth.
  static const String pushTokenEndpoint = "$baseUrl/api/v1/device/push-token";

  // In-app notification inbox. GET supports ?page&limit&unreadOnly and returns
  // { notifications, unreadCount, total, page, limit }. Requires an approved
  // company (pending companies get 403). PATCH marks a single one read (no
  // bulk "mark all" endpoint — the client loops).
  static const String notificationsEndpoint = "$baseUrl/api/v1/notifications";
  static String notificationReadEndpoint(int id) =>
      "$baseUrl/api/v1/notifications/$id/read";

  // The endpoint for refreshing tokens
  static const String refreshTokenEndpoint =
      "$baseUrl/api/v1/auth/refresh-token";

  // Timeouts (Good to keep centralized)

  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
}
