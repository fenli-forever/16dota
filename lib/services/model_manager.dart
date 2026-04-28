import 'package:file_picker/file_picker.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelManager {
  static const _kModelPathKey = 'ai_model_file_path';
  static const modelUrl =
      'https://your-cdn-or-storage/gemma-4-E4B-it.litertlm';

  static Future<bool> isInstalled() => FlutterGemma.isModelInstalled(_modelId);

  // 获取已保存的模型路径（用于重新注册）
  static Future<String?> getSavedModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kModelPathKey);
  }

  static Future<void> _saveModelPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kModelPathKey, path);
  }

  // 从网络下载，带进度回调
  static Future<void> downloadFromNetwork({
    required void Function(int pct) onProgress,
  }) async {
    await FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm,
    )
        .fromNetwork(modelUrl)
        .withProgress(onProgress)
        .install();

    // 保存下载后模型的路径（documents dir + filename）
    final dir = await getApplicationDocumentsDirectory();
    final savedPath = p.join(dir.path, _modelId);
    await _saveModelPath(savedPath);
  }

  // 打开文件选择器，选择 .litertlm 文件直接安装
  // 返回 null 表示用户取消
  static Future<ImportResult> importFromLocal() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      dialogTitle: '选择 Gemma 模型文件 (.litertlm)',
    );

    if (result == null || result.files.isEmpty) return ImportResult.cancelled;
    final path = result.files.single.path;
    if (path == null) return ImportResult.cancelled;

    await FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm,
    ).fromFile(path).install();

    // 保存外部文件路径供重启后重新注册
    await _saveModelPath(path);

    return ImportResult.success;
  }

  // 模型 ID = 文件名（flutter_gemma 用文件名做 key）
  static String get installedModelId {
    final uri = Uri.parse(modelUrl);
    return uri.pathSegments.last;
  }

  static String get _modelId => installedModelId;
}

enum ImportResult { success, cancelled }
