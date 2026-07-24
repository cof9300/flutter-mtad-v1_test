import 'package:flutter/material.dart';

class TextParser {
  static TextSpan parseStyledText(
    String text, {
    required TextStyle defaultStyle,
    required TextStyle boldStyle,
    TextStyle? coloredBoldStyle,
  }) {
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'<b>(.*?)</b>');
    final RegExp coloredBoldRegex = RegExp(r'<c>(.*?)</c>');
    
    int lastIndex = 0;
    final List<MapEntry<int, int>> boldMatches = [];
    final List<MapEntry<int, int>> coloredBoldMatches = [];
    
    for (final match in boldRegex.allMatches(text)) {
      boldMatches.add(MapEntry(match.start, match.end));
    }
    
    for (final match in coloredBoldRegex.allMatches(text)) {
      coloredBoldMatches.add(MapEntry(match.start, match.end));
    }
    
    for (final match in coloredBoldRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        final beforeText = text.substring(lastIndex, match.start);
        final cleanBeforeText = beforeText.replaceAll(RegExp(r'</?b>'), '');
        
        _addStyledSegments(cleanBeforeText, spans, defaultStyle, boldStyle, beforeText.contains('<b>'));
      }

      spans.add(TextSpan(
        text: match.group(1),
        style: coloredBoldStyle ?? boldStyle,
      ));

      lastIndex = match.end;
    }
    
    if (coloredBoldMatches.isEmpty) {
      for (final match in boldRegex.allMatches(text)) {
        if (match.start > lastIndex) {
          spans.add(TextSpan(
            text: text.substring(lastIndex, match.start),
            style: defaultStyle,
          ));
        }

        spans.add(TextSpan(
          text: match.group(1),
          style: boldStyle,
        ));

        lastIndex = match.end;
      }
    }

    if (lastIndex < text.length) {
      final remainingText = text.substring(lastIndex).replaceAll(RegExp(r'</?b>'), '');
      if (remainingText.isNotEmpty) {
        spans.add(TextSpan(
          text: remainingText,
          style: defaultStyle,
        ));
      }
    }

    return TextSpan(children: spans);
  }
  
  static void _addStyledSegments(
    String text,
    List<TextSpan> spans,
    TextStyle defaultStyle,
    TextStyle boldStyle,
    bool hasBoldTag,
  ) {
    if (hasBoldTag) {
      final RegExp boldRegex = RegExp(r'<b>(.*?)</b>');
      int lastIndex = 0;
      
      for (final match in boldRegex.allMatches(text)) {
        if (match.start > lastIndex) {
          spans.add(TextSpan(
            text: text.substring(lastIndex, match.start),
            style: defaultStyle,
          ));
        }

        spans.add(TextSpan(
          text: match.group(1),
          style: boldStyle,
        ));

        lastIndex = match.end;
      }

      if (lastIndex < text.length) {
        spans.add(TextSpan(
          text: text.substring(lastIndex),
          style: defaultStyle,
        ));
      }
    } else {
      spans.add(TextSpan(
        text: text,
        style: defaultStyle,
      ));
    }
  }
}

