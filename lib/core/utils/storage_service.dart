class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final Map<String, dynamic> _memoryCache = {};

  Future<void> setString(String key, String value) async {
    _memoryCache[key] = value;
  }

  Future<String?> getString(String key) async {
    return _memoryCache[key] as String?;
  }

  Future<void> setBool(String key, bool value) async {
    _memoryCache[key] = value;
  }

  Future<bool?> getBool(String key) async {
    return _memoryCache[key] as bool?;
  }

  Future<void> remove(String key) async {
    _memoryCache.remove(key);
  }

  Future<void> clear() async {
    _memoryCache.clear();
  }
}
