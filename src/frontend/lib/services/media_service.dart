import 'media_service_interface.dart';
import 'media_service_stub.dart'
    if (dart.library.js) 'media_service_web.dart';

export 'media_service_interface.dart';

MediaService get mediaService => getMediaService();
