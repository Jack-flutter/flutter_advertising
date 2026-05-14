import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'advertising_constant.dart';
import 'advertising_data.dart';
import 'advertising_service.dart';

class SdkLovin {
  final AdService service;
  final AdCallback callback;

  SdkLovin({required this.callback, required this.service});

  Future initialize(String key) async {
    if (key.isEmpty) return;
    await AppLovinMAX.initialize(key);
    // Max开屏广告监听
    AppLovinMAX.setAppOpenAdListener(
      AppOpenAdListener(
        onAdLoadedCallback: _lovinAdSucceed,
        onAdLoadFailedCallback: _lovinAdFailed,
        onAdDisplayedCallback: _lovinAdDisplayedCallback,
        onAdDisplayFailedCallback: _lovinAdDisplayFailedCallback,
        onAdClickedCallback: _lovinAdClickedCallback,
        onAdHiddenCallback: _lovinAMPlayClose,
      ),
    );
    // Max插屏广告监听
    AppLovinMAX.setInterstitialListener(
      InterstitialListener(
        onAdLoadedCallback: _lovinAdSucceed,
        onAdLoadFailedCallback: _lovinAdFailed,
        onAdDisplayedCallback: _lovinAdDisplayedCallback,
        onAdDisplayFailedCallback: _lovinAdDisplayFailedCallback,
        onAdClickedCallback: _lovinAdClickedCallback,
        onAdHiddenCallback: _lovinAMPlayClose,
      ),
    );
    // Max激励广告监听
    AppLovinMAX.setRewardedAdListener(
      RewardedAdListener(
        onAdLoadedCallback: _lovinAdSucceed,
        onAdLoadFailedCallback: _lovinAdFailed,
        onAdDisplayedCallback: _lovinAdDisplayedCallback,
        onAdDisplayFailedCallback: _lovinAdDisplayFailedCallback,
        onAdClickedCallback: _lovinAdClickedCallback,
        onAdHiddenCallback: _lovinAMPlayClose,
        onAdReceivedRewardCallback: (ad, reward) {},
      ),
    );
    // Max横幅广告监听
    AppLovinMAX.setBannerListener(
      AdViewAdListener(
        onAdLoadedCallback: _lovinAdSucceed,
        onAdLoadFailedCallback: _lovinAdFailed,
        onAdClickedCallback: _lovinAdClickedCallback,
        onAdExpandedCallback: (ad) {},
        onAdCollapsedCallback: (ad) {},
      ),
    );
  }

  /// max广告缓存
  void lovinCacheData({required AdCacheState data}) {
    debugPrint('MAX广告缓存 ${data.data.unitId}');
    if (data.data.type == AdDataType.open.value) {
      AppLovinMAX.loadAppOpenAd(data.data.unitId);
    } else if (data.data.type == AdDataType.interstitial.value) {
      AppLovinMAX.loadInterstitial(data.data.unitId);
    } else if (data.data.type == AdDataType.rewarded.value) {
      AppLovinMAX.loadRewardedAd(data.data.unitId);
    } else if (data.data.type == AdDataType.banner.value) {
      AppLovinMAX.preloadWidgetAdView(data.data.unitId, AdFormat.banner)
          .then((viewId) {
            callback.cacheSucceed(
              data.data.unitId,
              viewId,
              AdSdkPlatform.lovin,
            );
          })
          .catchError((e) {
            _lovinAdFailed(data.data.unitId, null);
          });
    }
  }

  /// 显示max广告
  bool showLovinAd(AdCacheState data) {
    final adUnitId = data.data.unitId;
    if (data.data.type == AdDataType.open.value) {
      AppLovinMAX.showAppOpenAd(adUnitId);
      return true;
    } else if (data.data.type == AdDataType.interstitial.value) {
      AppLovinMAX.showInterstitial(adUnitId);
      return true;
    } else if (data.data.type == AdDataType.rewarded.value) {
      AppLovinMAX.showRewardedAd(adUnitId);
      return true;
    }
    return false;
  }

  /// Max广告缓存成功
  void _lovinAdSucceed(MaxAd ad) {
    callback.cacheSucceed(ad.adUnitId, ad, AdSdkPlatform.lovin);
    debugPrint('Max广告缓存成功 ${ad.adUnitId}');
  }

  /// Max广告缓存失败回调
  void _lovinAdFailed(String adUnitId, MaxError? error) {
    final code = error?.code == null ? '0' : error!.code.toString();
    callback.cacheFailed(adUnitId, code, AdSdkPlatform.lovin);
    debugPrint('Max广告缓存失败 $adUnitId ${error?.message}');
  }

  /// Max广告显示失败
  void _lovinAdDisplayFailedCallback(MaxAd ad, MaxError error) {
    final code = error.code.toString();
    callback.showFailed(ad.adUnitId, code, AdSdkPlatform.lovin);
  }

  /// Max广告显示回调
  void _lovinAdDisplayedCallback(MaxAd ad) {
    final val = (ad.revenue * 1000000);
    callback.revenue(
      ad.adUnitId,
      val,
      'USD',
      ad.networkName,
      AdSdkPlatform.lovin,
    );
  }

  /// Max广告播放关闭
  void _lovinAMPlayClose(MaxAd ad) {
    debugPrint('Max广告播放关闭');
    callback.adClose(ad.adUnitId, AdSdkPlatform.lovin);
  }

  /// Max广告点击
  void _lovinAdClickedCallback(MaxAd ad) {
    callback.adOntap(ad.adUnitId, AdSdkPlatform.lovin);
  }
}
