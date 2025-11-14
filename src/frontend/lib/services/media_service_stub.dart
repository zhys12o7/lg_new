import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:frontend/webos_service_helper/utils.dart' as webos_utils;

import 'media_service_interface.dart';

MediaService getMediaService() {
  debugPrint('[MediaService] WebOSServiceBridge 사용');
  return const _NativeWebOSMediaService();
}

class _NativeWebOSMediaService extends MediaService {
  const _NativeWebOSMediaService();

  @override
  Future<String?> open(String uri, {Map<String, dynamic>? options}) async {
    try {
      final parameters = <String, dynamic>{
        'uri': uri,
        'type': 'media',
        'mediaFormat': 'video',
        'option': {
          'mediaTransportType': uri.startsWith('http') ? 'STREAMING' : 'FILE',
        },
      };
      if (options != null) {
        parameters.addAll(options);
      }

      debugPrint('[Luna API] 호출: luna://com.webos.media/open');

      final result = await webos_utils.callOneReply(
        uri: 'luna://com.webos.media',
        method: 'open',
        payload: parameters,
      );

      if (result != null && result['returnValue'] == true) {
        final sessionId = result['sessionId'] as String?;
        debugPrint('[Luna API] ✅ 성공 - sessionId: $sessionId');
        return sessionId;
      }

      debugPrint('[Luna API] ❌ 실패 - returnValue: ${result?['returnValue']}');
      return null;
    } catch (e) {
      debugPrint('[Luna API] ❌ 에러: $e');
      return null;
    }
  }

  @override
  Future<void> play(String sessionId) => _invokeSimple('play', sessionId);

  @override
  Future<void> pause(String sessionId) => _invokeSimple('pause', sessionId);

  @override
  Future<void> stop(String sessionId) => _invokeSimple('stop', sessionId);

  @override
  Future<void> close(String sessionId) => _invokeSimple('close', sessionId);

  Future<void> _invokeSimple(String method, String sessionId) async {
    try {
      debugPrint('[Luna API] 호출: luna://com.webos.media/$method');

      final result = await webos_utils.callOneReply(
        uri: 'luna://com.webos.media',
        method: method,
        payload: {'sessionId': sessionId},
      );

      if (result != null && result['returnValue'] == true) {
        debugPrint('[Luna API] ✅ $method 성공');
      } else {
        debugPrint('[Luna API] ❌ $method 실패');
      }
    } catch (e) {
      debugPrint('[Luna API] ❌ $method 에러: $e');
    }
  }
}
