import 'package:uuid/uuid.dart';

/// 基础模型类
///
/// 所有模型类的基类，提供通用属性和方法
abstract class BaseModel {
  /// 唯一标识符
  final String id;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime updatedAt;
  
  /// 是否已删除
  final bool isDeleted;
  
  /// 构造函数
  BaseModel({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();
  
  /// 转换为JSON
  Map<String, dynamic> toJson();
  
  /// 创建更新后的模型
  BaseModel copyWithUpdatedAt({DateTime? updatedAt});
  
  /// 创建已删除的模型
  BaseModel copyWithDeleted({bool isDeleted = true});
  
  /// 比较两个模型是否相等
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseModel && other.id == id;
  }
  
  /// 获取哈希码
  @override
  int get hashCode => id.hashCode;
}
