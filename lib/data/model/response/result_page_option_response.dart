import 'package:flutter_template/data/model/response/device_page_option_response.dart';

class ResultPageOptionResponse {
  final List<MediaItem> cm;
  final bool masking;

  ResultPageOptionResponse({
    required this.cm,
    required this.masking,
  });

  factory ResultPageOptionResponse.fromJson(Map<String, dynamic> json) {
    final resultData = json['resultData'] as Map<String, dynamic>;

    return ResultPageOptionResponse(
      cm: (resultData['cm'] as List<dynamic>?)
              ?.map((item) => MediaItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      masking: resultData['masking'] as bool? ?? false,
    );
  }
}




