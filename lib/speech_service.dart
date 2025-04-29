import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

// 定义回调函数的类型别名，让代码更清晰
typedef SpeechResultCallback = void Function(SpeechRecognitionResult result);
typedef SpeechErrorCallback = void Function(SpeechRecognitionError error);
typedef SpeechStatusCallback = void Function(String status);

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText(); // 创建 SpeechToText 实例
  bool _isAvailable = false; // 语音服务是否可用
  bool _isInitializing = false; // 是否正在初始化

  // Getter 方法，让外部可以查询是否可用
  bool get isAvailable => _isAvailable;

  // 初始化语音识别服务
  Future<bool> initialize({
    SpeechErrorCallback? onError,
    SpeechStatusCallback? onStatus,
  }) async {
    // 防止重复初始化
    if (_isInitializing || _isAvailable) {
      print("语音服务正在初始化或已初始化。");
      return _isAvailable;
    }
    _isInitializing = true;

    try {
      // 调用 speech_to_text 包的初始化方法
      _isAvailable = await _speech.initialize(
        onError: (error) {
          print("SpeechService 初始化错误: ${error.errorMsg}");
          _isAvailable = false; // 初始化失败
          _isInitializing = false;
          onError?.call(error); // 调用外部传入的错误回调
        },
        onStatus: (status) {
          print("SpeechService 状态: $status");
          // 当状态变为 'notListening' 时，通常表示初始化完成（或失败后结束）
          if (status == stt.SpeechToText.listeningStatus || status == stt.SpeechToText.notListeningStatus) {
             _isInitializing = false; // 初始化流程结束
          }
          // 更新可用状态，以防万一在状态回调中才能确定
          _isAvailable = _speech.isAvailable;
          onStatus?.call(status); // 调用外部传入的状态回调
        },
        // debugLog: true, // 可以在开发时开启详细日志
      );
      _isInitializing = false; // 确保在 await 返回后设置
      print("SpeechService 初始化完成, 可用状态: $_isAvailable");
      return _isAvailable;
    } catch (e) {
      print("捕获到 SpeechService 初始化异常: $e");
      _isAvailable = false;
      _isInitializing = false;
      // 如果需要，可以构造一个 SpeechRecognitionError 并调用 onError
      return false;
    }
  }

  // 开始语音识别监听
  Future<void> startListening({
    required SpeechResultCallback onResult,
    String localeId = 'zh_CN', // 默认使用中文
    Duration listenFor = const Duration(seconds: 10), // 最长听 10 秒
    Duration pauseFor = const Duration(seconds: 3), // 停顿 3 秒后认为结束
  }) async {
    if (!_isAvailable || _speech.isListening) {
      print("语音服务不可用或已在监听中");
      return; // 如果服务不可用或已在监听，则不执行
    }
    try {
       await _speech.listen(
         onResult: onResult, // 将结果回调给调用者
         localeId: localeId, // 设置语言
         listenFor: listenFor, // 设置最长监听时间
         pauseFor: pauseFor, // 设置停顿时间
         // partialResults: true, // 如果需要实时反馈（未确认的）结果，可以设为 true
       );
    } catch (e) {
        print("启动监听时出错: $e");
        // 这里可以向上抛出异常或调用错误回调
        rethrow; // 重新抛出，让调用者处理
    }
  }

  // 停止语音识别监听
  Future<void> stopListening() async {
    if (!_speech.isListening) {
       return; // 如果没有在监听，则不执行
    }
    try {
        await _speech.stop();
        print("SpeechService 已停止监听");
    } catch (e) {
        print("停止监听时出错: $e");
        // 这里可以向上抛出异常或调用错误回调
    }
  }

  // 取消当前的语音识别（如果正在进行）
  Future<void> cancelListening() async {
      if (!_speech.isListening) {
         return;
      }
      try {
          await _speech.cancel();
          print("SpeechService 已取消监听");
      } catch (e) {
          print("取消监听时出错: $e");
      }
    }


  // 可以添加一个方法来检查当前是否正在监听
  bool get isListening => _speech.isListening;
}