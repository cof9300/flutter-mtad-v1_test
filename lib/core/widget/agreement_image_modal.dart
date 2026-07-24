import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AgreementImageModal extends StatelessWidget {
  final String imageUrl;

  const AgreementImageModal({
    super.key,
    required this.imageUrl,
  });

  static void show(BuildContext context, {required String imageUrl}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => AgreementImageModal(imageUrl: imageUrl),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  bool _isLocalFile(String path) {
    return path.startsWith('/') || path.startsWith('file://');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLocal = _isLocalFile(imageUrl);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(40),
      child: Stack(
        children: [
          Container(
            width: screenSize.width * 0.9,
            height: screenSize.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SingleChildScrollView(
                child: isLocal
                    ? Image.file(
                        File(imageUrl),
                        fit: BoxFit.fitWidth,
                        width: screenSize.width * 0.9,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: screenSize.height * 0.85,
                          child: Center(
                            child: Icon(Icons.error, size: 64, color: Colors.grey),
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.fitWidth,
                        width: screenSize.width * 0.9,
                        placeholder: (context, url) => Container(
                          height: screenSize.height * 0.85,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: screenSize.height * 0.85,
                          child: Center(
                            child: Icon(Icons.error, size: 64, color: Colors.grey),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => hide(context),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

