import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:core';
import 'package:quran_memorization_helper/utils/utils.dart' as utils;

class Settings extends ChangeNotifier {
  static final Settings _instance = Settings._private();
  static Settings get instance => _instance;
  int _currentReadingPara = 1;
  int _currentReadingPage = 0;
  Timer? timer;

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

  int get currentReadingPage => _currentReadingPage;
  set currentReadingPage(int val) {
    _currentReadingPage = val;
    persist();
  }

  factory Settings() {
    return _instance;
  }

  Future<void> saveToDisk() async {
    Map<String, dynamic> map = {
      'fontSize': fontSize,
      'wordSpacing': wordSpacing,
      'currentReadingPara': _currentReadingPara,
      'currentReadingScrollOffset': _currentReadingPage,
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
    _currentReadingPage = json["currentReadingScrollOffset"] ?? 0.0;
  }

  Future<void> saveScrollPosition(int paraNumber, int page) async {
    currentReadingPara = paraNumber;
    currentReadingPage = page;
    await saveToDisk();
  }

  void saveScrollPositionDelayed(int paraNumber, int page) {
    currentReadingPara = paraNumber;
    currentReadingPage = page;
    persist(seconds: 4);
  }

  void persist({int seconds = 1}) {
    timer?.cancel();
    timer = Timer(Duration(seconds: seconds), saveToDisk);
  }

  Settings._private();
}
