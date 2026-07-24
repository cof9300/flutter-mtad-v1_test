import 'package:flutter/material.dart';

class RichTextParser {
  static List<TextSpan> parseRichText(
    String text, {
    required TextStyle defaultStyle,
  }) {
    final List<TextSpan> spans = [];
    _parseRecursive(text, defaultStyle, spans);
    return spans;
  }

  static void _parseRecursive(
    String text,
    TextStyle currentStyle,
    List<TextSpan> spans,
  ) {
    if (text.isEmpty) return;

    int currentIndex = 0;

    while (currentIndex < text.length) {
      final boldStart = text.indexOf('<b>', currentIndex);
      final colorStart = text.indexOf('<#', currentIndex);

      int nextTagStart = -1;
      String tagType = '';

      if (boldStart != -1 && colorStart != -1) {
        if (boldStart < colorStart) {
          nextTagStart = boldStart;
          tagType = 'bold';
        } else {
          nextTagStart = colorStart;
          tagType = 'color';
        }
      } else if (boldStart != -1) {
        nextTagStart = boldStart;
        tagType = 'bold';
      } else if (colorStart != -1) {
        nextTagStart = colorStart;
        tagType = 'color';
      }

      if (nextTagStart == -1) {
        if (currentIndex < text.length) {
          spans.add(TextSpan(
            text: text.substring(currentIndex),
            style: currentStyle,
          ));
        }
        break;
      }

      if (nextTagStart > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, nextTagStart),
          style: currentStyle,
        ));
      }

      if (tagType == 'bold') {
        final boldEnd = _findMatchingCloseTag(text, nextTagStart, '<b>', '</b>');
        if (boldEnd == -1) {
          spans.add(TextSpan(
            text: text.substring(nextTagStart),
            style: currentStyle,
          ));
          break;
        }

        final innerText = text.substring(nextTagStart + 3, boldEnd);
        final boldStyle = currentStyle.copyWith(
          fontVariations: <FontVariation>[FontVariation('wght', 700)],
        );

        _parseRecursive(innerText, boldStyle, spans);

        currentIndex = boldEnd + 4;
      } else if (tagType == 'color') {
        final colorTagEnd = text.indexOf('>', nextTagStart);
        if (colorTagEnd == -1) {
          spans.add(TextSpan(
            text: text.substring(nextTagStart),
            style: currentStyle,
          ));
          break;
        }

        final colorCode = text.substring(nextTagStart + 2, colorTagEnd);
        final closeTag = '</#$colorCode>';
        final colorEnd = _findMatchingCloseTag(text, nextTagStart, '<#$colorCode>', closeTag);

        if (colorEnd == -1) {
          spans.add(TextSpan(
            text: text.substring(nextTagStart),
            style: currentStyle,
          ));
          break;
        }

        final innerText = text.substring(colorTagEnd + 1, colorEnd);
        final color = _parseColor(colorCode);
        final coloredStyle = currentStyle.copyWith(color: color);

        _parseRecursive(innerText, coloredStyle, spans);

        currentIndex = colorEnd + closeTag.length;
      }
    }
  }

  static int _findMatchingCloseTag(
    String text,
    int openTagStart,
    String openTag,
    String closeTag,
  ) {
    int depth = 1;
    int searchStart = openTagStart + openTag.length;

    while (depth > 0 && searchStart < text.length) {
      final nextOpen = text.indexOf(openTag, searchStart);
      final nextClose = text.indexOf(closeTag, searchStart);

      if (nextClose == -1) {
        return -1;
      }

      if (nextOpen != -1 && nextOpen < nextClose) {
        depth++;
        searchStart = nextOpen + openTag.length;
      } else {
        depth--;
        if (depth == 0) {
          return nextClose;
        }
        searchStart = nextClose + closeTag.length;
      }
    }

    return -1;
  }

  static Color _parseColor(String hexCode) {
    String hex = hexCode.replaceAll('#', '').toUpperCase();

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.black;
    }
  }
}
