import 'package:flutter/material.dart';

/// 语言模型
///
/// 表示应用程序支持的语言
class Language {
  /// 语言代码
  final String code;
  
  /// 国家代码
  final String? countryCode;
  
  /// 语言名称（英文）
  final String nameEn;
  
  /// 语言名称（本地）
  final String nameLocal;
  
  /// 语言图标
  final IconData? icon;
  
  /// 构造函数
  const Language({
    required this.code,
    this.countryCode,
    required this.nameEn,
    required this.nameLocal,
    this.icon,
  });
  
  /// 创建语言区域
  Locale toLocale() {
    return countryCode != null
        ? Locale(code, countryCode)
        : Locale(code);
  }
  
  /// 从语言区域创建
  static Language fromLocale(Locale locale) {
    return supportedLanguages.firstWhere(
      (language) => language.code == locale.languageCode && language.countryCode == locale.countryCode,
      orElse: () => supportedLanguages.firstWhere(
        (language) => language.code == locale.languageCode,
        orElse: () => supportedLanguages.first,
      ),
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Language &&
        other.code == code &&
        other.countryCode == countryCode;
  }
  
  @override
  int get hashCode => code.hashCode ^ (countryCode?.hashCode ?? 0);
  
  /// 支持的语言列表
  static const List<Language> supportedLanguages = [
    // 英语（美国）
    Language(
      code: 'en',
      countryCode: 'US',
      nameEn: 'English',
      nameLocal: 'English',
      icon: Icons.language,
    ),
    
    // 中文（简体）
    Language(
      code: 'zh',
      countryCode: 'CN',
      nameEn: 'Chinese (Simplified)',
      nameLocal: '简体中文',
      icon: Icons.language,
    ),
    
    // 中文（繁体）
    Language(
      code: 'zh',
      countryCode: 'TW',
      nameEn: 'Chinese (Traditional)',
      nameLocal: '繁體中文',
      icon: Icons.language,
    ),
    
    // 日语
    Language(
      code: 'ja',
      countryCode: 'JP',
      nameEn: 'Japanese',
      nameLocal: '日本語',
      icon: Icons.language,
    ),
    
    // 韩语
    Language(
      code: 'ko',
      countryCode: 'KR',
      nameEn: 'Korean',
      nameLocal: '한국어',
      icon: Icons.language,
    ),
    
    // 法语
    Language(
      code: 'fr',
      countryCode: 'FR',
      nameEn: 'French',
      nameLocal: 'Français',
      icon: Icons.language,
    ),
    
    // 德语
    Language(
      code: 'de',
      countryCode: 'DE',
      nameEn: 'German',
      nameLocal: 'Deutsch',
      icon: Icons.language,
    ),
  ];
}
