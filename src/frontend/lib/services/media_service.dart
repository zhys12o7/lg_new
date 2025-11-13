import 'media_service_interface.dart';
import 'media_service_web.dart'
    if (dart.library.io) 'media_service_stub.dart';

export 'media_service_interface.dart';

MediaService get mediaService => getMediaService();
