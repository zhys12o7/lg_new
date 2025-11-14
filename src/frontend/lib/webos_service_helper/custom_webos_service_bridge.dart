import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:webos_service_bridge/webos_service_bridge.dart';

int generateHashCode(WebOSServiceData serviceData) =>
    '${serviceData.uri}${serviceData.payload}'.hashCode;

// Abstract base class for WebOSServiceBridge
abstract class WebOSServiceBridgeBase {
  Stream<Map<String, dynamic>> subscribe();
  Future<Map<String, dynamic>?> cancel();
}

// Wrapper for the actual WebOSServiceBridge from the plugin
class CustomWebOSServiceBridge implements WebOSServiceBridgeBase {
  // Factory constructor to return the single instance
  factory CustomWebOSServiceBridge(WebOSServiceData serviceData) {
    return CustomWebOSServiceBridge._internal(serviceData);
  }

  CustomWebOSServiceBridge._internal(WebOSServiceData serviceData)
      : _webOSServiceBridge = WebOSServiceBridge(
            serviceData.uri, serviceData.payload as Map<String, dynamic>);

  final WebOSServiceBridge _webOSServiceBridge;

  static Future<Map<String, dynamic>?> callOneReply(WebOSServiceData request) =>
      WebOSServiceBridge.callOneReply(request);

  @override
  Stream<Map<String, dynamic>> subscribe() => _webOSServiceBridge.subscribe();

  @override
  Future<Map<String, dynamic>?> cancel() => _webOSServiceBridge.cancel();
}

class MockWebOSServiceBridge implements WebOSServiceBridgeBase {
  // Private constructor
  factory MockWebOSServiceBridge(WebOSServiceData serviceData) {
    return MockWebOSServiceBridge._internal(serviceData);
  }

  MockWebOSServiceBridge._internal(serviceData)
      : _serviceData = serviceData as WebOSServiceData;

  final WebOSServiceData _serviceData;

  static Future<Map<String, dynamic>> callOneReply(
      WebOSServiceData request) async {
    // Read the mock response from a local file

    final String uriPath = request.uri.replaceFirst('luna://', '');
    String path = 'mocks/$uriPath-${generateHashCode(request)}.json';
    if (!kIsWeb) {
      path = 'assets/$path';
    }
    try {
      if (kIsWeb) {
        // For mobile platforms (Android/iOS)
        final String raw = await rootBundle.loadString(path);
        final Map<String, dynamic> response =
            jsonDecode(raw) as Map<String, dynamic>;
        return response;
      } else {
        // For Linux or other platforms
        if (File(path).existsSync()) {
          final String raw = File(path).readAsStringSync();
          final Map<String, dynamic> response =
              jsonDecode(raw) as Map<String, dynamic>;
          return response;
        } else {
          throw Exception('[linux]Mock response file not found : $path');
        }
      }
    } catch (e) {
      throw Exception('Mock response file not found : $path');
    }
  }

  @override
  Stream<Map<String, dynamic>> subscribe() async* {
    // Read the mock response from a local file
    final String uriPath = _serviceData.uri.replaceFirst('luna://', '');
    String path = 'mocks/$uriPath-${generateHashCode(_serviceData)}.json';
    if (!kIsWeb) {
      path = 'assets/$path';
    }
    try {
      if (kIsWeb) {
        // For mobile platforms (Android/iOS)
        final String raw = await rootBundle.loadString(path);
        final Map<String, dynamic> response =
            jsonDecode(raw) as Map<String, dynamic>;
        yield response;
      } else {
        // For Linux or other platforms
        if (File(path).existsSync()) {
          final String raw = File(path).readAsStringSync();
          final Map<String, dynamic> response =
              jsonDecode(raw) as Map<String, dynamic>;
          yield response;
        } else {
          throw Exception('[linux]Mock response file not found : $path');
        }
      }
    } catch (e) {
      throw Exception('[all]Mock response file not found : $path');
    }
  }

  @override
  Future<Map<String, dynamic>?> cancel() async {
    // Mock cancel response
    return <String, dynamic>{
      'status': 'cancelled',
      'callId': _serviceData.hashCode
    };
  }
}
