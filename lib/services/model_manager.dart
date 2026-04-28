import 'package:file_picker/file_picker.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class ModelManager {
  static const modelUrl =
      'https://your-cdn-or-storage/gemma-4-E4B-it.litertlm';

  static Future<bool> isInstalled() => FlutterGemma.isModelInstalled(_modelId);

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

    return ImportResult.success;
  }

  // 模型 ID = 文件名（flutter_gemma 用文件名做 key）
  static String get _modelId {
    final uri = Uri.parse(modelUrl);
    return uri.pathSegments.last;
  }
}

enum ImportResult { success, cancelled }
