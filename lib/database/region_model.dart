class Region {
  final String id;
  final String name;
  final String nameZh;
  final String nameEn;

  Region({
    required this.id,
    required this.name,
    required this.nameZh,
    required this.nameEn,
  });

  // 从数据库映射创建对象
  factory Region.fromMap(Map<String, dynamic> map) {
    return Region(
      id: map['id'],
      name: map['name'],
      nameZh: map['name_zh'],
      nameEn: map['name_en'],
    );
  }

  // 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_zh': nameZh,
      'name_en': nameEn,
    };
  }
}
