import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final Map<String, dynamic> _database = {};

  Future<void> initDatabase() async {
    debugPrint('Initializing local/remote database...');
  }

  Future<void> insert(String table, String id, Map<String, dynamic> data) async {
    _database['$table/$id'] = data;
  }

  Future<Map<String, dynamic>?> query(String table, String id) async {
    return _database['$table/$id'] as Map<String, dynamic>?;
  }

  Future<void> delete(String table, String id) async {
    _database.remove('$table/$id');
  }

  Future<void> clearAll() async {
    _database.clear();
  }
}
