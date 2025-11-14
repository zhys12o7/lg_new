// ⚠️ webOS 배포 전용 파일
// 현재 개발 환경에서는 사용되지 않음
// webOS .ipk 빌드 시 ClockController를 이 파일로 교체하여 사용

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:frontend/webos_service_helper/utils.dart' as webos_utils;

/// webOS Luna Service 기반 시계 컨트롤러
///
/// 역할: webOS의 System Service를 사용하여 시스템 시간을 가져옴 (WebOSServiceBridge)
/// - luna://com.webos.service.systemservice/time/getSystemTime 사용
/// - 시간대 변경 시 자동 업데이트
/// - UTC 및 로컬 시간 모두 지원
///
/// 사용 방법:
/// 1. webOS 배포 시 clock_widget.dart에서 import 변경
/// 2. ClockController 대신 ClockControllerWebOS 사용
class ClockControllerWebOS extends ChangeNotifier {
  int? _subscriptionHashCode;

  DateTime _currentTime = DateTime.now();
  String _timezone = 'Unknown';
  int _offset = 0; // 분 단위
  bool _isSubscribed = false;

  DateTime get currentTime => _currentTime;
  String get timezone => _timezone;
  int get offset => _offset;

  /// Luna Service 구독 시작
  ///
  /// subscribe=true로 System Service를 호출하여
  /// 시간/시간대 변경 이벤트를 자동으로 수신
  Future<void> startLunaService() async {
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
      _fallbackToTimer();
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

  /// Luna Service 실패 시 일반 Timer로 대체
  void _fallbackToTimer() {
    Timer.periodic(const Duration(seconds: 1), (_) {
      _currentTime = DateTime.now();
      notifyListeners();
    });
  }

  /// 구독 중지
  Future<void> stopLunaService() async {
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

  /// 시간 포맷 (예: "14:30:45")
  String getFormattedTime() {
    return '${_currentTime.hour.toString().padLeft(2, '0')}:'
        '${_currentTime.minute.toString().padLeft(2, '0')}:'
        '${_currentTime.second.toString().padLeft(2, '0')}';
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
    stopLunaService();
    super.dispose();
  }
}
