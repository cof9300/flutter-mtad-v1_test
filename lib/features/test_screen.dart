import 'package:flutter/material.dart';
import 'package:flutter_template/core/widget/common_layout.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      child: Container(
        color: Colors.grey[300],
        child: const Center(
          child: Text(
            '메인 영역',
            style: TextStyle(
              fontSize: 48,
              fontVariations: <FontVariation>[FontVariation('wght', 700)],
            ),
          ),
        ),
      ),
    );
  }
}

