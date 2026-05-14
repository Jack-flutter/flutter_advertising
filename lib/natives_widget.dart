import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'advertising_service.dart';

class NativesWidget extends StatefulWidget {
  final int time;
  final double rate;
  final AdService service;
  final List<dynamic> childs;

  const NativesWidget({
    super.key,
    required this.time,
    required this.rate,
    required this.childs,
    required this.service,
  });

  @override
  State<NativesWidget> createState() => _NativesWidgetState();
}

class _NativesWidgetState extends State<NativesWidget> {
  final ValueNotifier<int> timeValue = ValueNotifier(0);
  AdWidget? firstWidget;
  AdWidget? lastWidget;
  Timer? _timer; // 倒计时
  bool isTop = true;

  @override
  void initState() {
    // TODO: implement initState
    if (widget.childs.isNotEmpty) {
      firstWidget = AdWidget(ad: widget.childs.first, key: UniqueKey());
    }
    if (widget.childs.length > 1) {
      lastWidget = AdWidget(ad: widget.childs.last, key: UniqueKey());
    }
    timeValue.value = widget.time;
    isTop = widget.childs.length == 2 ? Random().nextBool() : true;
    final double randomValue = Random().nextDouble();
    widget.service.adClickNotifier.value = randomValue > widget.rate;
    _startCountdown();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    debugPrint('---原生广告关闭---');
    super.dispose();
  }

  void _startCountdown() {
    if (timeValue.value == 0) return;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timeValue.value = timeValue.value - 1;
      if (timeValue.value <= 0) {
        timeValue.value = 0;
        _timer?.cancel();
        setState(() {});
      }
    });
  }

  /// 关闭弹出
  void closeAdWidget(BuildContext context) {
    widget.service.closeNativeMobAdPlay(widget.childs);
    setState(() {
      firstWidget = null;
      lastWidget = null;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = 320.0;
    return Container(
      color: widget.time == 0 ? Colors.transparent : Colors.black,
      width: double.maxFinite,
      height: double.maxFinite,
      alignment: Alignment.center,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        direction: Axis.vertical,
        children: [
          if (firstWidget != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(
                    color: Colors.white,
                    width: size * 0.8,
                    height: size * 0.68,
                    child: firstWidget,
                  ),
                  Positioned(left: 0, top: 0, child: _buildButtonObx(true)),
                  Positioned(right: 8, top: 8, child: _buildTimeWidget()),
                ],
              ),
            ),
          if (lastWidget != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(
                    color: Colors.white,
                    width: size * 0.8,
                    height: size * 0.68,
                    child: lastWidget,
                  ),
                  Positioned(left: 0, top: 0, child: _buildButtonObx(false)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeWidget() {
    return ValueListenableBuilder(
      valueListenable: timeValue,
      builder: (context, value, child) {
        return Visibility(
          visible: value != 0,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$value',
              style: const TextStyle(
                height: 1,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonObx(bool tag) {
    return isTop == tag
        ? ValueListenableBuilder(
            valueListenable: widget.service.adClickNotifier,
            builder: (context, value, child) {
              final visible = timeValue.value == 0;
              return Visibility(
                visible: visible,
                child: value
                    ? GestureDetector(
                        onTap: () {
                          closeAdWidget(context);
                        },
                        child: _buildButtonView(),
                      )
                    : IgnorePointer(child: _buildButtonView()),
              );
            },
          )
        : const SizedBox.shrink();
  }

  Container _buildButtonView() {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(10)),
      ),
      child: const Icon(Icons.close, color: Colors.white, size: 18),
    );
  }
}
