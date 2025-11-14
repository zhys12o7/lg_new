import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:frontend/webos_service_helper/utils.dart' as webos_utils;
import '../data/repository_factory.dart';

/// 통합 시계 서비스
///
/// 역할: 환경에 따라 자동으로 적절한 시간 소스 사용
/// - webOS 환경: Luna Service (SystemService) 사용 (WebOSServiceBridge)
/// - 일반 환경: Dart DateTime 사용
/// - 환경 전환이 쉬운 단일 인터페이스 제공
class ClockService extends ChangeNotifier {
  int? _subscriptionHashCode;

  DateTime _currentTime = DateTime.now();
  String _timezone = 'Unknown';
  int _offset = 0; // 분 단위
  bool _isSubscribed = false;
  Timer? _timer;
  bool _isWebOS = false;

  DateTime get currentTime => _currentTime;
  String get timezone => _timezone;
  int get offset => _offset;
  bool get isWebOS => _isWebOS;

  ClockService() {
    _isWebOS = RepositoryFactory.isWebOS;
  }

  /// 시계 서비스 시작
  ///
  /// webOS 환경이면 Luna Service 구독 시작
  /// 일반 환경이면 Timer로 매초 업데이트
  Future<void> start() async {
    if (_isWebOS) {
      await _startLunaService();
    } else {
      _startTimer();
    }
  }

  /// 시계 서비스 중지
  Future<void> stop() async {
    if (_isWebOS) {
      await _stopLunaService();
    } else {
      _stopTimer();
    }
  }

  /// Luna Service 시작 (webOS 전용)
  ///
  /// luna://com.webos.service.systemservice/time/getSystemTime 호출
  /// subscribe=true로 시간/시간대 변경 이벤트 자동 수신
  Future<void> _startLunaService() async {
    if (_isSubscribed) return;

    try {
      debugPrint('[Luna API] 구독: luna://com.webos.service.systemservice/time/getSystemTime');

      _subscriptionHashCode = webos_utils.subscribe(
        uri: 'luna://com.webos.service.systemservice',
        method: 'time/getSystemTime',
        payload: {'subscribe': true},
        onComplete: (response) {
          _handleTimeResponse(response);
        },
        onError: (error) {
          debugPrint('[Luna API] ❌ 구독 에러: $error');
        },
      );

      _isSubscribed = true;
      debugPrint('[Luna API] ✅ 구독 성공');
    } catch (e) {
      debugPrint('[Luna API] ❌ 에러: $e - Timer로 대체');
      _startTimer();
    }
  }

  /// Luna Service 응답 처리
  void _handleTimeResponse(dynamic response) {
    if (response == null) return;

    try {
      final data = response as Map<dynamic, dynamic>;

      if (data['returnValue'] == true) {
        // UTC 시간 (Epoch seconds)
        final utc = data['utc'] as int?;

        // 로컬 시간 객체
        final localtime = data['localtime'] as Map<dynamic, dynamic>?;

        if (localtime != null) {
          _currentTime = DateTime(
            localtime['year'] as int,
            localtime['month'] as int,
            localtime['day'] as int,
            localtime['hour'] as int,
            localtime['minute'] as int,
            localtime['second'] as int,
          );
        } else if (utc != null) {
          _currentTime = DateTime.fromMillisecondsSinceEpoch(utc * 1000);
        }

        // 시간대 정보
        _timezone = data['timezone'] as String? ?? 'Unknown';
        _offset = data['offset'] as int? ?? 0;

        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Luna API] ❌ 응답 파싱 오류: $e');
    }
  }

  /// Luna Service 구독 중지
  Future<void> _stopLunaService() async {
    if (!_isSubscribed || _subscriptionHashCode == null) return;

    try {
      webos_utils.cancel(_subscriptionHashCode!);
      _isSubscribed = false;
      _subscriptionHashCode = null;
      debugPrint('[Luna API] 구독 중지');
    } catch (e) {
      debugPrint('[Luna API] ❌ 구독 취소 실패: $e');
    }
  }

  /// 일반 Timer 시작 (로컬 환경용)
  void _startTimer() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTime();
    });
  }

  /// 일반 Timer 중지
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// 시간 업데이트 (로컬 환경용)
  void _updateTime() {
    _currentTime = DateTime.now();
    notifyListeners();
  }

  /// 시간 포맷 (예: "14:30:45")
  String getFormattedTime() {
    return '${_currentTime.hour.toString().padLeft(2, '0')}:'
        '${_currentTime.minute.toString().padLeft(2, '0')}:'
        '${_currentTime.second.toString().padLeft(2, '0')}';
  }

  /// 12시간 형식 시간 (예: "02:30 PM")
  String getFormattedTime12Hour() {
    final hour = _currentTime.hour;
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final amPm = hour >= 12 ? 'PM' : 'AM';

    return '${hour12.toString().padLeft(2, '0')}:'
        '${_currentTime.minute.toString().padLeft(2, '0')} $amPm';
  }

  /// 날짜 포맷 (예: "2025년 11월 13일 수요일")
  // String getFormattedDate() {
  //   const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  //   final weekday = weekdays[_currentTime.weekday - 1];

  //   return '${_currentTime.year}년 '
  //       '${_currentTime.month}월 '
  //       '${_currentTime.day}일 '
  //       '$weekday요일';
  // }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
