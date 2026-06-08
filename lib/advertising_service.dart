import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'advertising_constant.dart';
import 'advertising_data.dart';
import 'natives_widget.dart';
import 'sdk_lovin.dart';
import 'sdk_mobile.dart';

mixin AdService {
  late final SdkMobile mobileSdk; //mod广告
  late final SdkLovin lovinSdk; //max广告
  late AdConfig adConfig; //广告配置
  final Map<String, int> _timeData = {}; // 广告显示时间记录
  final Map<String, AdCacheState> _cacheData = {}; //广告缓存记录{广告id:广告数据}
  int _playCount = 0; //广告显示次数
  bool _showAd = false; //广告是否显示
  String? showNativeId; //多原生广告ID
  String _playScene = ''; //广告播放场景
  String _playLocation = ''; //广告播放位置
  AdCacheState? _adData; //当前显示广告的数据记录
  dynamic _fileData; // 播放的视频数据
  Function()? _adExitCall; //广告关闭回调

  ValueNotifier<bool> adClickNotifier = ValueNotifier(false); //原生广告点击

  bool get adShow => _showAd; //是否显示广告

  /// 广告是否开启
  bool advertisingEnabled();

  /// 原生广告位置key
  String nativeAdLocationKey();

  /// 原生广告显示通知
  void adNativesShowNotif(NativesWidget widget);

  /// 单个广告缓存成功通知
  void singAdCacheSucceedNotif(AdCacheState data, AdSdkPlatform type);

  /// 发送埋点事件
  void reportAdEvent({
    required AdEventType event,
    required String scene,
    String? code,
  });

  /// 广告收益通知
  void adRevenueNotif({
    required String scene,
    required dynamic file,
    required double ecpm,
    required String currency,
    required String code,
    required String network,
    required String posId,
    required String format,
    required String client,
  });

  /// 广告播放关闭通知
  void adPlayExitNotif();

  /// 初始化
  Future initAppAdSdk({required String lovinKey}) async {
    final callData = AdCallback(
      cacheSucceed: _adLoadSucceed,
      cacheFailed: _adLoadFailed,
      showFailed: _adPlayFailedCall,
      adOntap: _adWidgetOnTap,
      adClose: _adPalyExitCall,
      revenue: _adPlaySuccess,
    );
    mobileSdk = SdkMobile(callback: callData, service: this);
    lovinSdk = SdkLovin(callback: callData, service: this);
    await Future.wait([mobileSdk.initialize(), lovinSdk.initialize(lovinKey)]);
  }

  /// 更新配置
  AdConfig updateAdConfig({required String json}) {
    try {
      adConfig = AdConfig.fromJson(jsonDecode(json));
    } catch (e) {
      adConfig = AdConfig.fromJson({});
    }
    return adConfig;
  }

  /// 开启广告缓存
  void startCacheAd({required String scene}) {
    debugPrint('广告开始缓存');
    _playScene = scene;
    for (final key in adConfig.adData.keys) {
      _cacheLocationAd(index: 0, location: key, scene: scene);
    }
  }

  /// 显示广告
  bool popAd({
    required String scene,
    required String location,
    dynamic videoData,
    int playCount = 1,
    Function()? exitCall,
  }) {
    // 是否可显示广告
    if (_showAd == true && advertisingEnabled() == false) {
      if (exitCall != null) exitCall();
      return false;
    }
    // 是否有广告
    if (_obtionAdData(location).isEmpty) {
      if (exitCall != null) exitCall();
      return false;
    }
    // 是否有效期
    if (_adValidPlayInterTime(scene, playCount) == false) {
      if (exitCall != null) exitCall();
      return false;
    }
    _adData = null;
    _fileData = videoData;
    _playScene = scene;
    _playLocation = location;
    _adExitCall = exitCall;
    _playCount = playCount;
    reportAdEvent(event: AdEventType.needShow, scene: scene);
    // 找出缓存的广告
    bool isCache = false;
    for (final item in _cacheData.values) {
      if (item.locations.contains(location)) {
        _adData = item;
        isCache = item.isCache;
        break;
      }
    }
    // 按类型显示广告
    if (_adData?.data.platform == AdSdkPlatform.admob.value &&
        isCache == true) {
      _showAd = mobileSdk.showMobileAd(_adData!);
    } else if (_adData?.data.platform == AdSdkPlatform.lovin.value &&
        isCache == true) {
      _showAd = lovinSdk.showLovinAd(_adData!);
    }
    if (_showAd == false) {
      reportAdEvent(
        event: AdEventType.showFail,
        scene: scene,
        code: "No padding",
      );
      // 没找到对应的平台或者没有广告-重新走缓存流程
      _cacheLocationAd(index: 0, location: location, scene: scene);
      // 看看第二套广告有缓存没
      _showSecond(scene: scene, data: _adData);
    } else {
      // 广告完成通知
      if (_showAd == false && _adExitCall != null) _adExitCall!();
    }
    return _showAd;
  }

  /// 补偿广告
  void _showSecond({required String scene, required AdCacheState? data}) {
    final location = data?.data.secondsType ?? '';
    if (location.isEmpty || _playCount == 2) {
      // 广告完成通知
      _showAd = false;
      if (_adExitCall != null) _adExitCall!();
      return;
    }
    popAd(
      playCount: 2,
      scene: scene,
      videoData: _fileData,
      location: location,
      exitCall: _adExitCall,
    );
  }

  /// 显示原生广告
  void showNativeAd(AdCacheState data) {
    Set<dynamic> adList = {data.ad};
    // 添加第二套原生广告
    for (final item in _cacheData.values) {
      if (item.data.nativeId == _playLocation && item.isCache == true) {
        showNativeId = item.data.unitId;
        adList.add(item.ad);
      }
    }
    int time = 0;
    double open = 0.0;
    if (_playLocation == nativeAdLocationKey()) {
      open = adConfig.playPush;
    } else {
      if (adList.length == 2) {
        time = adConfig.nativeShowTimeTwo;
        open = adConfig.nativePushTwo;
      } else {
        time = adConfig.nativeShowTime;
        open = adConfig.nativePush;
      }
    }
    final view = NativesWidget(
      service: this,
      time: time,
      rate: open,
      childs: adList.toList(),
    );
    adNativesShowNotif(view);
  }

  /// 原生mob广告主动关闭
  void closeNativeMobAdPlay(List<dynamic> ads) {
    for (Ad ad in ads) {
      final AdCacheState? adData = _cacheData[ad.adUnitId];
      final isRep = adData?.locations.isNotEmpty ?? false;
      if (isRep == false) _cacheData.remove(adData?.data.unitId);
      mobileSdk.nativeMobAdPlayClose(ad: ad, isRep: isRep);
    }
  }

  /// 广告位置缓存
  void _cacheLocationAd({
    required int index,
    required String location,
    required String scene,
  }) {
    final amList = _obtionAdData(location);
    if ((index + 1) > amList.length || index < 0) return;
    final item = amList[index];
    if (item.unitId.isEmpty) {
      _cacheLocationAd(index: index + 1, location: location, scene: scene);
      return;
    }
    // max广告同一个位置只能缓存一个
    for (final ads in _cacheData.values) {
      if (ads.data.platform == AdSdkPlatform.lovin.value &&
          item.unitId == ads.data.unitId) {
        ads.locations.add(location);
        _cacheLocationAd(index: index + 1, location: location, scene: scene);
        return;
      }
    }
    List<AdCacheState> adList = [];
    if (_cacheData.keys.contains(item.unitId)) {
      // 正在缓存当前广告说明这个广告是多个位置共有
      final AdCacheState data = _cacheData[item.unitId]!;
      data.locations.add(location);
      _cacheData[item.unitId] = data;
    } else {
      // 没有缓存广告，新加缓存
      final adData = AdCacheState(data: item, scene: scene);
      adData.locations.add(location);
      adList.add(adData);
    }
    if (item.nativeId.isNotEmpty &&
        _cacheData.keys.contains(item.nativeId) == false) {
      // 第二套原生广告缓存
      final data = AdItem(
        platform: item.platform,
        weight: 1,
        type: AdDataType.native.value,
        unitId: item.nativeId,
        nativeId: location,
        secondsType: '',
      );
      adList.add(AdCacheState(data: data, scene: scene));
    }
    // 加入缓存位置
    for (final ad in adList) {
      _cacheData[ad.data.unitId] = ad;
      // 根据平台缓存广告（只做第一次广告缓存，以为广告ID一样 缓存的也一样）
      if (item.platform == AdSdkPlatform.admob.value) {
        mobileSdk.mobileCacheData(data: ad);
      } else if (item.platform == AdSdkPlatform.lovin.value) {
        lovinSdk.lovinCacheData(data: ad);
      }
      reportAdEvent(event: AdEventType.reqPlacement, scene: ad.scene);
    }
  }

  /// 广告列表
  List<AdItem> _obtionAdData(String type) {
    return adConfig.adData[type] ?? [];
  }

  /// 是否有效播放时间
  bool _adValidPlayInterTime(String scene, int playCount) {
    if (playCount == 2) return true;
    final sameInt = _timeData[scene] ?? 0; //相同位置上次显示时间
    int differentInt = 0; //不同位置上次显示时间
    for (final item in _timeData.values) {
      if (item == sameInt) continue;
      if (item > differentInt) differentInt = item;
    }
    final sameTime = DateTime.fromMillisecondsSinceEpoch(sameInt);
    final differentTime = DateTime.fromMillisecondsSinceEpoch(differentInt);
    //当前的时间
    final time = DateTime.now();
    //相同位置的播放时间差
    if (time.difference(sameTime).inSeconds < adConfig.sameTime) {
      return false;
    }
    //不同位置的播放时间差
    if (time.difference(differentTime).inSeconds < adConfig.differentTime) {
      return false;
    }
    return true;
  }

  /// 广告加载成功回调
  void _adLoadSucceed(String adUnitId, Object? ad, AdSdkPlatform type) {
    final data = _cacheData[adUnitId]!;
    data.isCache = true;
    data.ad = ad;
    _cacheData[adUnitId] = data;
    reportAdEvent(event: AdEventType.reqSuc, scene: data.scene);
    singAdCacheSucceedNotif(data, type);
  }

  /// 广告加载失败回调
  void _adLoadFailed(String adUnitId, String code, AdSdkPlatform type) {
    final AdCacheState? data = _cacheData[adUnitId];
    if (data == null) return;
    reportAdEvent(event: AdEventType.reqFail, scene: data.scene, code: code);
    // 删除失败的广告缓存
    _cacheData.remove(adUnitId);
    // 重新缓存下一个广告id 如果有多个位置需要同时缓存加入
    for (final location in data.locations) {
      final amList = _obtionAdData(location);
      // 找出当前广告缓存下标
      final index = amList.indexWhere((item) => item.unitId == adUnitId);
      // 重新缓存下一个
      _cacheLocationAd(index: index + 1, location: location, scene: data.scene);
    }
  }

  /// 广告播放成功
  void _adPlaySuccess(
    String adUnitId,
    double revenue,
    String currency,
    String network,
    AdSdkPlatform type,
  ) {
    if (_adData == null) return;
    if (adUnitId != showNativeId) {
      reportAdEvent(event: AdEventType.showPlacement, scene: _playScene);
    }
    adRevenueNotif(
      scene: _playScene,
      ecpm: revenue,
      currency: currency,
      network: network,
      code: _adData!.data.unitId,
      posId: _playLocation,
      format: _adData!.data.type,
      client: _adData!.data.platform,
      file: _fileData,
    );
  }

  /// 广告播放失败响应
  void _adPlayFailedCall(String adUnitId, String code, AdSdkPlatform type) {
    reportAdEvent(event: AdEventType.showFail, scene: _playScene, code: code);
    _adPalyExitCall(adUnitId, type);
  }

  /// 广告播放关闭响应
  void _adPalyExitCall(String adUnitId, AdSdkPlatform type) async {
    final adData = _cacheData[adUnitId];
    if (adData != null) {
      _cacheData.remove(adUnitId);
      // 保存当前广告位置的关闭时间
      _timeData[_playScene] = DateTime.now().millisecondsSinceEpoch;
      // 当前位置重新走缓存(有可能同一个广告被多个位置持有，需要同时开启缓存)
      for (final String location in adData.locations) {
        // 开启缓存
        _cacheLocationAd(index: 0, location: location, scene: _playScene);
      }
    }
    // 非激励广告 需要二次触发广告
    await Future.delayed(const Duration(milliseconds: 150));
    _showSecond(scene: _playScene, data: adData);
    if (_showAd == false) adPlayExitNotif();
  }

  /// 广告点击
  void _adWidgetOnTap(String adUnitId, AdSdkPlatform type) {
    if (_adData == null) return;
    reportAdEvent(event: AdEventType.click, scene: _playScene);
  }

  /// 请求广告权限认证
  void requestConsentInfoUpdate(Function(bool) completeCall) async {
    try {
      final canRequestAds = await ConsentInformation.instance.canRequestAds();
      if (canRequestAds == true) {
        completeCall(false);
        return;
      }
      final params = ConsentRequestParameters(
        consentDebugSettings: ConsentDebugSettings(
          debugGeography: DebugGeography.debugGeographyEea,
        ),
      );
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((loadAndShowError) {
            completeCall(true);
          });
        },
        (FormError formError) {
          completeCall(false);
        },
      );
    } catch (_) {
      completeCall(false);
    }
  }
}
