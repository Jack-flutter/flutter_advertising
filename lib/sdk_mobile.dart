import 'package:flutter/cupertino.dart' show debugPrint;
import 'package:flutter/material.dart' show Colors;
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'advertising_constant.dart';
import 'advertising_data.dart';
import 'advertising_service.dart';

class SdkMobile {
  final AdService service;
  final AdCallback callback;

  SdkMobile({required this.callback, required this.service});

  Future initialize() async {
    final status = await ConsentInformation.instance.getConsentStatus();
    final configuration = RequestConfiguration(
      tagForUnderAgeOfConsent: status != ConsentStatus.obtained
          ? TagForUnderAgeOfConsent.yes
          : TagForUnderAgeOfConsent.unspecified,
    );
    MobileAds.instance.updateRequestConfiguration(configuration);
    await MobileAds.instance.initialize();
  }

  /// 谷歌谷歌缓存
  Future<void> mobileCacheData({required AdCacheState data}) async {
    debugPrint('谷歌广告缓存 ${data.data.unitId}');
    if (data.data.type == AdDataType.open.value) {
      AppOpenAd.load(
        adUnitId: data.data.unitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: _mobileAdSucceed,
          onAdFailedToLoad: (e) {
            _mobileAdFailed(e, data.data.unitId);
          },
        ),
      );
    } else if (data.data.type == AdDataType.interstitial.value) {
      InterstitialAd.load(
        adUnitId: data.data.unitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: _mobileAdSucceed,
          onAdFailedToLoad: (e) {
            _mobileAdFailed(e, data.data.unitId);
          },
        ),
      );
    } else if (data.data.type == AdDataType.rewarded.value) {
      RewardedAd.load(
        adUnitId: data.data.unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: _mobileAdSucceed,
          onAdFailedToLoad: (e) {
            _mobileAdFailed(e, data.data.unitId);
          },
        ),
      );
    } else if (data.data.type == AdDataType.native.value) {
      NativeAd(
        adUnitId: data.data.unitId,
        listener: NativeAdListener(
          onAdLoaded: _mobileAdSucceed,
          onAdFailedToLoad: (ad, error) {
            _mobileAdFailed(error, data.data.unitId);
            ad.dispose();
          },
          onAdClicked: (ad) {
            service.adClickNotifier.value = true;
            _mobileAdClicked(ad);
          },
          onPaidEvent: _mobilePaidEventCallback,
        ),
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          mainBackgroundColor: Colors.white,
          cornerRadius: 10.0,
        ),
      ).load();
    } else if (data.data.type == AdDataType.banner.value) {
      final size = AdSize.getLandscapeInlineAdaptiveBannerAdSize(320);
      BannerAd(
        size: size,
        adUnitId: data.data.unitId,
        listener: BannerAdListener(
          onAdLoaded: _mobileAdSucceed,
          onAdFailedToLoad: (ad, error) {
            _mobileAdFailed(error, data.data.unitId);
            ad.dispose();
          },
          onAdClicked: _mobileAdClicked,
          onAdClosed: _mobileAMPlayClose,
          onPaidEvent: _mobilePaidEventCallback,
        ),
        request: const AdRequest(),
      ).load();
    }
  }

  /// 显示mob广告
  bool showMobileAd(AdCacheState data) {
    final ad = data.ad;
    if (ad is AdWithoutView) {
      ad.onPaidEvent = _mobilePaidEventCallback;
    }
    if (ad is AppOpenAd) {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdClicked: _mobileAdClicked,
        onAdDismissedFullScreenContent: _mobileAMPlayClose,
        onAdShowedFullScreenContent: _mobileAdShowedFullScreenContent,
        onAdFailedToShowFullScreenContent: _mobileAdShowFailedScreenContent,
      );
      ad.show();
      return true;
    } else if (ad is InterstitialAd) {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdClicked: _mobileAdClicked,
        onAdDismissedFullScreenContent: _mobileAMPlayClose,
        onAdShowedFullScreenContent: _mobileAdShowedFullScreenContent,
        onAdFailedToShowFullScreenContent: _mobileAdShowFailedScreenContent,
      );
      ad.show();
      return true;
    } else if (ad is RewardedAd) {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdClicked: _mobileAdClicked,
        onAdDismissedFullScreenContent: _mobileAMPlayClose,
        onAdShowedFullScreenContent: _mobileAdShowedFullScreenContent,
        onAdFailedToShowFullScreenContent: _mobileAdShowFailedScreenContent,
      );
      ad.show(onUserEarnedReward: (_, reward) {});
      return true;
    } else if (ad is NativeAd) {
      _mobileAdShowedFullScreenContent(data.ad);
      service.showNativeAd(data);
      return true;
    }
    return false;
  }

  /// 原生mob广告主动关闭
  void nativeMobAdPlayClose({required Ad? ad, required bool isRep}) {
    if (ad == null) return;
    if (isRep) _mobileAMPlayClose(ad);
    ad.dispose();
  }

  /// mob广告收益回调
  void _mobilePaidEventCallback(
    Ad ad,
    double valueMicros,
    PrecisionType precision,
    String code,
  ) {
    final network = ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName;
    callback.revenue(
      ad.adUnitId,
      valueMicros,
      code,
      network ?? '',
      AdSdkPlatform.admob,
    );
  }

  /// mob广告缓存成功
  void _mobileAdSucceed(Ad ad) {
    callback.cacheSucceed(ad.adUnitId, ad, AdSdkPlatform.admob);
    debugPrint('adMob广告缓存成功 ${ad.adUnitId}');
  }

  /// mob广告缓存失败回调
  void _mobileAdFailed(LoadAdError error, String adUnitId) {
    final code = error.code.toString();
    callback.cacheFailed(adUnitId, code, AdSdkPlatform.admob);
    debugPrint('adMob广告缓存失败 $adUnitId');
  }

  /// mob显示失败
  void _mobileAdShowFailedScreenContent(Ad ad, AdError error) {
    final code = error.code.toString();
    callback.showFailed(ad.adUnitId, code, AdSdkPlatform.admob);
  }

  /// mob显示成功
  void _mobileAdShowedFullScreenContent(Ad ad) {}

  /// mob广告点击
  void _mobileAdClicked(Ad ad) {
    callback.adOntap(ad.adUnitId, AdSdkPlatform.admob);
  }

  /// mob广告播放关闭
  void _mobileAMPlayClose(Ad ad) {
    final adUnitId = ad.adUnitId;
    callback.adClose(adUnitId, AdSdkPlatform.admob);
    debugPrint('adMob广告播放关闭');
  }
}
