import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage? _storage = kIsWeb 
      ? null 
      : const FlutterSecureStorage();

  Future<void> write(String key, String? value) async {
    if (kIsWeb) {
      try {
        // Untuk web, gunakan SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (value != null) {
          await prefs.setString(key, value);
        } else {
          await prefs.remove(key);
        }
      } catch (e) {
        print('Error writing to web storage: $e');
      }
      return;
    }
    await _storage?.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    if (kIsWeb) {
      try {
        // Untuk web, baca dari SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      } catch (e) {
        print('Error reading from web storage: $e');
        return null;
      }
    }
    return await _storage?.read(key: key);
  }

  Future<void> delete(String key) async {
    if (kIsWeb) {
      try {
        // Untuk web, hapus dari SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
      } catch (e) {
        print('Error deleting from web storage: $e');
      }
      return;
    }
    await _storage?.delete(key: key);
  }

  Future<void> deleteAll() async {
    if (kIsWeb) {
      try {
        // Untuk web, hapus semua data user terkait dari SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();
        for (String key in keys) {
          if (key.startsWith('user_')) {
            await prefs.remove(key);
          }
        }
      } catch (e) {
        print('Error deleting from web storage: $e');
      }
      return;
    }
    await _storage?.deleteAll();
  }
}
