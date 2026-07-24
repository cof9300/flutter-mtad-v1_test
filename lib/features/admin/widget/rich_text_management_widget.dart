import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/rich_text_renderer.dart';
import 'package:flutter_template/features/admin/widget/rich_text_editor_widget.dart';
import 'package:flutter_template/providers/notifier/rich_text_notifier.dart';
import 'package:flutter_template/providers/notifier/locale_notifier.dart';

class RichTextManagementWidget extends ConsumerStatefulWidget {
  final String textKey;

  const RichTextManagementWidget({
    super.key,
    required this.textKey,
  });

  @override
  ConsumerState<RichTextManagementWidget> createState() => _RichTextManagementWidgetState();
}

class _DefaultValues {
  static Map<String, String>? forKey(String key) {
    switch (key) {
      case 'auth_title':
        return {
          'ko': '<b>사용자 번호</b> 또는 <b>휴대폰 번호</b>를 입력해주세요!',
          'en': 'Please enter your <b>user number</b> or <b>phone number</b>!',
          'zh': '请输入您的<b>用户编号</b>或<b>手机号码</b>！',
          'vi': 'Vui lòng nhập <b>số người dùng</b> hoặc <b>số điện thoại</b>!',
        };
      default:
        return null;
    }
  }
}

class _RichTextManagementWidgetState extends ConsumerState<RichTextManagementWidget> {
  late TextEditingController _koController;
  late TextEditingController _enController;
  late TextEditingController _zhController;
  late TextEditingController _viController;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _koController = TextEditingController();
    _enController = TextEditingController();
    _zhController = TextEditingController();
    _viController = TextEditingController();
  }

  @override
  void dispose() {
    _koController.dispose();
    _enController.dispose();
    _zhController.dispose();
    _viController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentText() async {
    if (_isInitialized) return;

    final notifier = ref.read(richTextNotifierProvider.notifier);
    final content = await notifier.getRichTextByKey(widget.textKey);

    if (content != null && mounted) {
      setState(() {
        _koController.text = content.koText;
        _enController.text = content.enText;
        _zhController.text = content.zhText;
        _viController.text = content.viText;
        _isInitialized = true;
      });
    }
  }

  void _applyDefaults() {
    final defaults = _DefaultValues.forKey(widget.textKey);
    if (defaults == null) return;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '기본값 적용',
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontVariations: <FontVariation>[FontVariation('wght', 700)],
          ),
        ),
        content: Text(
          '기본값을 적용하면 현재 입력된 내용이 모두 교체됩니다.\n계속하시겠습니까?',
          style: TextStyle(fontFamily: AppTextStyles.bodyFontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              '취소',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '적용',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                color: AppColors.headerBackground,
                fontVariations: <FontVariation>[FontVariation('wght', 700)],
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        setState(() {
          _koController.text = defaults['ko']!;
          _enController.text = defaults['en']!;
          _zhController.text = defaults['zh']!;
          _viController.text = defaults['vi']!;
        });
      }
    });
  }

  Future<void> _saveText() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(richTextNotifierProvider.notifier);
      await notifier.updateRichText(
        key: widget.textKey,
        koText: _koController.text,
        enText: _enController.text,
        zhText: _zhController.text,
        viText: _viController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '저장되었습니다.',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: 16,
              ),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '저장 중 오류가 발생했습니다.',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: 16,
              ),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    if (!_isInitialized) {
      _loadCurrentText();
    }

    String getPreviewText() {
      switch (locale.languageCode) {
        case 'ko':
          return _koController.text;
        case 'zh':
          return _zhController.text.isNotEmpty ? _zhController.text : _enController.text;
        case 'vi':
          return _viController.text.isNotEmpty ? _viController.text : _enController.text;
        default:
          return _enController.text;
      }
    }

    String getPreviewLabel() {
      switch (locale.languageCode) {
        case 'ko':
          return '한국어';
        case 'zh':
          return '中文';
        case 'vi':
          return 'Tiếng Việt';
        default:
          return 'English';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichTextEditorWidget(
          label: '한국어 텍스트',
          controller: _koController,
        ),
        SizedBox(height: 24),
        RichTextEditorWidget(
          label: '영어 텍스트',
          controller: _enController,
        ),
        SizedBox(height: 24),
        RichTextEditorWidget(
          label: '중국어 텍스트',
          controller: _zhController,
        ),
        SizedBox(height: 24),
        RichTextEditorWidget(
          label: '베트남어 텍스트',
          controller: _viController,
        ),
        SizedBox(height: 24),
        Text(
          '미리보기 (${getPreviewLabel()})',
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: 20,
            fontVariations: <FontVariation>[
              FontVariation('wght', 600),
            ],
            color: Color(0xFF111111),
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFE0E0E0)),
          ),
          child: RichTextRenderer(
            text: getPreviewText(),
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: 18,
              fontVariations: <FontVariation>[
                FontVariation('wght', 400),
              ],
              color: Color(0xFF595757),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 24),
        if (_DefaultValues.forKey(widget.textKey) != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _applyDefaults,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFFAAAAAA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '기본값 적용',
                  style: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: 20,
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 600),
                    ],
                    color: Color(0xFF555555),
                  ),
                ),
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveText,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.headerBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    '저장',
                    style: TextStyle(
                      fontFamily: AppTextStyles.bodyFontFamily,
                      fontSize: 20,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 600),
                      ],
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

