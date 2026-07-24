import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_template/config/device_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/config/config.dart';
import 'package:flutter_template/data/model/response/wait_page_option_response.dart';
import 'package:flutter_template/providers/notifier/wait_content_notifier.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';
import 'package:device_info_plus/device_info_plus.dart';

class WaitContentArea extends ConsumerStatefulWidget {
  final VoidCallback? onTap;

  /// 화면이 활성(대기화면이 최상위)인지 여부. false가 되면 영상/오디오를 일시정지하고,
  /// true로 복귀하면 영상 타입일 때만 재개한다. null이면 항상 활성으로 간주한다.
  final ValueNotifier<bool>? isActiveNotifier;

  const WaitContentArea({
    super.key,
    this.onTap,
    this.isActiveNotifier,
  });

  @override
  ConsumerState<WaitContentArea> createState() => _WaitContentAreaState();
}

class _WaitContentAreaState extends ConsumerState<WaitContentArea>
    with WidgetsBindingObserver {
  // media_kit (non-G10)
  Player? _player;
  VideoController? _controller;

  // video_player (G10)
  VideoPlayerController? _vpController;
  VoidCallback? _vpListener;

  bool _isG10 = false;
  bool _isDeviceDetected = false;
  List<WaitPageContent>? _pendingContents;

  int _currentIndex = 0;
  List<WaitPageContent> _previousContents = [];
  Timer? _contentTimer;
  bool _isDisposed = false;
  bool _isVideoType = false;

  StreamSubscription<bool>? _completedSub;

  static const int _defaultImageDurationSeconds = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.isActiveNotifier?.addListener(_onActiveChanged);
    _applyDeviceResult(DeviceConfig().isG10);
  }

  void _applyDeviceResult(bool isG10) async {
    if (_isDisposed) return;
    bool isEmulator = false;
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        isEmulator = !androidInfo.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        isEmulator = !iosInfo.isPhysicalDevice;
      }
    } catch (_) {}

    _isG10 = isG10 || isEmulator;

    if (!_isG10 && _player == null) {
      _player = Player();
      _controller = VideoController(
        _player!,
        configuration: const VideoControllerConfiguration(
          enableHardwareAcceleration: false,
        ),
      );
    }

    _isDeviceDetected = true;
    if (mounted) setState(() {});
    if (_pendingContents != null) {
      final pending = _pendingContents!;
      _pendingContents = null;
      _playContent(pending, 0);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_isG10) {
        _vpController?.pause();
      } else {
        try { _player?.pause(); } catch (_) {}
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isVideoType) {
        if (_isG10) {
          _vpController?.play();
        } else {
          try { _player?.play(); } catch (_) {}
        }
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.isActiveNotifier?.removeListener(_onActiveChanged);
    WidgetsBinding.instance.removeObserver(this);
    _contentTimer?.cancel();
    _completedSub?.cancel();
    _player?.dispose();
    _disposeVpController();
    super.dispose();
  }

  void _onActiveChanged() {
    final isActive = widget.isActiveNotifier?.value ?? true;
    if (isActive) {
      if (_isVideoType) {
        if (_isG10) {
          _vpController?.play();
        } else {
          try { _player?.play(); } catch (_) {}
        }
      }
    } else {
      if (_isG10) {
        _vpController?.pause();
      } else {
        try { _player?.pause(); } catch (_) {}
      }
    }
  }

  void _disposeVpController() {
    if (_vpController != null) {
      if (_vpListener != null) {
        _vpController!.removeListener(_vpListener!);
        _vpListener = null;
      }
      _vpController!.dispose();
      _vpController = null;
    }
  }

  bool _isVideoFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }

  bool _isLocalFile(String path) {
    if (path.startsWith('file://')) return true;
    if (!path.startsWith('/')) return false;
    return File(path).existsSync();
  }

  void _playContent(List<WaitPageContent> contents, int index) {
    if (_isDisposed || contents.isEmpty || index >= contents.length) return;

    _contentTimer?.cancel();
    _contentTimer = null;
    _completedSub?.cancel();
    _completedSub = null;

    final item = contents[index];
    final isVideo = _isVideoFile(item.path);

    if (mounted) {
      setState(() {
        _currentIndex = index;
        _isVideoType = isVideo;
      });
    }

    if (isVideo) {
      if (_isG10) {
        _playVideoWithVp(contents, index, item);
      } else {
        _playVideoWithMediaKit(contents, index, item);
      }
    } else {
      try { _player?.stop(); } catch (_) {}
      _disposeVpController();
      _scheduleNextForImage(item.playtime, contents);
    }
  }

  void _playVideoWithMediaKit(
    List<WaitPageContent> contents,
    int index,
    WaitPageContent item,
  ) {
    final isLocal = _isLocalFile(item.path);
    final source = isLocal ? item.path : '${Config.baseUrl}${item.path}';
    final volume = item.sound > 0 ? item.sound.toDouble() : 0.0;
    final isSingle = contents.length == 1;
    final loop = item.playtime == 0 && isSingle;

    try {
      _player?.setVolume(volume);
      _player?.setPlaylistMode(
        loop ? PlaylistMode.single : PlaylistMode.none,
      );
      _player?.open(
        Media(isLocal ? 'file://$source' : source),
      );
    } catch (_) {}

    if (!loop) {
      if (item.playtime > 0) {
        _contentTimer = Timer(Duration(seconds: item.playtime), () {
          if (!_isDisposed && mounted) _moveToNext(contents);
        });
      } else {
        _completedSub = _player?.stream.completed.listen((completed) {
          if (completed && !_isDisposed && mounted) {
            _completedSub?.cancel();
            _completedSub = null;
            _moveToNext(contents);
          }
        });
      }
    }
  }

  Future<void> _playVideoWithVp(
    List<WaitPageContent> contents,
    int index,
    WaitPageContent item,
  ) async {
    _disposeVpController();

    final isLocal = _isLocalFile(item.path);
    final source = isLocal ? item.path : '${Config.baseUrl}${item.path}';
    final volume = item.sound > 0 ? (item.sound / 100.0).clamp(0.0, 1.0) : 0.0;
    final isSingle = contents.length == 1;
    final loop = item.playtime == 0 && isSingle;

    final VideoPlayerController controller;
    if (isLocal) {
      controller = VideoPlayerController.file(File(source));
    } else {
      controller = VideoPlayerController.networkUrl(Uri.parse(source));
    }

    try {
      await controller.initialize();
      if (_isDisposed || !mounted) {
        controller.dispose();
        return;
      }

      await controller.setVolume(volume);
      await controller.setLooping(loop);

      _vpController = controller;

      if (!loop) {
        if (item.playtime > 0) {
          _contentTimer = Timer(Duration(seconds: item.playtime), () {
            if (!_isDisposed && mounted) _moveToNext(contents);
          });
        } else {
          _vpListener = () {
            if (_isDisposed || !mounted) return;
            final value = controller.value;
            if (value.isInitialized &&
                !value.isPlaying &&
                value.position >= value.duration &&
                value.duration > Duration.zero) {
              if (_vpListener != null) {
                controller.removeListener(_vpListener!);
                _vpListener = null;
              }
              _moveToNext(contents);
            }
          };
          controller.addListener(_vpListener!);
        }
      }

      await controller.play();
      if (mounted && !_isDisposed) setState(() {});
    } catch (e, stack) {
      print('VideoPlayer init failed: $e');
      print(stack);
      controller.dispose();
    }
  }

  void _scheduleNextForImage(int seconds, List<WaitPageContent> contents) {
    if (_isDisposed || contents.length <= 1) return;
    final duration = seconds > 0 ? seconds : _defaultImageDurationSeconds;
    _contentTimer = Timer(Duration(seconds: duration), () {
      if (!_isDisposed && mounted) _moveToNext(contents);
    });
  }

  void _moveToNext(List<WaitPageContent> contents) {
    if (_isDisposed || contents.isEmpty) return;
    final next = (_currentIndex + 1) % contents.length;
    _playContent(contents, next);
  }

  @override
  Widget build(BuildContext context) {
    final contents = ref.watch(waitContentProvider);

    if (contents.isEmpty) {
      return _buildPlaceholder();
    }

    if (_previousContents != contents) {
      _previousContents = contents;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed || !mounted) return;
        if (!_isDeviceDetected) {
          _pendingContents = contents;
          return;
        }
        _playContent(contents, 0);
      });
    }

    if (_currentIndex >= contents.length) return _buildPlaceholder();

    final currentContent = contents[_currentIndex];

    if (_isVideoType) {
      if (_isG10 && _vpController != null && _vpController!.value.isInitialized) {
        final vpCtrl = _vpController!;
        final size = vpCtrl.value.size;
        final hasValidSize = size.width > 0 && size.height > 0;
        final videoWidth = hasValidSize ? size.width : 1920.0;
        final videoHeight = hasValidSize ? size.height : 1080.0;

        return GestureDetector(
          onTap: widget.onTap,
          child: ColoredBox(
            color: Colors.black,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final containerWidth = constraints.maxWidth;
                final containerHeight = constraints.maxHeight;
                if (containerWidth <= 0 || containerHeight <= 0) {
                  return const SizedBox.shrink();
                }

                final containerAspect = containerWidth / containerHeight;
                final videoAspect = videoWidth / videoHeight;
                final ratioDiff =
                    (videoAspect - containerAspect).abs() / containerAspect;
                final useCover = ratioDiff < 0.05;
                final fit = useCover ? BoxFit.cover : BoxFit.contain;
                final overScale = useCover ? 1.03 : 1.0;

                return SizedBox.expand(
                  child: ClipRect(
                    child: FittedBox(
                      fit: fit,
                      alignment: Alignment.center,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: videoWidth,
                        height: videoHeight,
                        child: Transform.scale(
                          scale: overScale,
                          alignment: Alignment.center,
                          child: VideoPlayer(vpCtrl),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
      if (!_isG10) {
        return GestureDetector(
          onTap: widget.onTap,
          child: SizedBox.expand(
            child: Video(
              controller: _controller!,
              controls: NoVideoControls,
              fit: BoxFit.contain,
            ),
          ),
        );
      }
      return _buildPlaceholder();
    }

    return _buildImageContent(currentContent);
  }

  Widget _buildImageContent(WaitPageContent content) {
    final isLocal = _isLocalFile(content.path);

    if (isLocal) {
      return _SmartFitImage(
        provider: FileImage(File(content.path)),
        onTap: widget.onTap,
      );
    }

    return _SmartFitNetworkImage(
      imageUrl: '${Config.baseUrl}${content.path}',
      onTap: widget.onTap,
    );
  }

  Widget _buildPlaceholder() {
    return GestureDetector(
      onTap: widget.onTap,
      child: const ColoredBox(
        color: Colors.transparent,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

// 이미지 비율과 컨테이너 비율 차이가 5% 미만이면 cover, 이상이면 contain을 자동 선택.
// 세로형(portrait) 키오스크 이미지는 여백 없이 꽉 채우고,
// 가로형(landscape) 이미지는 원본 비율을 유지한다.
class _SmartFitImage extends StatefulWidget {
  final ImageProvider provider;
  final VoidCallback? onTap;

  const _SmartFitImage({
    required this.provider,
    this.onTap,
  });

  @override
  State<_SmartFitImage> createState() => _SmartFitImageState();
}

class _SmartFitImageState extends State<_SmartFitImage> {
  Size? _naturalSize;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _resolveSize(widget.provider);
  }

  @override
  void didUpdateWidget(_SmartFitImage old) {
    super.didUpdateWidget(old);
    if (old.provider != widget.provider) {
      _detachListener();
      setState(() => _naturalSize = null);
      _resolveSize(widget.provider);
    }
  }

  void _resolveSize(ImageProvider provider) {
    _detachListener();
    _stream = provider.resolve(ImageConfiguration.empty);
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() => _naturalSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            ));
      },
      onError: (_, __) {},
    );
    _stream!.addListener(_listener!);
  }

  void _detachListener() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detachListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final fit = _chooseFit(
        _naturalSize,
        Size(constraints.maxWidth, constraints.maxHeight),
      );
      return GestureDetector(
        onTap: widget.onTap,
        child: SizedBox.expand(
          child: FittedBox(
            fit: fit,
            alignment: Alignment.center,
            child: Image(image: widget.provider, fit: fit),
          ),
        ),
      );
    });
  }
}

class _SmartFitNetworkImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback? onTap;

  const _SmartFitNetworkImage({
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox.expand(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          memCacheWidth: 1080,
          memCacheHeight: 1440,
          maxWidthDiskCache: 1080,
          maxHeightDiskCache: 1440,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          errorWidget: (_, __, ___) => const ColoredBox(
            color: Colors.transparent,
            child: Center(child: CircularProgressIndicator()),
          ),
          placeholder: (_, __) => const ColoredBox(
            color: Colors.transparent,
            child: Center(child: CircularProgressIndicator()),
          ),
          imageBuilder: (context, imageProvider) {
            // _SmartFitImage(StatefulWidget)에 위임해 ImageStreamListener를 안전하게 관리한다.
            return _SmartFitImage(provider: imageProvider, onTap: onTap);
          },
        ),
      ),
    );
  }
}

/// 컨테이너와 이미지의 가로세로 비율 차이가 5% 미만이면 BoxFit.cover,
/// 그 이상이면 BoxFit.contain을 반환한다.
BoxFit _chooseFit(Size? naturalSize, Size containerSize) {
  if (naturalSize == null || containerSize.isEmpty) return BoxFit.contain;
  final imageAspect = naturalSize.width / naturalSize.height;
  final containerAspect = containerSize.width / containerSize.height;
  final ratioDiff = (imageAspect - containerAspect).abs() / containerAspect;
  return ratioDiff < 0.05 ? BoxFit.cover : BoxFit.contain;
}
