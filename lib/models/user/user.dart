import 'package:jinlin_app/models/base_model.dart';

/// 用户角色
enum UserRole {
  /// 普通用户
  user,

  /// 高级用户
  premium,

  /// 管理员
  admin,
}

/// 用户模型
///
/// 表示应用程序的用户
class User extends BaseModel {
  /// 用户名
  final String username;

  /// 电子邮件
  final String email;

  /// 显示名称
  final String? displayName;

  /// 头像URL
  final String? avatarUrl;

  /// 用户角色
  final UserRole role;

  /// 是否已验证电子邮件
  final bool isEmailVerified;

  /// 最后登录时间
  final DateTime? lastLoginAt;

  /// 构造函数
  User({
    super.id,
    required this.username,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.role = UserRole.user,
    this.isEmailVerified = false,
    this.lastLoginAt,
    super.createdAt,
    super.updatedAt,
    super.isDeleted = false,
  });

  /// 从JSON创建用户
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: _parseUserRole(json['role'] as String?),
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  /// 转换为JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'role': _userRoleToString(role),
      'is_email_verified': isEmailVerified,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  /// 创建更新后的用户
  User copyWith({
    String? username,
    String? email,
    String? displayName,
    String? avatarUrl,
    UserRole? role,
    bool? isEmailVerified,
    DateTime? lastLoginAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// 创建更新后的模型
  @override
  BaseModel copyWithUpdatedAt({DateTime? updatedAt}) {
    return copyWith(updatedAt: updatedAt);
  }

  /// 创建已删除的模型
  @override
  BaseModel copyWithDeleted({bool isDeleted = true}) {
    return copyWith(isDeleted: isDeleted);
  }

  /// 解析用户角色
  static UserRole _parseUserRole(String? role) {
    switch (role) {
      case 'premium':
        return UserRole.premium;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }

  /// 用户角色转字符串
  static String _userRoleToString(UserRole role) {
    switch (role) {
      case UserRole.premium:
        return 'premium';
      case UserRole.admin:
        return 'admin';
      default:
        return 'user';
    }
  }
}
