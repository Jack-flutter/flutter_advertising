import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'advertising_service.dart';

class NativesWidget extends StatefulWidget {
  final bool isBack;
  final FlutterAdService service;
  final List<dynamic> childs;

  const NativesWidget({
    super.key,
    required this.isBack,
    required this.childs,
    required this.service,
  });

  @override
  State<NativesWidget> createState() => _NativesWidgetState();
}

class _NativesWidgetState extends State<NativesWidget> {
  AdWidget? firstWidget;
  AdWidget? lastWidget;

  @override
  void initState() {
    // TODO: implement initState
    if (widget.childs.isNotEmpty) {
      firstWidget = AdWidget(ad: widget.childs.first, key: UniqueKey());
    }
    if (widget.childs.length > 1) {
      lastWidget = AdWidget(ad: widget.childs.last, key: UniqueKey());
    }
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    debugPrint('---原生广告关闭---');
    super.dispose();
  }

  /// 关闭弹出
  void closeAdWidget(BuildContext context) {
    widget.service.closeNativeAd(widget.childs);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = 320.0;
    return Container(
      color: widget.isBack ? Colors.black : Colors.transparent,
      width: double.maxFinite,
      height: double.maxFinite,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .end,
        children: [
          GestureDetector(
            onTap: () {
              closeAdWidget(context);
            },
            behavior: .opaque,
            child: Container(
              width: 24,
              height: 24,
              margin: EdgeInsets.only(bottom: 6),
              alignment: .center,
              decoration: BoxDecoration(
                color: widget.isBack ? Colors.white : Colors.black54,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.close,
                color: widget.isBack ? Colors.black : Colors.white,
                size: 20,
              ),
            ),
          ),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            direction: Axis.vertical,
            children: [
              if (firstWidget != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    color: Colors.white,
                    width: size * 0.8,
                    height: size * 0.68,
                    child: firstWidget,
                  ),
                ),
              if (lastWidget != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    color: Colors.white,
                    width: size * 0.8,
                    height: size * 0.68,
                    child: lastWidget,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
