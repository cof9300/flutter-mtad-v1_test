import 'package:flutter/material.dart';
import 'package:flutter_template/generated/l10n/app_localizations.dart';

class DeviceTypeHelper {
  static String getDeviceTypeName(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;
    
    switch (type.toUpperCase()) {
      case 'BP':
        return l10n.deviceTypeBP;
      case 'HS':
        return l10n.deviceTypeHC;
      case 'VA':
        return l10n.deviceTypeVA;
      case 'CM':
        return l10n.deviceTypeCM;
      case 'BC':
        return l10n.deviceTypeBC;
      case 'BS':
        return l10n.deviceTypeBS;
      case 'HRV':
        return l10n.deviceTypeHRV;
      case 'ST':
        return l10n.deviceTypeST;
      case 'AL':
        return l10n.deviceTypeAL;
      case 'MF':
        return l10n.deviceTypeMF;
      case 'LU':
        return l10n.deviceTypeLU;
      case 'OM':
        return l10n.deviceTypeOM;
      default:
        return type;
    }
  }
}










