import 'advertising_constant.dart';

class AdConfig {
  int sameTime; //相同广告位广告展示间隔时间
  int differentTime; //不同广告位广告展示间隔时间
  int splashTime; //冷启动时最长广告加载时间
  int nativeShowTime; //原生广告显示关闭按钮时间
  int nativeShowTimeTwo; //原生广告显示关闭按钮时间
  int playCount; //播放中第几个播放广告
  int playTime; //播放中触发广告时间
  double playPush; //播放中原生广告点击跳转概率 0-1
  double nativePush; //原生广告点击概率 0-1
  double nativePushTwo; //原生广告点击概率 0-1
  int playAdTime; //播放中广告的时间点设置
  String second; //非激励补充广告
  String secondRv; //激励补充广告
  Map<String, List<AdItem>> adData; //广告数据 key-广告位 value-广告集合

  AdConfig({
    required this.sameTime,
    required this.differentTime,
    required this.splashTime,
    required this.playCount,
    required this.playTime,
    required this.playPush,
    required this.playAdTime,
    required this.nativeShowTime,
    required this.nativeShowTimeTwo,
    required this.nativePush,
    required this.nativePushTwo,
    required this.second,
    required this.secondRv,
    required this.adData,
  });

  factory AdConfig.fromJson(Map<String, dynamic> json) {
    final Map<String, List<AdItem>> adData = {};
    final Map<String, dynamic> data = json['ad_data'] ?? {};
    for (final String key in data.keys) {
      final List list = data[key] ?? [];
      adData[key] = list.map((item) => AdItem.fromJson(item)).toList();
    }
    return AdConfig(
      sameTime: json['same_time'] ?? 60,
      differentTime: json['different_time'] ?? 60,
      splashTime: json['splash_time'] ?? 10,
      playCount: json['play_count'] ?? 3,
      playTime: json['play_time'] ?? 5,
      playPush: json['play_push'] ?? 0.5,
      nativeShowTime: json['native_show_time'] ?? 3,
      nativeShowTimeTwo: json['native_show_time_two'] ?? 5,
      nativePush: json['native_push'] ?? 0.5,
      nativePushTwo: json['native_push_two'] ?? 0.5,
      playAdTime: json['play_ad_time'] ?? 600,
      second: json['second'] ?? '',
      secondRv: json['second_rv'] ?? '',
      adData: adData,
    );
  }
}

class AdItem {
  final String platform; //广告来源
  final int weight; //广告权重
  final String type; //广告类型 open(横幅) rewarded(激励) interstitial(插页) banner(横幅)
  final String unitId; //广告id
  final String nativeId; //原生id
  AdItem({
    required this.platform,
    required this.weight,
    required this.type,
    required this.unitId,
    this.nativeId = '',
  });

  factory AdItem.fromJson(Map<String, dynamic> json) => AdItem(
    platform: json['platform'] ?? '',
    weight: json['weight'] ?? 0,
    type: json['type'] ?? '',
    unitId: json['unit_id'] ?? '',
    nativeId: json['native_id'] ?? '',
  );
}

class AdCacheState {
  final AdItem data; // 广告数据
  final String scene; // 广告场景
  dynamic ad; //广告对象
  bool isCache = false; // 是否缓存
  Set<String> locations = {}; //有时候一个广告资源会对应多个广告位置
  AdCacheState({required this.data, required this.scene});
}

class AdCallback {
  final Function(String adUnitId, Object? ad, AdSdkPlatform type) cacheSucceed;
  final Function(String adUnitId, String code, AdSdkPlatform type) cacheFailed;
  final Function(String adUnitId, String code, AdSdkPlatform type) showFailed;
  final Function(String adUnitId, AdSdkPlatform type) adOntap;
  final Function(String adUnitId, AdSdkPlatform type) adClose;
  final Function(
    String adUnitId,
    double revenue,
    String currency,
    String network,
    AdSdkPlatform type,
  )
  revenue;

  AdCallback({
    required this.cacheSucceed,
    required this.cacheFailed,
    required this.showFailed,
    required this.adOntap,
    required this.adClose,
    required this.revenue,
  });
}
