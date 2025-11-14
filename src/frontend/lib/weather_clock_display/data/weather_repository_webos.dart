import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:frontend/webos_service_helper/utils.dart' as webos_utils;
import 'package:http/http.dart' as http;
import 'weather_model.dart';

/// webOS 환경용 날씨 데이터 저장소
///
/// 역할: webOS Luna Service를 통한 네트워크 상태 확인 후 날씨 API 호출 (WebOSServiceBridge)
/// - Connection Manager로 인터넷 연결 확인
/// - 연결 확인 후 외부 날씨 API 호출 (OpenWeatherMap 등)
/// - 에러 처리 및 재시도 로직
class WeatherRepositoryWebOS {
  int? _connectionSubscriptionHashCode;
  static const String _apiKey = '84001a617861fd360e81ffa35df64b3e';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// 인터넷 연결 상태 확인
  ///
  /// luna://com.webos.service.connectionmanager/getStatus 호출
  /// 반환: 연결 가능 여부 (true/false)
  Future<bool> checkInternetConnection() async {
    try {
      final result = await webos_utils.callOneReply(
        uri: 'luna://com.webos.service.connectionmanager',
        method: 'getStatus',
        payload: {},
      );

      if (result == null) return false;

      final isConnected =
          result['isInternetConnectionAvailable'] as bool? ?? false;

      debugPrint('[Luna API] 연결 상태: $isConnected');
      return isConnected;
    } catch (e) {
      debugPrint('[Luna API] ❌ 에러: $e');
      return true;
    }
  }

  /// 도시 이름으로 현재 날씨 가져오기
  ///
  /// [cityName]: 검색할 도시 이름
  /// 반환: WeatherModel 객체
  /// 에러: 연결 불가 또는 API 호출 실패 시 Exception
  Future<WeatherModel> getCurrentWeather(String cityName) async {
    // 1. 인터넷 연결 확인
    final isConnected = await checkInternetConnection();

    if (!isConnected) {
      throw Exception('인터넷 연결을 사용할 수 없습니다. 네트워크 설정을 확인하세요.');
    }

    // 2. 날씨 API 호출
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric&lang=kr',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return WeatherModel.fromJson(json);
      } else {
        throw Exception('날씨 정보를 가져오는데 실패했습니다. (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('날씨 API 호출 중 오류 발생: $e');
    }
  }

  /// 위도/경도로 현재 날씨 가져오기
  ///
  /// [lat]: 위도
  /// [lon]: 경도
  /// 반환: WeatherModel 객체
  Future<WeatherModel> getCurrentWeatherByCoordinates(
    double lat,
    double lon,
  ) async {
    final isConnected = await checkInternetConnection();

    if (!isConnected) {
      throw Exception('인터넷 연결을 사용할 수 없습니다.');
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=kr',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return WeatherModel.fromJson(json);
      } else {
        throw Exception('날씨 정보를 가져오는데 실패했습니다. (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('날씨 API 호출 중 오류 발생: $e');
    }
  }

  /// 5일 예보 가져오기
  ///
  /// [cityName]: 검색할 도시 이름
  /// 반환: WeatherModel 리스트
  // Future<List<WeatherModel>> getForecast(String cityName) async {
  //   final isConnected = await checkInternetConnection();

  //   if (!isConnected) {
  //     throw Exception('인터넷 연결을 사용할 수 없습니다.');
  //   }

  //   try {
  //     final url = Uri.parse(
  //       '$_baseUrl/forecast?q=$cityName&appid=$_apiKey&units=metric&lang=kr',
  //     );

  //     final response = await http.get(url);

  //     if (response.statusCode == 200) {
  //       final json = jsonDecode(response.body) as Map<String, dynamic>;
  //       final list = json['list'] as List<dynamic>;

  //       return list
  //           .map((item) => WeatherModel.fromJson(item as Map<String, dynamic>))
  //           .toList();
  //     } else {
  //       throw Exception('예보 정보를 가져오는데 실패했습니다. (${response.statusCode})');
  //     }
  //   } catch (e) {
  //     throw Exception('예보 API 호출 중 오류 발생: $e');
  //   }
  // }

  /// 네트워크 상태 변경 감지 (구독)
  ///
  /// webOS Connection Manager의 변경 이벤트를 구독하여
  /// 네트워크 상태 변화를 실시간으로 감지
  Future<void> subscribeToConnectionStatus(
    Function(bool isConnected) onStatusChange,
  ) async {
    try {
      debugPrint('[Luna API] 구독: luna://com.webos.service.connectionmanager/getStatus');

      _connectionSubscriptionHashCode = webos_utils.subscribe(
        uri: 'luna://com.webos.service.connectionmanager',
        method: 'getStatus',
        payload: {'subscribe': true},
        onComplete: (response) {
          final isConnected =
              response['isInternetConnectionAvailable'] as bool? ?? false;
          onStatusChange(isConnected);
        },
        onError: (error) {
          debugPrint('[Luna API] ❌ 구독 에러: $error');
        },
      );
      debugPrint('[Luna API] ✅ 구독 성공');
    } catch (e) {
      debugPrint('[Luna API] ❌ 에러: $e');
    }
  }

  /// 구독 해제
  void unsubscribeFromConnectionStatus() {
    if (_connectionSubscriptionHashCode != null) {
      webos_utils.cancel(_connectionSubscriptionHashCode!);
      _connectionSubscriptionHashCode = null;
      debugPrint('[Luna API] 구독 해제');
    }
  }
}
