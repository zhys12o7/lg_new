import 'package:webos_service_bridge/webos_service_bridge.dart';
import 'custom_webos_service_bridge.dart';
import 'webos_service_helper.dart';

int subscribe({
  required String uri,
  required String method,
  Map<String, dynamic>? payload,
  required void Function(Map<String, dynamic>) onComplete,
  void Function(Object)? onError,
  void Function()? onDone,
  bool cancelOnError = false,
}) {
  final WebOSServiceData serviceData = WebOSServiceData('$uri/$method',
      payload: payload, optHashCode: defaultHashCode);
  final int hashCode = generateHashCode(serviceData);
  BridgeService? service = ServiceManager.instance.get(hashCode);
  if (service == null) {
    service = BridgeService(
      bridge: useMock
          ? MockWebOSServiceBridge(serviceData)
          : CustomWebOSServiceBridge(serviceData),
      onComplete: onComplete,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    ServiceManager.instance.add(hashCode, service);
    service.subscribe();
  }
  return hashCode;
}

void cancel(int hashCode) {
  ServiceManager.instance.remove(hashCode);
}

void cancelAll() {
  ServiceManager.instance.removeAll();
}

Future<Map<String, dynamic>?> callOneReply({
  required String uri,
  required String method,
  Map<String, dynamic>? payload = const <String, dynamic>{},
}) async {
  final WebOSServiceData serviceData = WebOSServiceData('$uri/$method',
      payload: payload, optHashCode: defaultHashCode);
  return useMock
      ? MockWebOSServiceBridge.callOneReply(serviceData)
      : CustomWebOSServiceBridge.callOneReply(serviceData);
}
