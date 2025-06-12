/// Data cache singleton untuk menyimpan data yang sudah di-load
/// Ini memungkinkan data persist across navigation tanpa mengubah navigation pattern
class DataCache {
  static final DataCache _instance = DataCache._internal();
  factory DataCache() => _instance;
  DataCache._internal();

  // Cache untuk history screen
  dynamic _historyData;
  dynamic _userProfile;
  dynamic _dashboardData;
  DateTime? _lastHistoryUpdate;
  DateTime? _lastProfileUpdate;
  DateTime? _lastDashboardUpdate;

  // User ID untuk memastikan cache isolation antar user
  String? _currentUserId;

  // Cache expiry duration (5 menit)
  static const Duration _cacheExpiry = Duration(minutes: 5);
  // History data cache
  dynamic get historyData {
    if (_lastHistoryUpdate != null &&
        DateTime.now().difference(_lastHistoryUpdate!) < _cacheExpiry) {
      return _historyData;
    }
    return null;
  }

  void setHistoryData(dynamic data, {String? userId}) {
    // Clear cache if user has changed
    if (userId != null && _currentUserId != null && _currentUserId != userId) {
      clearAll();
    }
    _historyData = data;
    _lastHistoryUpdate = DateTime.now();
    if (userId != null) _currentUserId = userId;
  }

  // User profile cache
  dynamic get userProfile {
    if (_lastProfileUpdate != null &&
        DateTime.now().difference(_lastProfileUpdate!) < _cacheExpiry) {
      return _userProfile;
    }
    return null;
  }

  void setUserProfile(dynamic data, {String? userId}) {
    // Clear cache if user has changed
    if (userId != null && _currentUserId != null && _currentUserId != userId) {
      clearAll();
    }
    _userProfile = data;
    _lastProfileUpdate = DateTime.now();
    if (userId != null) _currentUserId = userId;
  }

  // Dashboard data cache
  dynamic get dashboardData {
    if (_lastDashboardUpdate != null &&
        DateTime.now().difference(_lastDashboardUpdate!) < _cacheExpiry) {
      return _dashboardData;
    }
    return null;
  }

  void setDashboardData(dynamic data, {String? userId}) {
    // Clear cache if user has changed
    if (userId != null && _currentUserId != null && _currentUserId != userId) {
      clearAll();
    }
    _dashboardData = data;
    _lastDashboardUpdate = DateTime.now();
    if (userId != null) _currentUserId = userId;
  }

  // Clear all cache
  void clearAll() {
    _historyData = null;
    _userProfile = null;
    _dashboardData = null;
    _lastHistoryUpdate = null;
    _lastProfileUpdate = null;
    _lastDashboardUpdate = null;
    _currentUserId = null; // Clear user ID as well
  }

  // Clear all cache for user change (public method for logout/login)
  void clearAllForUserChange() {
    clearAll();
  }

  // Set current user ID (to be called after login)
  void setCurrentUserId(String userId) {
    // If user has changed, clear all cache
    if (_currentUserId != null && _currentUserId != userId) {
      clearAll();
    }
    _currentUserId = userId;
  }

  // Get current user ID
  String? get currentUserId => _currentUserId;

  // Clear specific cache
  void clearHistoryCache() {
    _historyData = null;
    _lastHistoryUpdate = null;
  }

  void clearProfileCache() {
    _userProfile = null;
    _lastProfileUpdate = null;
  }

  void clearDashboardCache() {
    _dashboardData = null;
    _lastDashboardUpdate = null;
  }

  // Check if cache has data (regardless of expiry)
  bool get hasHistoryData => _historyData != null;
  bool get hasUserProfile => _userProfile != null;
  bool get hasDashboardData => _dashboardData != null;

  // Force refresh flags
  bool _forceRefreshHistory = false;
  bool _forceRefreshProfile = false;
  bool _forceRefreshDashboard = false;

  bool get shouldForceRefreshHistory => _forceRefreshHistory;
  bool get shouldForceRefreshProfile => _forceRefreshProfile;
  bool get shouldForceRefreshDashboard => _forceRefreshDashboard;

  void setForceRefreshHistory() {
    _forceRefreshHistory = true;
  }

  void setForceRefreshProfile() {
    _forceRefreshProfile = true;
  }

  void setForceRefreshDashboard() {
    _forceRefreshDashboard = true;
  }

  void clearForceRefreshFlags() {
    _forceRefreshHistory = false;
    _forceRefreshProfile = false;
    _forceRefreshDashboard = false;
  }
}
