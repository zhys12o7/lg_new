import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

import 'package:flutter/foundation.dart';

import 'media_service_interface.dart';

MediaService getMediaService() => const _WebOSMediaService();

class _WebOSMediaService extends MediaService {
  const _WebOSMediaService();

  @override
  Future<String?> open(String uri, {Map<String, dynamic>? options}) {
    if (!_hasWebOS) {
      debugPrint('[media] webOS object not available');
      return Future.value(null);
    }

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

    js_util.callMethod(service, 'request', [
      'luna://com.webos.media',
      js_util.jsify({
        'method': 'open',
        'parameters': parameters,
        'onSuccess': js.allowInterop((dynamic res) {
          final sessionId = js_util.getProperty(res, 'sessionId');
          completer.complete(sessionId is String ? sessionId : null);
        }),
        'onFailure': js.allowInterop((dynamic error) {
          final code = js_util.hasProperty(error, 'errorCode')
              ? js_util.getProperty(error, 'errorCode')
              : 'unknown';
          final text = js_util.hasProperty(error, 'errorText')
              ? js_util.getProperty(error, 'errorText')
              : 'unknown';
          debugPrint('[media] open failed: [$code] $text');
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
    if (!_hasWebOS) {
      debugPrint('[media] $method skipped, webOS unavailable');
      return Future.value();
    }

    final service = js_util.getProperty(_webOS!, 'service');
    js_util.callMethod(service, 'request', [
      'luna://com.webos.media',
      js_util.jsify({
        'method': method,
        'parameters': {'sessionId': sessionId},
        'onFailure': js.allowInterop((dynamic error) {
          final code = js_util.hasProperty(error, 'errorCode')
              ? js_util.getProperty(error, 'errorCode')
              : 'unknown';
          final text = js_util.hasProperty(error, 'errorText')
              ? js_util.getProperty(error, 'errorText')
              : 'unknown';
          debugPrint('[media] $method failed: [$code] $text');
        }),
      })
    ]);

    return Future.value();
  }
}

Object? get _webOS => js.context.hasProperty('webOS') ? js.context['webOS'] : null;

bool get _hasWebOS => _webOS != null;
