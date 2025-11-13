abstract class MediaService {
  const MediaService();

  Future<String?> open(String uri, {Map<String, dynamic>? options});

  Future<void> play(String sessionId);

  Future<void> pause(String sessionId);

  Future<void> stop(String sessionId);

  Future<void> close(String sessionId);
}
