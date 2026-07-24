import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_template/config/device_config.dart';
import 'package:flutter_template/data/model/response/device_page_option_response.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';

class MeasurementMediaPlayer extends StatefulWidget {
  /// DeviceConfig().isG10 의 편의 접근자. 결과 화면에서 직접 참조하지 말고
  /// [DeviceConfig().isG10] 을 사용한다.
  static bool get isG10Device => DeviceConfig().isG10;

  final List<MediaItem> mediaItems;
  final String baseUrl;
  final String playerId;
  final bool isActive;

  const MeasurementMediaPlayer({
    super.key,
    required this.mediaItems,
    required this.baseUrl,
    required this.playerId,
    this.isActive = true,
  });

  @override
  State<MeasurementMediaPlayer> createState() => _MeasurementMediaPlayerState();
}

class _MeasurementMediaPlayerState extends State<MeasurementMediaPlayer>
    with WidgetsBindingObserver {
  // media_kit (non-G10)
  late final Player _player;
  late final VideoController _controller;

  // video_player (G10)
  VideoPlayerController? _vpController;
  VoidCallback? _vpListener;

  bool _isG10 = false;
  bool _pendingPlay = false;

  int _currentIndex = 0;
  bool _isVideoType = false;
  bool _isDisposed = false;
  bool _pausedByParent = false;

  Timer? _playbackTimer;
  StreamSubscription<bool>? _completedSub;

  static const int _defaultImageDurationSeconds = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = Player();
    _controller = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: false,
      ),
    );
    _applyDeviceResult(DeviceConfig().isG10);
  }

  void _applyDeviceResult(bool isG10) {
    if (_isDisposed) return;
    _isG10 = isG10;
    if (_pendingPlay) {
      _pendingPlay = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed && widget.mediaItems.isNotEmpty) {
          _playMedia(0);
        }
      });
    } else if (widget.mediaItems.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) _playMedia(0);
      });
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_isG10) {
        _vpController?.pause();
      } else {
        try { _player.pause(); } catch (_) {}
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isVideoType && !_pausedByParent) {
        if (_isG10) {
          _vpController?.play();
        } else {
          try { _player.play(); } catch (_) {}
        }
      }
    }
  }

  @override
  void didUpdateWidget(MeasurementMediaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive && oldWidget.isActive) {
      _pausedByParent = true;
      if (_isG10) {
        _vpController?.pause();
      } else {
        try { _player.pause(); } catch (_) {}
      }
    } else if (widget.isActive && !oldWidget.isActive && _pausedByParent) {
      _pausedByParent = false;
      if (_isG10) {
        _vpController?.play();
      } else {
        try { _player.play(); } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _playbackTimer?.cancel();
    _completedSub?.cancel();
    _player.dispose();
    _disposeVpController();
    super.dispose();
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

  bool _isLocalFile(String path) {
    if (path.startsWith('file://')) return true;
    if (!path.startsWith('/')) return false;
    return File(path).existsSync();
  }

  bool _isVideo(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.mkv');
  }

  void _playMedia(int index) {
    if (_isDisposed || widget.mediaItems.isEmpty) return;
    if (index >= widget.mediaItems.length) return;

    _playbackTimer?.cancel();
    _playbackTimer = null;
    _completedSub?.cancel();
    _completedSub = null;

    final item = widget.mediaItems[index];
    final isVideo = _isVideo(item.path);

    if (mounted) {
      setState(() {
        _currentIndex = index;
        _isVideoType = isVideo;
      });
    }

    if (isVideo) {
      if (_isG10) {
        _playVideoWithVp(item, index);
      } else {
        _playVideoWithMediaKit(item, index);
      }
    } else {
      try { _player.stop(); } catch (_) {}
      _disposeVpController();
      _scheduleNextForImage(item.playtime, index);
    }
  }

  void _playVideoWithMediaKit(MediaItem item, int index) {
    final isLocal = _isLocalFile(item.path);
    final source = isLocal
        ? 'file://${item.path}'
        : '${widget.baseUrl}${item.path}';
    final volume = item.sound > 0 ? item.sound.toDouble() : 0.0;
    final isSingle = widget.mediaItems.length == 1;
    final loop = item.playtime == 0 && isSingle;

    try {
      _player.setVolume(volume);
      _player.setPlaylistMode(loop ? PlaylistMode.single : PlaylistMode.none);
      _player.open(Media(source));
    } catch (_) {}

    if (!loop) {
      if (item.playtime > 0) {
        _playbackTimer = Timer(Duration(seconds: item.playtime), () {
          if (!_isDisposed && mounted) {
            _playMedia((_currentIndex + 1) % widget.mediaItems.length);
          }
        });
      } else {
        _completedSub = _player.stream.completed.listen((completed) {
          if (completed && !_isDisposed && mounted) {
            _completedSub?.cancel();
            _completedSub = null;
            _playMedia((_currentIndex + 1) % widget.mediaItems.length);
          }
        });
      }
    }
  }

  Future<void> _playVideoWithVp(MediaItem item, int index) async {
    _disposeVpController();

    final isLocal = _isLocalFile(item.path);
    final source = isLocal ? item.path : '${widget.baseUrl}${item.path}';
    final volume = item.sound > 0 ? (item.sound / 100.0).clamp(0.0, 1.0) : 0.0;
    final isSingle = widget.mediaItems.length == 1;
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
          _playbackTimer = Timer(Duration(seconds: item.playtime), () {
            if (!_isDisposed && mounted) {
              _playMedia((_currentIndex + 1) % widget.mediaItems.length);
            }
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
              _playMedia((_currentIndex + 1) % widget.mediaItems.length);
            }
          };
          controller.addListener(_vpListener!);
        }
      }

      await controller.play();
      if (mounted && !_isDisposed) setState(() {});
    } catch (_) {
      controller.dispose();
    }
  }

  void _scheduleNextForImage(int seconds, int index) {
    if (_isDisposed || widget.mediaItems.length <= 1) return;
    final duration = seconds > 0 ? seconds : _defaultImageDurationSeconds;
    _playbackTimer = Timer(Duration(seconds: duration), () {
      if (!_isDisposed && mounted) {
        _playMedia((index + 1) % widget.mediaItems.length);
      }
    });
  }

  Widget _buildLoadingOverlay() {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
      ),
    );
  }

  Widget _buildG10Video(VideoPlayerController controller) {
    return ColoredBox(
      color: Colors.black,
      child: ClipRect(
        child: SizedBox.expand(
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (widget.mediaItems.isEmpty) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Icon(Icons.play_circle_outline, color: Colors.white, size: 64),
        ),
      );
    }

    if (_isVideoType) {
      if (_isG10) {
        if (_vpController != null && _vpController!.value.isInitialized) {
          return _buildG10Video(_vpController!);
        }
        return _buildLoadingOverlay();
      }
      return ColoredBox(
        color: Colors.black,
        child: SizedBox.expand(
          child: Video(
            controller: _controller,
            controls: NoVideoControls,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    final item = widget.mediaItems[_currentIndex];
    final isLocal = _isLocalFile(item.path);

    if (isLocal) {
      return ClipRect(
        child: SizedBox.expand(
          child: Image.file(
            File(item.path),
            fit: isMobile ? BoxFit.fill : BoxFit.cover,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) return child;
              return _buildLoadingOverlay();
            },
          ),
        ),
      );
    }

    final fullUrl = '${widget.baseUrl}${item.path}';
    return ClipRect(
      child: SizedBox.expand(
        child: CachedNetworkImage(
          imageUrl: fullUrl,
          memCacheWidth: 1280,
          memCacheHeight: 800,
          maxWidthDiskCache: 1280,
          maxHeightDiskCache: 800,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (context, url) => _buildLoadingOverlay(),
          errorWidget: (context, url, error) => const ColoredBox(
            color: Colors.black,
            child: Center(
              child: Icon(Icons.error, color: Colors.white, size: 64),
            ),
          ),
          imageBuilder: (context, imageProvider) => Image(
            image: imageProvider,
            fit: isMobile ? BoxFit.fill : BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

