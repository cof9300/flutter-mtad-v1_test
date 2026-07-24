import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';

class RichTextEditorWidget extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  const RichTextEditorWidget({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  State<RichTextEditorWidget> createState() => _RichTextEditorWidgetState();
}

class _RichTextEditorWidgetState extends State<RichTextEditorWidget> {
  void _insertTag(String openTag, String closeTag) {
    final selection = widget.controller.selection;
    final text = widget.controller.text;

    if (selection.isValid && selection.start != selection.end) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$openTag$selectedText$closeTag',
      );
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.collapsed(
        offset: selection.start + openTag.length + selectedText.length + closeTag.length,
      );
    } else {
      final cursorPos = selection.baseOffset;
      final newText = text.substring(0, cursorPos) +
          openTag +
          closeTag +
          text.substring(cursorPos);
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.collapsed(
        offset: cursorPos + openTag.length,
      );
    }
  }

  void _showColorPicker() {
    final colorController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '색상 코드 입력',
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: 24,
            fontVariations: <FontVariation>[
              FontVariation('wght', 600),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: colorController,
              decoration: InputDecoration(
                labelText: '헥사 컬러 코드 (예: FF0000)',
                hintText: 'FF0000',
                border: OutlineInputBorder(),
              ),
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '예시: FF0000 (빨강), 0000FF (파랑)',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: 18,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final colorCode = colorController.text.trim().toUpperCase();
              if (colorCode.isNotEmpty) {
                Navigator.pop(context);
                _insertTag('<#$colorCode>', '</#$colorCode>');
              }
            },
            child: Text(
              '적용',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFE0E0E0)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    _buildToolButton(
                      icon: Icons.format_bold,
                      tooltip: '굵게',
                      onPressed: () => _insertTag('<b>', '</b>'),
                    ),
                    SizedBox(width: 8),
                    _buildToolButton(
                      icon: Icons.color_lens,
                      tooltip: '색상',
                      onPressed: _showColorPicker,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '태그: <b>굵게</b>, <#FF0000>색상</#FF0000>',
                        style: TextStyle(
                          fontFamily: AppTextStyles.bodyFontFamily,
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              TextField(
                controller: widget.controller,
                maxLines: 5,
                style: TextStyle(
                  fontFamily: AppTextStyles.bodyFontFamily,
                  fontSize: 16,
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 400),
                  ],
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                  hintText: '텍스트를 입력하세요...',
                  hintStyle: TextStyle(
                    fontFamily: AppTextStyles.bodyFontFamily,
                    fontSize: 16,
                    color: Color(0xFFBBBBBB),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Color(0xFFE0E0E0)),
          ),
          child: Icon(icon, size: 20, color: Color(0xFF333333)),
        ),
      ),
    );
  }
}

