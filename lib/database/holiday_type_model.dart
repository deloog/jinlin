class HolidayType {
  final String id;
  final String name;
  final String nameZh;
  final String nameEn;
  final int iconCode;

  HolidayType({
    required this.id,
    required this.name,
    required this.nameZh,
    required this.nameEn,
    required this.iconCode,
  });

  // 从数据库映射创建对象
  factory HolidayType.fromMap(Map<String, dynamic> map) {
    return HolidayType(
      id: map['id'],
      name: map['name'],
      nameZh: map['name_zh'],
      nameEn: map['name_en'],
      iconCode: map['icon_code'],
    );
  }

  // 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_zh': nameZh,
      'name_en': nameEn,
      'icon_code': iconCode,
    };
  }
}
