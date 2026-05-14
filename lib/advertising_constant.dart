/// 广告平台
enum AdSdkPlatform {
  admob('admob'), //谷歌平台
  lovin('applovin'); //lovin平台

  final String value;

  const AdSdkPlatform(this.value);
}

/// 广告资源类型
enum AdDataType {
  open('open'), //开屏广告
  rewarded('rewarded'), //激励广告
  interstitial('interstitial'), //插页广告
  banner('banner'), //横幅
  native('native'); //原生

  final String value;

  const AdDataType(this.value);
}

enum AdEventType {
  reqPlacement, //请求场景
  reqSuc, //请求成功
  reqFail, //请求失败
  needShow, //应展示场景
  showPlacement, //展示场景
  showFail, //展示失败
  click, //点击
}
