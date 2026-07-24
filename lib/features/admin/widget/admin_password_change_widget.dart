import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/theme/app_theme.dart';
import 'package:flutter_template/core/widget/admin_password_dialog.dart';
import 'package:flutter_template/config/service_locator.dart';

class AdminPasswordChangeWidget extends ConsumerStatefulWidget {
  const AdminPasswordChangeWidget({super.key});

  @override
  ConsumerState<AdminPasswordChangeWidget> createState() =>
      _AdminPasswordChangeWidgetState();
}

class _AdminPasswordChangeWidgetState
    extends ConsumerState<AdminPasswordChangeWidget> {
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _isChangingPassword = false;
  String? _errorMessage;

  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = 1080.0;
    return (screenWidth / baseWidth * baseSize)
        .clamp(baseSize * 0.5, baseSize * 1.5);
  }

  Future<void> _handleChangePassword() async {
    if (_currentPassword.length != 4 ||
        _newPassword.length != 4 ||
        _confirmPassword.length != 4) {
      setState(() {
        _errorMessage = '모든 비밀번호를 4자리로 입력해주세요.';
      });
      return;
    }

    if (_newPassword != _confirmPassword) {
      setState(() {
        _errorMessage = '새 비밀번호가 일치하지 않습니다.';
      });
      return;
    }

    final serviceLocator = ServiceLocator();
    final adminPasswordService = serviceLocator.adminPasswordService;

    final isValid = await adminPasswordService.verifyPassword(_currentPassword);
    if (!isValid) {
      setState(() {
        _errorMessage = '현재 비밀번호가 일치하지 않습니다.';
        _currentPassword = '';
      });
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _errorMessage = null;
    });

    try {
      await adminPasswordService.setPassword(_newPassword);
      setState(() {
        _currentPassword = '';
        _newPassword = '';
        _confirmPassword = '';
        _errorMessage = '비밀번호가 변경되었습니다.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = '비밀번호 변경 중 오류가 발생했습니다.';
      });
    } finally {
      setState(() {
        _isChangingPassword = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonFontSize = _getResponsiveSize(context, 36);
    final errorFontSize = _getResponsiveSize(context, 28);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPasswordField(
          context,
          label: '현재 비밀번호',
          value: _currentPassword,
          field: 'current',
        ),
        SizedBox(height: _getResponsiveSize(context, 40)),
        _buildPasswordField(
          context,
          label: '새 비밀번호',
          value: _newPassword,
          field: 'new',
        ),
        SizedBox(height: _getResponsiveSize(context, 40)),
        _buildPasswordField(
          context,
          label: '새 비밀번호 확인',
          value: _confirmPassword,
          field: 'confirm',
        ),
        if (_errorMessage != null) ...[
          SizedBox(height: _getResponsiveSize(context, 20)),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontFamily: AppTextStyles.bodyFontFamily,
              fontSize: errorFontSize,
              fontVariations: <FontVariation>[
                FontVariation('wght', 400),
              ],
              color: Colors.red,
            ),
          ),
        ],
        SizedBox(height: _getResponsiveSize(context, 60)),
        GestureDetector(
          onTap: _isChangingPassword ? null : _handleChangePassword,
          child: Container(
            width: double.infinity,
            padding:
                EdgeInsets.symmetric(vertical: _getResponsiveSize(context, 20)),
            decoration: BoxDecoration(
              color: _isChangingPassword
                  ? Color(0xFFCCCCCC)
                  : AppColors.headerBackground,
              borderRadius:
                  BorderRadius.circular(_getResponsiveSize(context, 16)),
            ),
            alignment: Alignment.center,
            child: Text(
              _isChangingPassword ? '변경 중...' : '비밀번호 변경',
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: buttonFontSize,
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

  Widget _buildPasswordField(
    BuildContext context, {
    required String label,
    required String value,
    required String field,
  }) {
    final labelFontSize = _getResponsiveSize(context, 28);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFontFamily,
            fontSize: labelFontSize,
            fontVariations: <FontVariation>[
              FontVariation('wght', 600),
            ],
            color: Color(0xFF595757),
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 12)),
        GestureDetector(
          onTap: () {
            AdminPasswordDialog.show(
              context,
              showConfirmButton: true,
              onSuccess: (password) {
                setState(() {
                  switch (field) {
                    case 'current':
                      _currentPassword = password;
                      break;
                    case 'new':
                      _newPassword = password;
                      break;
                    case 'confirm':
                      _confirmPassword = password;
                      break;
                  }
                  _errorMessage = null;
                });
              },
            );
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                vertical: _getResponsiveSize(context, 24),
                horizontal: _getResponsiveSize(context, 32)),
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius:
                  BorderRadius.circular(_getResponsiveSize(context, 16)),
              border: Border.all(
                color: Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: Text(
              value.padRight(4, '○'),
              style: TextStyle(
                fontFamily: AppTextStyles.bodyFontFamily,
                fontSize: _getResponsiveSize(context, 36),
                fontVariations: <FontVariation>[
                  FontVariation('wght', 600),
                ],
                color: AppColors.primary,
                letterSpacing: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
