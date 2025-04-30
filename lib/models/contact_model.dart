import 'package:hive/hive.dart';

// 这个文件将由build_runner生成
// 运行命令: flutter pub run build_runner build
part 'contact_model.g.dart';

/// 联系人关系类型
@HiveType(typeId: 12)
enum RelationType {
  @HiveField(0)
  family, // 家人

  @HiveField(1)
  friend, // 朋友

  @HiveField(2)
  colleague, // 同事

  @HiveField(3)
  classmate, // 同学

  @HiveField(4)
  other // 其他
}

/// 联系人模型
@HiveType(typeId: 13)
class ContactModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  RelationType relationType;

  @HiveField(3)
  String? specificRelation; // 具体关系，如"母亲"、"父亲"等

  @HiveField(4)
  String? phoneNumber;

  @HiveField(5)
  String? email;

  @HiveField(6)
  String? avatarUrl;

  @HiveField(7)
  DateTime? birthday;

  @HiveField(8)
  bool isBirthdayLunar; // 生日是否为农历

  @HiveField(9)
  Map<String, String>? additionalInfo; // 额外信息，如喜好、忌讳等

  @HiveField(10)
  List<String>? associatedHolidayIds; // 关联的节日ID列表

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime? lastModified;

  @HiveField(13)
  Map<String, String>? names; // 多语言名称

  @HiveField(14)
  Map<String, String>? specificRelations; // 多语言具体关系

  ContactModel({
    required this.id,
    required this.name,
    required this.relationType,
    this.specificRelation,
    this.phoneNumber,
    this.email,
    this.avatarUrl,
    this.birthday,
    this.isBirthdayLunar = false,
    this.additionalInfo,
    this.associatedHolidayIds,
    DateTime? createdAt,
    this.lastModified,
    this.names,
    this.specificRelations,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从JSON创建联系人模型
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      name: json['name'] as String,
      relationType: _parseRelationType(json['relationType']),
      specificRelation: json['specificRelation'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      birthday: json['birthday'] != null
          ? DateTime.parse(json['birthday'] as String)
          : null,
      isBirthdayLunar: json['isBirthdayLunar'] as bool? ?? false,
      additionalInfo: json['additionalInfo'] != null
          ? Map<String, String>.from(json['additionalInfo'] as Map)
          : null,
      associatedHolidayIds: json['associatedHolidayIds'] != null
          ? List<String>.from(json['associatedHolidayIds'] as List)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      names: json['names'] != null
          ? Map<String, String>.from(json['names'] as Map)
          : null,
      specificRelations: json['specificRelations'] != null
          ? Map<String, String>.from(json['specificRelations'] as Map)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationType': relationType.toString().split('.').last,
      'specificRelation': specificRelation,
      'phoneNumber': phoneNumber,
      'email': email,
      'avatarUrl': avatarUrl,
      'birthday': birthday?.toIso8601String(),
      'isBirthdayLunar': isBirthdayLunar,
      'additionalInfo': additionalInfo,
      'associatedHolidayIds': associatedHolidayIds,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'names': names,
      'specificRelations': specificRelations,
    };
  }

  /// 创建带有更新时间的副本
  ContactModel copyWithLastModified() {
    return ContactModel(
      id: id,
      name: name,
      relationType: relationType,
      specificRelation: specificRelation,
      phoneNumber: phoneNumber,
      email: email,
      avatarUrl: avatarUrl,
      birthday: birthday,
      isBirthdayLunar: isBirthdayLunar,
      additionalInfo: additionalInfo,
      associatedHolidayIds: associatedHolidayIds,
      createdAt: createdAt,
      lastModified: DateTime.now(),
      names: names,
      specificRelations: specificRelations,
    );
  }

  /// 获取指定语言的名称
  String getLocalizedName(String languageCode) {
    if (names != null && names!.containsKey(languageCode)) {
      return names![languageCode]!;
    }

    return name; // 默认返回主名称
  }

  /// 获取指定语言的具体关系
  String? getLocalizedSpecificRelation(String languageCode) {
    if (specificRelations != null && specificRelations!.containsKey(languageCode)) {
      return specificRelations![languageCode];
    }

    return specificRelation; // 默认返回主具体关系
  }

  /// 解析关系类型
  static RelationType _parseRelationType(dynamic value) {
    if (value is RelationType) return value;
    if (value is String) {
      try {
        return RelationType.values.firstWhere(
          (e) => e.toString().split('.').last == value,
        );
      } catch (_) {}
    }
    return RelationType.other;
  }
}
