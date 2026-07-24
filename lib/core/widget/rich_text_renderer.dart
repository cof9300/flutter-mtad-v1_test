import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/rich_text_parser.dart';

class RichTextRenderer extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const RichTextRenderer({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final spans = RichTextParser.parseRichText(
      text,
      defaultStyle: style,
    );

    return RichText(
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(children: spans),
    );
  }
}

