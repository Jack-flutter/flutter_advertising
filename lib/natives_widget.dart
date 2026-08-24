import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'advertising_service.dart';

class NativesWidget extends StatelessWidget {
  final bool isBlack;
  final FlutterAdService service;
  final List<dynamic> childs;

  const NativesWidget({
    super.key,
    required this.isBlack,
    required this.childs,
    required this.service,
  });

  /// 关闭弹出
  void closeAdWidget() {
    service.closeNativeAd(childs);
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.orientationOf(context) == .landscape;
    return Container(
      color: isBlack ? Colors.black : Colors.transparent,
      width: double.maxFinite,
      height: double.maxFinite,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .end,
        children: [
          GestureDetector(
            onTap: closeAdWidget,
            behavior: .opaque,
            child: Container(
              width: 24,
              height: 24,
              margin: EdgeInsets.only(bottom: 6),
              alignment: .center,
              decoration: BoxDecoration(
                color: isBlack ? Colors.white : Colors.black54,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.close,
                color: isBlack ? Colors.black : Colors.white,
                size: 16,
              ),
            ),
          ),
          isLandscape
              ? Row(mainAxisSize: .min, children: _buildListWidgets())
              : Column(mainAxisSize: .min, children: _buildListWidgets()),
        ],
      ),
    );
  }

  List<Widget> _buildListWidgets() {
    final size = 320.0;
    return [
      if (childs.isNotEmpty)
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            color: Colors.white,
            width: size * 0.8,
            height: size * 0.68,
            child: AdWidget(ad: childs.first),
          ),
        ),
      if (childs.length > 1) const SizedBox(width: 15, height: 15),
      if (childs.length > 1)
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            color: Colors.white,
            width: size * 0.8,
            height: size * 0.68,
            child: AdWidget(ad: childs.last),
          ),
        ),
    ];
  }
}
