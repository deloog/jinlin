/// 字符串工具类
///
/// 提供字符串相关的工具方法
class StringUtils {
  /// 私有构造函数，防止实例化
  StringUtils._();
  
  /// 检查字符串是否为空或只包含空白字符
  static bool isNullOrEmpty(String? str) {
    return str == null || str.trim().isEmpty;
  }
  
  /// 检查字符串是否不为空且不只包含空白字符
  static bool isNotNullOrEmpty(String? str) {
    return !isNullOrEmpty(str);
  }
  
  /// 获取字符串的第一个字符
  static String? getFirstChar(String? str) {
    if (isNullOrEmpty(str)) return null;
    return str!.substring(0, 1);
  }
  
  /// 获取字符串的最后一个字符
  static String? getLastChar(String? str) {
    if (isNullOrEmpty(str)) return null;
    return str!.substring(str.length - 1);
  }
  
  /// 截断字符串，超过指定长度时添加省略号
  static String truncate(String str, int maxLength, {String ellipsis = '...'}) {
    if (str.length <= maxLength) return str;
    return '${str.substring(0, maxLength)}$ellipsis';
  }
  
  /// 将字符串首字母大写
  static String capitalize(String str) {
    if (isNullOrEmpty(str)) return str;
    return str.substring(0, 1).toUpperCase() + str.substring(1);
  }
  
  /// 将字符串首字母小写
  static String decapitalize(String str) {
    if (isNullOrEmpty(str)) return str;
    return str.substring(0, 1).toLowerCase() + str.substring(1);
  }
  
  /// 将驼峰命名法转换为下划线命名法
  static String camelToSnake(String str) {
    return str.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }
  
  /// 将下划线命名法转换为驼峰命名法
  static String snakeToCamel(String str) {
    return str.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (match) => match.group(1)!.toUpperCase(),
    );
  }
  
  /// 将下划线命名法转换为帕斯卡命名法
  static String snakeToPascal(String str) {
    final camel = snakeToCamel(str);
    return capitalize(camel);
  }
  
  /// 将驼峰命名法转换为帕斯卡命名法
  static String camelToPascal(String str) {
    return capitalize(str);
  }
  
  /// 将帕斯卡命名法转换为驼峰命名法
  static String pascalToCamel(String str) {
    return decapitalize(str);
  }
  
  /// 将帕斯卡命名法转换为下划线命名法
  static String pascalToSnake(String str) {
    return camelToSnake(decapitalize(str));
  }
  
  /// 将字符串转换为安全的文件名
  static String toSafeFileName(String str) {
    return str.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
  
  /// 获取字符串的字节长度
  static int getByteLength(String str) {
    return utf8.encode(str).length;
  }
  
  /// 检查字符串是否是有效的电子邮件地址
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
  
  /// 检查字符串是否是有效的URL
  static bool isValidUrl(String url) {
    final urlRegex = RegExp(
      r'^(http|https)://[a-zA-Z0-9]+([\-\.]{1}[a-zA-Z0-9]+)*\.[a-zA-Z]{2,5}(:[0-9]{1,5})?(\/.*)?$',
    );
    return urlRegex.hasMatch(url);
  }
  
  /// 检查字符串是否是有效的手机号码
  static bool isValidPhoneNumber(String phoneNumber) {
    final phoneRegex = RegExp(
      r'^\+?[0-9]{10,15}$',
    );
    return phoneRegex.hasMatch(phoneNumber);
  }
  
  /// 检查字符串是否是有效的日期（YYYY-MM-DD）
  static bool isValidDate(String date) {
    final dateRegex = RegExp(
      r'^([0-9]{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$',
    );
    return dateRegex.hasMatch(date);
  }
  
  /// 检查字符串是否是有效的时间（HH:MM）
  static bool isValidTime(String time) {
    final timeRegex = RegExp(
      r'^([01][0-9]|2[0-3]):([0-5][0-9])$',
    );
    return timeRegex.hasMatch(time);
  }
  
  /// 检查字符串是否是有效的日期时间（YYYY-MM-DD HH:MM）
  static bool isValidDateTime(String dateTime) {
    final dateTimeRegex = RegExp(
      r'^([0-9]{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]) ([01][0-9]|2[0-3]):([0-5][0-9])$',
    );
    return dateTimeRegex.hasMatch(dateTime);
  }
  
  /// 检查字符串是否只包含数字
  static bool isNumeric(String str) {
    final numericRegex = RegExp(r'^[0-9]+$');
    return numericRegex.hasMatch(str);
  }
  
  /// 检查字符串是否只包含字母
  static bool isAlpha(String str) {
    final alphaRegex = RegExp(r'^[a-zA-Z]+$');
    return alphaRegex.hasMatch(str);
  }
  
  /// 检查字符串是否只包含字母和数字
  static bool isAlphanumeric(String str) {
    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    return alphanumericRegex.hasMatch(str);
  }
  
  /// 获取字符串中的数字
  static String getNumbers(String str) {
    final numericRegex = RegExp(r'[0-9]+');
    final matches = numericRegex.allMatches(str);
    return matches.map((match) => match.group(0)).join();
  }
  
  /// 获取字符串中的字母
  static String getAlpha(String str) {
    final alphaRegex = RegExp(r'[a-zA-Z]+');
    final matches = alphaRegex.allMatches(str);
    return matches.map((match) => match.group(0)).join();
  }
  
  /// 反转字符串
  static String reverse(String str) {
    return String.fromCharCodes(str.runes.toList().reversed);
  }
  
  /// 计算两个字符串的相似度（Levenshtein距离）
  static double similarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    
    final len1 = s1.length;
    final len2 = s2.length;
    
    if (len1 == 0 || len2 == 0) return 0.0;
    
    final maxLen = len1 > len2 ? len1 : len2;
    final distance = levenshteinDistance(s1, s2);
    
    return (maxLen - distance) / maxLen;
  }
  
  /// 计算Levenshtein距离
  static int levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;
    
    final d = List.generate(len1 + 1, (_) => List.filled(len2 + 1, 0));
    
    for (var i = 0; i <= len1; i++) {
      d[i][0] = i;
    }
    
    for (var j = 0; j <= len2; j++) {
      d[0][j] = j;
    }
    
    for (var i = 1; i <= len1; i++) {
      for (var j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return d[len1][len2];
  }
}

// UTF-8编码器
class _Utf8Encoder {
  List<int> encode(String str) {
    return str.codeUnits.expand((charCode) {
      if (charCode < 0x80) {
        return [charCode];
      } else if (charCode < 0x800) {
        return [
          0xC0 | (charCode >> 6),
          0x80 | (charCode & 0x3F),
        ];
      } else if (charCode < 0x10000) {
        return [
          0xE0 | (charCode >> 12),
          0x80 | ((charCode >> 6) & 0x3F),
          0x80 | (charCode & 0x3F),
        ];
      } else {
        return [
          0xF0 | (charCode >> 18),
          0x80 | ((charCode >> 12) & 0x3F),
          0x80 | ((charCode >> 6) & 0x3F),
          0x80 | (charCode & 0x3F),
        ];
      }
    }).toList();
  }
}

// UTF-8编码器实例
final utf8 = _Utf8Encoder();
