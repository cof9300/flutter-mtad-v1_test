import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/utils/device_type_helper.dart';
import 'package:flutter_template/data/model/device.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = DeviceTypeHelper.getDeviceTypeName(context, device.type);

    return GestureDetector(
      onTap: device.isConnected ? onTap : null,
      child: Opacity(
        opacity: device.isConnected ? 1.0 : 0.5,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final minDim = math.min(w, h);
            final borderRadius = minDim * 0.09;
            final imageSize = minDim * 0.38;
            final fontSize = minDim * 0.095;
            final topPadding = h * 0.08;
            final bottomPadding = h * 0.07;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(height: topPadding),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        device.imagePath,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: imageSize,
                            height: imageSize,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(imageSize / 2),
                            ),
                            child: Icon(
                              Icons.medical_services,
                              size: imageSize * 0.6,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontFamily: AppTextStyles.bodyFontFamily,
                        fontSize: fontSize,
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        color: device.isConnected ? AppColors.primary : Colors.grey,
                        letterSpacing: -fontSize * 0.025,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
