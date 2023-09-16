import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:core';
import 'package:quran_memorization_helper/utils/utils.dart' as utils;

class Settings extends ChangeNotifier {
  static final Settings _instance = Settings._private();
  static Settings get instance => _instance;
  int _currentReadingPara = 1;
  double _currentReadingScroll = 0.0;
  Timer? timer;
  bool _pageView = true;

  // The font size of ayahs
  int _fontSize = 24;
  int get fontSize => _fontSize;
  set fontSize(int val) {
    _fontSize = val;
    notifyListeners();
    persist();
  }

  // The word spacing between words of ayah
  int _wordSpacing = 1;
  int get wordSpacing => _wordSpacing;
  set wordSpacing(int val) {
    _wordSpacing = val;
    notifyListeners();
    persist();
  }

  int get currentReadingPara => _currentReadingPara;
  set currentReadingPara(int val) {
    _currentReadingPara = val;
    persist();
  }

  double get currentReadingScrollOffset => _currentReadingScroll;
  set currentReadingScrollOffset(double val) {
    _currentReadingScroll = val;
    persist();
  }

  bool get pageView => _pageView;
  set pageView(v) {
    _pageView = v;
    persist();
    notifyListeners();
  }

  factory Settings() {
    return _instance;
  }

  Future<void> saveToDisk() async {
    Map<String, dynamic> map = {
      'fontSize': fontSize,
      'wordSpacing': wordSpacing,
      'currentReadingPara': _currentReadingPara,
      'currentReadingScrollOffset': _currentReadingScroll,
      'pageView': _pageView,
    };
    String json = const JsonEncoder.withIndent("  ").convert(map);
    await utils.saveJsonToDisk(json, "settings");
  }

  Future<void> readSettings() async {
    final Map<String, dynamic>? json = await utils.readJsonFile("settings");
    if (json == null) return;
    _fontSize = json["fontSize"] ?? 24;
    _wordSpacing = json["wordSpacing"] ?? 1;
    _currentReadingPara = json["currentReadingPara"] ?? 1;
    _currentReadingScroll = json["currentReadingScrollOffset"] ?? 0.0;
    _pageView = json["pageView"] ?? true;
  }

  Future<void> saveScrollPosition(int paraNumber, double scrollOffset) async {
    currentReadingPara = paraNumber;
    currentReadingScrollOffset = scrollOffset;
    await saveToDisk();
  }

  void saveScrollPositionDelayed(int paraNumber, double scrollOffset) {
    if (paraNumber == currentReadingPara) {
      if ((currentReadingScrollOffset - scrollOffset).abs() < 15) {
        return;
      }
    }
    currentReadingPara = paraNumber;
    currentReadingScrollOffset = scrollOffset;
    persist(seconds: 4);
  }

  void persist({int seconds = 1}) {
    timer?.cancel();
    timer = Timer(Duration(seconds: seconds), saveToDisk);
  }

  Settings._private();
}
