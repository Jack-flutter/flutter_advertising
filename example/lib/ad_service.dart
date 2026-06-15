import 'package:flutter/material.dart';
import 'package:flutter_advertising/advertising_constant.dart';
import 'package:flutter_advertising/advertising_service.dart';
import 'package:flutter_advertising/natives_widget.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AdTestService with AdService {
  /// 单例
  static AdTestService R = AdTestService._getInstance();
  static AdTestService? _r;

  static AdTestService _getInstance() {
    _r ??= AdTestService._();
    return _r!;
  }

  AdTestService._();

  @override
  void adNativesShowNotif(NativesWidget widget) {
    // TODO: implement adNativesShowNotif
    if (navigatorKey.currentContext == null) return;
    showModalBottomSheet(
      context: navigatorKey.currentContext!,
      isDismissible: false,
      isScrollControlled: true,
      enableDrag: false,
      builder: (_) {
        return widget;
      },
    );
  }

  @override
  void adPlayExitNotif() {
    // TODO: implement adPlayExitNotif
  }

  @override
  void adRevenueNotif({
    required String scene,
    required file,
    required double ecpm,
    required String currency,
    required String code,
    required String network,
    required String posId,
    required String format,
    required String client,
  }) {
    // TODO: implement adRevenueNotif
  }

  @override
  bool advertisingEnabled() {
    // TODO: implement advertisingEnabled
    return true;
  }

  @override
  String playingAdLocationKey() {
    // TODO: implement nativeAdLocationKey
    return '-';
  }

  @override
  void reportAdEvent({
    required AdEventType event,
    required String scene,
    String? code,
  }) {
    // TODO: implement reportAdEvent
  }
}
