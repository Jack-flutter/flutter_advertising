import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advertising/advertising_data.dart';

import 'ad_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    loadAdData();
    super.initState();
  }

  void loadAdData() async {
    // 初始化sdk
    await AdTestService.R.initAppAdSdk(lovinKey: '');
    // 更新配置
    final path = 'assets/json/ad.json';
    final adJson = await rootBundle.loadString(path);
    final cf = AdTestService.R.updateAdConfig(json: adJson);
    // 重新添加广告配置
    final List<AdItem> items = cf.adData['play'] ?? [];
    items.add(
      AdItem(
        platform: 'admob',
        weight: 2,
        type: 'rewarded',
        unitId: 'ca-app-pub-3940256099942544/1712485313',
      ),
    );
    cf.adData['play'] = items;
    // 开启缓存
    AdTestService.R.startCacheAd(scene: 'code');
    log('广告初始化完成');
  }

  void showOpen() {
    AdTestService.R.popAd(scene: 'home', location: 'open');
  }

  void showPlay() {
    AdTestService.R.popAd(scene: 'home', location: 'play');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Column(
            mainAxisAlignment: .center,
            children: [
              TextButton(onPressed: showOpen, child: const Text('show open')),
              TextButton(onPressed: showPlay, child: const Text('show play')),
            ],
          ),
        ),
      ),
    );
  }
}
