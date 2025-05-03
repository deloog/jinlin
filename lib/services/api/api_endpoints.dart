/// API端点定义
///
/// 定义所有API端点的常量
class ApiEndpoints {
  // 防止实例化
  ApiEndpoints._();
  
  // 健康检查
  static const String health = '/health';
  
  // 节日相关
  static const String holidays = '/api/holidays';
  static const String holidaysGlobal = '/api/holidays/global';
  static const String holidayUpdates = '/api/holidays/updates';
  
  // 版本相关
  static const String versions = '/api/versions';
  
  // 同步相关
  static const String syncChanges = '/api/sync/changes';
  
  // 用户相关
  static const String users = '/api/users';
  static const String userLogin = '/api/users/login';
  static const String userRegister = '/api/users/register';
  static const String userProfile = '/api/users/profile';
  
  // 提醒事项相关
  static const String reminders = '/api/reminders';
  static const String reminderSync = '/api/reminders/sync';
  
  // 设置相关
  static const String settings = '/api/settings';
  
  // 管理员相关
  static const String admin = '/api/admin';
  static const String adminHolidays = '/api/admin/holidays';
  static const String adminUsers = '/api/admin/users';
}
