import 'dart:async';
import 'dart:io';
import 'package:video_player/video_player.dart';

class VideoPlayerManager {
  static final VideoPlayerManager _instance = VideoPlayerManager._internal();
  factory VideoPlayerManager() => _instance;
  VideoPlayerManager._internal();

  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, String> _urls = {};
  bool _isReleasingAll = false;

  Future<VideoPlayerController?> getController({
    required String id,
    required String url,
    bool isLocalFile = false,
    required double volume,
    required bool loop,
  }) async {
    if (_isReleasingAll) {
      int retryCount = 0;
      while (_isReleasingAll && retryCount < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        retryCount++;
      }
      if (_isReleasingAll) {
        _isReleasingAll = false;
      }
    }

    if (_urls[id] == url && _controllers[id] != null) {
      try {
        final controller = _controllers[id]!;
        if (controller.value.isInitialized) {
          controller.setVolume(volume);
          controller.setLooping(loop);
          return controller;
        }
      } catch (e) {
        _controllers.remove(id);
        _urls.remove(id);
      }
    }

    await releaseController(id);
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final VideoPlayerController controller;
      
      if (isLocalFile) {
        controller = VideoPlayerController.file(File(url));
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      }
      
      await controller.initialize();

      _controllers[id] = controller;
      _urls[id] = url;

      controller.setVolume(volume);
      controller.setLooping(loop);

      return controller;
    } catch (e) {
      return null;
    }
  }

  Future<void> releaseController(String id) async {
    final controller = _controllers.remove(id);
    _urls.remove(id);

    if (controller != null) {
      try {
        await controller.pause();
      } catch (_) {}

      try {
        controller.dispose();
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> releaseAllControllers() async {
    if (_controllers.isEmpty) {
      _isReleasingAll = false;
      return;
    }

    _isReleasingAll = true;

    try {
      final ids = _controllers.keys.toList();
      for (final id in ids) {
        await releaseController(id);
      }

      _controllers.clear();
      _urls.clear();

      await Future.delayed(const Duration(milliseconds: 200));
    } finally {
      _isReleasingAll = false;
    }
  }

  Future<void> pauseAll() async {
    for (final controller in _controllers.values) {
      try {
        await controller.pause();
      } catch (_) {}
    }
  }

  Future<void> releaseControllersWithPrefix(String prefix) async {
    final idsToRelease =
        _controllers.keys.where((id) => id.startsWith(prefix)).toList();
    for (final id in idsToRelease) {
      await releaseController(id);
    }
  }

  Future<void> pauseControllersWithPrefix(String prefix) async {
    final entries = _controllers.entries
        .where((e) => e.key.startsWith(prefix))
        .toList();
    for (final entry in entries) {
      try {
        await entry.value.pause();
      } catch (_) {}
    }
  }

  Future<void> playControllersWithPrefix(String prefix) async {
    final entries = _controllers.entries
        .where((e) => e.key.startsWith(prefix))
        .toList();
    for (final entry in entries) {
      try {
        await entry.value.play();
      } catch (_) {}
    }
  }

  Future<void> playAll() async {
    for (final controller in _controllers.values) {
      try {
        await controller.play();
      } catch (_) {}
    }
  }

  bool hasController(String id) => _controllers.containsKey(id);

  VideoPlayerController? getExistingController(String id) => _controllers[id];
}
