import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'model_manager.dart';
import 'summary_db.dart';

enum InferenceStatus { stopped, starting, running, error }

class InferenceService extends ChangeNotifier {
  static final InferenceService instance = InferenceService._();
  InferenceService._();

  InferenceStatus _status = InferenceStatus.stopped;
  String _errorMessage = '';
  InferenceModel? _model;

  InferenceStatus get status => _status;
  String get errorMessage => _errorMessage;
  InferenceModel? get model => _model;

  static bool get isAvailable => Platform.isAndroid;

  Future<void> start() async {
    if (_status == InferenceStatus.running || _status == InferenceStatus.starting) return;
    _status = InferenceStatus.starting;
    _errorMessage = '';
    notifyListeners();
    try {
      // flutter_gemma keeps active model spec only in memory.
      // After an app restart, re-register from the saved path so that
      // getActiveModel() can resolve the file location.
      if (!FlutterGemma.hasActiveModel()) {
        final savedPath = await ModelManager.getSavedModelPath();
        if (savedPath == null || savedPath.isEmpty) {
          throw Exception('未找到模型路径，请在 AI 页面重新导入模型文件');
        }
        final file = File(savedPath);
        if (!await file.exists()) {
          throw Exception('模型文件已不存在（$savedPath），请重新导入');
        }
        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
          fileType: ModelFileType.litertlm,
        ).fromFile(savedPath).install();
      }

      _model = await FlutterGemma.getActiveModel(
        maxTokens: 2048,
        preferredBackend: PreferredBackend.cpu,
      );
      _status = InferenceStatus.running;
    } catch (e) {
      _model = null;
      _status = InferenceStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await _model?.close();
    _model = null;
    _status = InferenceStatus.stopped;
    notifyListeners();
    await SummaryDb.failAllGenerating();
  }
}
