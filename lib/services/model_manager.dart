import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

class ModelManager {
  // Gemma 3B Instruct (MediaPipe TFLite format, ~1.7 GB)
  // https://www.kaggle.com/models/google/gemma/frameworks/tfLite
  static const modelUrl =
      'https://your-cdn-or-storage/gemma-3b-it-gpu-int4.bin';

  // flutter_gemma 内部固定使用 documents 目录下的 model.bin
  static Future<File> get _modelFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/model.bin');
  }

  static Future<bool> isDownloaded() =>
      FlutterGemmaPlugin.instance.isLoaded;

  /// 从网络下载，返回进度流（0-100 百分比）
  static Stream<int> downloadFromNetwork() =>
      FlutterGemmaPlugin.instance.loadNetworkModelWithProgress(url: modelUrl);

  /// 打开文件选择器让用户选择本地 .bin 文件，复制到 documents/model.bin
  /// 返回 null 表示用户取消
  static Future<ImportResult> importFromLocal() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin'],
      allowMultiple: false,
      dialogTitle: '选择 Gemma 模型文件 (.bin)',
    );

    if (result == null || result.files.isEmpty) {
      return ImportResult.cancelled;
    }

    final srcPath = result.files.single.path;
    if (srcPath == null) return ImportResult.cancelled;

    final src = File(srcPath);
    if (!src.existsSync()) return ImportResult.notFound;

    final dest = await _modelFile;
    if (dest.existsSync()) dest.deleteSync();

    await src.copy(dest.path);
    return ImportResult.success;
  }

  static Future<void> delete() async {
    final f = await _modelFile;
    if (f.existsSync()) f.deleteSync();
  }

  static Future<int> sizeBytes() async {
    final f = await _modelFile;
    return f.existsSync() ? f.lengthSync() : 0;
  }
}

enum ImportResult { success, cancelled, notFound }
