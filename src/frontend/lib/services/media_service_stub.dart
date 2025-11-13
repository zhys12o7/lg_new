import 'dart:async';

import 'package:flutter/foundation.dart';

import 'media_service_interface.dart';

MediaService getMediaService() => const _StubMediaService();

class _StubMediaService extends MediaService {
  const _StubMediaService();

  @override
  Future<String?> open(String uri, {Map<String, dynamic>? options}) async {
    debugPrint('[media] open($uri) (stub)');
    return 'stub-session';
  }

  @override
  Future<void> play(String sessionId) async {
    debugPrint('[media] play($sessionId) (stub)');
  }

  @override
  Future<void> pause(String sessionId) async {
    debugPrint('[media] pause($sessionId) (stub)');
  }

  @override
  Future<void> stop(String sessionId) async {
    debugPrint('[media] stop($sessionId) (stub)');
  }

  @override
  Future<void> close(String sessionId) async {
    debugPrint('[media] close($sessionId) (stub)');
  }
}
