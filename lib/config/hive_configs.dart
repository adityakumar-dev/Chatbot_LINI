import 'dart:convert';

import 'package:hive_flutter/adapters.dart';

class HiveConfigs {
static saveContactsData(String key, List<Map<String, String>> value) async {
  final box = await Hive.openBox('myBox');
  box.put(key, jsonEncode(value));
}


 static Future<List<Map<String, String>>> getContactsData(String key) async {
  final box = await Hive.openBox('myBox');
  String? data = box.get(key);
  if (data != null) {
    final List<dynamic> rawList = jsonDecode(data);
    return rawList
        .map((e) => Map<String, String>.from(e as Map)) // ✅ force cast properly
        .toList();
  }
  return [];
}



}