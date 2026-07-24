import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/data/model/rich_text_content.dart';
import 'package:flutter_template/data/local/rich_text_storage_service.dart';

class RichTextNotifier extends StateNotifier<AsyncValue<Map<String, RichTextContent>>> {
  final RichTextStorageService _storageService;

  RichTextNotifier(this._storageService) : super(const AsyncValue.loading()) {
    loadAllRichTexts();
  }

  Future<void> loadAllRichTexts() async {
    state = const AsyncValue.loading();
    try {
      final richTexts = await _storageService.getAllRichTexts();
      final map = <String, RichTextContent>{};
      for (final richText in richTexts) {
        map[richText.key] = richText;
      }
      state = AsyncValue.data(map);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<RichTextContent?> getRichTextByKey(String key) async {
    return await _storageService.getRichTextByKey(key);
  }

  Future<void> updateRichText({
    required String key,
    required String koText,
    required String enText,
    required String zhText,
    required String viText,
  }) async {
    try {
      final content = RichTextContent(
        key: key,
        koText: koText,
        enText: enText,
        zhText: zhText,
        viText: viText,
        updatedAt: DateTime.now(),
      );

      await _storageService.updateRichText(content);
      await loadAllRichTexts();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> insertRichText({
    required String key,
    required String koText,
    required String enText,
    required String zhText,
    required String viText,
  }) async {
    try {
      final content = RichTextContent(
        key: key,
        koText: koText,
        enText: enText,
        zhText: zhText,
        viText: viText,
        updatedAt: DateTime.now(),
      );

      await _storageService.updateRichText(content);
      await loadAllRichTexts();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  String getText(String key, String languageCode, String fallback) {
    final data = state.value;
    if (data == null) return fallback;

    final content = data[key];
    if (content == null) return fallback;

    switch (languageCode) {
      case 'ko':
        return content.koText;
      case 'zh':
        return content.zhText.isNotEmpty ? content.zhText : content.enText;
      case 'vi':
        return content.viText.isNotEmpty ? content.viText : content.enText;
      default:
        return content.enText;
    }
  }
}

final richTextNotifierProvider = StateNotifierProvider<RichTextNotifier, AsyncValue<Map<String, RichTextContent>>>((ref) {
  throw UnimplementedError('richTextNotifierProvider must be overridden');
});

