import 'dart:typed_data';

/// 자율신경계(HRV) MP-SDK 프레임 프로토콜.
///
/// 프레임 구조: HEADER(0xFF) + SOURCE(1) + LEN(2, big-endian, CODE+DATA+CRC 길이) +
///             CODE(1) + DATA(N) + CRC16-MODBUS(2)
class HrvProtocol {
  HrvProtocol._();

  static const int header = 0xFF;
  static const int sourceTerminal = 0x55;
  static const int sourceSdk = 0x4D;

  // User Terminal → MP-SDK
  static const int codeStart = 0x44; // 'D'
  static const int codeStop = 0x50; // 'P'
  static const int codeResultRequest = 0x52; // 'R'
  static const int codeInfoRequest = 0x49; // 'I'
  static const int codeTimeRequest = 0x54; // 'T'

  // MP-SDK → User Terminal
  static const int codeMeasureData = 0x6D; // 'm'
  static const int codeResult = 0x72; // 'r'
  static const int codeStatus = 0x73; // 's'
  static const int codeError = 0x65; // 'e'
  static const int codeInfo = 0x69; // 'i'
  static const int codeTime = 0x74; // 't'
}

/// Start Message(0x44) Data 구성값.
class HrvSensorType {
  HrvSensorType._();
  static const int mouse = 0x50; // 'P'
  static const int finger = 0x46; // 'F'
}

class HrvGenderCode {
  HrvGenderCode._();
  static const int female = 0x46; // 'F'
  static const int male = 0x4D; // 'M'
}

class HrvReferenceType {
  HrvReferenceType._();
  static const int asian = 0x41; // 'A'
  static const int western = 0x57; // 'W'
}

/// Result Request Message(0x52) Data 값.
class HrvResultRequestType {
  HrvResultRequestType._();
  static const int basic = 0x44; // 'D'
  static const int apg = 0x41; // 'A'
  static const int hrv = 0x48; // 'H'
}

/// Status Message(0x73) Data 값.
class HrvStatusCode {
  HrvStatusCode._();
  static const int userStopped = 0x75; // 'u'
  static const int preview = 0x76; // 'v'
  static const int measuring = 0x73; // 's'
  static const int finished = 0x70; // 'p'
  static const int booting = 0x6F; // 'o'
}

/// Error Message(0x65) Data 값.
class HrvErrorCode {
  HrvErrorCode._();
  static const int startError = 0x73; // 's'
  static const int signalError = 0x6D; // 'm'
  static const int lengthError = 0x63; // 'c'
  static const int noResult = 0x6E; // 'n'
  static const int undefinedCode = 0x75; // 'u'
}

/// Measure Data Message(0x6D)의 Measure Error 값.
class HrvMeasureErrorCode {
  HrvMeasureErrorCode._();
  static const int normal = 0x00;
  static const int fingerOut = 0x66; // 'f'
  static const int badSignal = 0x73; // 's'
  static const int sensorDisconnected = 0x70; // 'p'
}

class HrvCrc16 {
  HrvCrc16._();

  static int compute(List<int> data, [int? length]) {
    final int count = length ?? data.length;
    int crc = 0xFFFF;
    for (int i = 0; i < count; i++) {
      crc ^= data[i] & 0xFF;
      for (int b = 0; b < 8; b++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc & 0xFFFF;
  }

  static bool verify(List<int> frame) {
    if (frame.length < 3) return false;
    final int crc = compute(frame, frame.length - 2);
    return frame[frame.length - 2] == (crc & 0xFF) &&
        frame[frame.length - 1] == ((crc >> 8) & 0xFF);
  }
}

class HrvFrame {
  final int source;
  final int code;
  final Uint8List data;

  const HrvFrame(
      {required this.source, required this.code, required this.data});
}

class HrvFrameEncoder {
  HrvFrameEncoder._();

  static Uint8List build(int code, List<int> data) {
    final int dataLen = 1 + data.length + 2;
    final BytesBuilder builder = BytesBuilder();
    builder.addByte(HrvProtocol.header);
    builder.addByte(HrvProtocol.sourceTerminal);
    builder.addByte((dataLen >> 8) & 0xFF);
    builder.addByte(dataLen & 0xFF);
    builder.addByte(code);
    builder.add(data);
    final Uint8List body = builder.toBytes();
    final int crc = HrvCrc16.compute(body);
    final BytesBuilder full = BytesBuilder();
    full.add(body);
    full.addByte(crc & 0xFF);
    full.addByte((crc >> 8) & 0xFF);
    return full.toBytes();
  }

  static Uint8List infoRequest() {
    return build(HrvProtocol.codeInfoRequest, const <int>[]);
  }

  /// Start Message: 0x44('D'). 측정을 시작한다.
  /// previewTime: 10~30초, measureTime: 60초 또는 150초.
  static Uint8List start({
    required int previewTime,
    required int measureTime,
    required int sensorType,
    required int gender,
    required int age,
    required int referenceType,
  }) {
    return build(HrvProtocol.codeStart, <int>[
      previewTime & 0xFF,
      measureTime & 0xFF,
      sensorType & 0xFF,
      gender & 0xFF,
      age & 0xFF,
      referenceType & 0xFF,
    ]);
  }

  /// Stop Message: 0x50('P'). 측정을 중지한다(결과 전송하지 않음).
  static Uint8List stop() {
    return build(HrvProtocol.codeStop, const <int>[]);
  }

  /// Result Request Message: 0x52('R').
  static Uint8List resultRequest(int type) {
    return build(HrvProtocol.codeResultRequest, <int>[type & 0xFF]);
  }
}

class HrvFrameDecoder {
  final List<int> _buffer = <int>[];

  List<HrvFrame> add(List<int> chunk) {
    _buffer.addAll(chunk);
    final List<HrvFrame> frames = <HrvFrame>[];
    while (true) {
      final HrvFrame? frame = _tryExtract();
      if (frame == null) break;
      frames.add(frame);
    }
    return frames;
  }

  void reset() {
    _buffer.clear();
  }

  HrvFrame? _tryExtract() {
    while (_buffer.isNotEmpty && _buffer[0] != HrvProtocol.header) {
      _buffer.removeAt(0);
    }
    if (_buffer.length < 5) return null;

    final int source = _buffer[1];
    if (source != HrvProtocol.sourceSdk &&
        source != HrvProtocol.sourceTerminal) {
      _buffer.removeAt(0);
      return null;
    }

    final int dataLen = (_buffer[2] << 8) | _buffer[3];
    final int totalLen = 4 + dataLen;
    if (dataLen < 3 || dataLen > 8192) {
      _buffer.removeAt(0);
      return null;
    }
    if (_buffer.length < totalLen) return null;

    final Uint8List frame = Uint8List.fromList(_buffer.sublist(0, totalLen));
    if (!HrvCrc16.verify(frame)) {
      _buffer.removeAt(0);
      return null;
    }

    final int code = frame[4];
    final Uint8List data = frame.sublist(5, totalLen - 2);
    _buffer.removeRange(0, totalLen);
    return HrvFrame(source: source, code: code, data: data);
  }
}
