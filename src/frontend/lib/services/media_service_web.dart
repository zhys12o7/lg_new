import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

import 'package:flutter/foundation.dart';

import 'media_service_interface.dart';

MediaService getMediaService() {
  debugPrint('[media] Using WebOS MediaService');
  return const _WebOSMediaService();
}

class _WebOSMediaService extends MediaService {
  const _WebOSMediaService();

  @override
  Future<String?> open(String uri, {Map<String, dynamic>? options}) {
    final timestamp = DateTime.now().toString();
    debugPrint('[media] [$timestamp] open() called');
    debugPrint('[media] [$timestamp] uri: $uri');

    if (!_hasWebOS) {
      debugPrint('[media] [$timestamp] ERROR: webOS object not available');
      return Future.value(null);
    }

    debugPrint('[media] [$timestamp] webOS object detected');
    final completer = Completer<String?>();
    final service = js_util.getProperty(_webOS!, 'service');
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

    debugPrint('[media] [$timestamp] Calling luna://com.webos.media with parameters: $parameters');

    js_util.callMethod(service, 'request', [
      'luna://com.webos.media',
      js_util.jsify({
        'method': 'open',
        'parameters': parameters,
        'onSuccess': js.allowInterop((dynamic res) {
          final successTimestamp = DateTime.now().toString();
          debugPrint('[media] [$successTimestamp] open SUCCESS');
          final sessionId = js_util.getProperty(res, 'sessionId');
          debugPrint('[media] [$successTimestamp] sessionId: $sessionId');
          completer.complete(sessionId is String ? sessionId : null);
        }),
        'onFailure': js.allowInterop((dynamic error) {
          final failureTimestamp = DateTime.now().toString();
          final code = js_util.hasProperty(error, 'errorCode')
              ? js_util.getProperty(error, 'errorCode')
              : 'unknown';
          final text = js_util.hasProperty(error, 'errorText')
              ? js_util.getProperty(error, 'errorText')
              : 'unknown';
          debugPrint('[media] [$failureTimestamp] open FAILED: [$code] $text');
          debugPrint('[media] [$failureTimestamp] error object: $error');
          completer.complete(null);
        }),
      })
    ]);

    return completer.future;
  }

  @override
  Future<void> play(String sessionId) => _invokeSimple('play', sessionId);

  @override
  Future<void> pause(String sessionId) => _invokeSimple('pause', sessionId);

  @override
  Future<void> stop(String sessionId) => _invokeSimple('stop', sessionId);

  @override
  Future<void> close(String sessionId) => _invokeSimple('close', sessionId);

  Future<void> _invokeSimple(String method, String sessionId) {
    final timestamp = DateTime.now().toString();
    debugPrint('[media] [$timestamp] $method() called with sessionId: $sessionId');

    if (!_hasWebOS) {
      debugPrint('[media] [$timestamp] $method skipped, webOS unavailable');
      return Future.value();
    }

    final service = js_util.getProperty(_webOS!, 'service');
    js_util.callMethod(service, 'request', [
      'luna://com.webos.media',
      js_util.jsify({
        'method': method,
        'parameters': {'sessionId': sessionId},
        'onSuccess': js.allowInterop((dynamic res) {
          final successTimestamp = DateTime.now().toString();
          debugPrint('[media] [$successTimestamp] $method SUCCESS');
        }),
        'onFailure': js.allowInterop((dynamic error) {
          final failureTimestamp = DateTime.now().toString();
          final code = js_util.hasProperty(error, 'errorCode')
              ? js_util.getProperty(error, 'errorCode')
              : 'unknown';
          final text = js_util.hasProperty(error, 'errorText')
              ? js_util.getProperty(error, 'errorText')
              : 'unknown';
          debugPrint('[media] [$failureTimestamp] $method FAILED: [$code] $text');
        }),
      })
    ]);

    return Future.value();
  }
}

Object? get _webOS => js.context.hasProperty('webOS') ? js.context['webOS'] : null;

bool get _hasWebOS => _webOS != null;
