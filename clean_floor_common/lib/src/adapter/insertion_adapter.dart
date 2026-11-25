import 'dart:async';

import 'package:clean_floor_annotation/clean_floor_annotation.dart';
import 'package:clean_floor_common/src/extension/on_conflict_strategy_extensions.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart';

class InsertionAdapter<T> {
  final DatabaseExecutor _database;
  final String _entityName;
  final Map<String, Object?> Function(T) _valueMapper;
  final StreamController<String>? _changeListener;

  InsertionAdapter(
    DatabaseExecutor database,
    String entityName,
    Map<String, Object?> Function(T) valueMapper, [
    StreamController<String>? changeListener,
  ]) : assert(entityName.isNotEmpty),
       _database = database,
       _entityName = entityName,
       _valueMapper = valueMapper,
       _changeListener = changeListener;

  Future<void> insert(T item, OnConflictStrategy onConflictStrategy) async {
    await _insert(item, onConflictStrategy);
  }

  Future<void> insertList(
    List<T> items,
    OnConflictStrategy onConflictStrategy,
  ) async {
    if (items.isEmpty) return;
    final batch = _database.batch();
    for (final item in items) {
      batch.insert(
        _entityName,
        _valueMapper(item),
        conflictAlgorithm: onConflictStrategy.asSqfliteConflictAlgorithm(),
      );
    }
    await batch.commit(noResult: true);
    _changeListener?.add(_entityName);
  }

  Future<int> insertAndReturnId(T item, OnConflictStrategy onConflictStrategy) {
    return _insert(item, onConflictStrategy);
  }

  Future<List<int>> insertListAndReturnIds(
    List<T> items,
    OnConflictStrategy onConflictStrategy,
  ) async {
    if (items.isEmpty) return [];
    final batch = _database.batch();
    for (final item in items) {
      batch.insert(
        _entityName,
        _valueMapper(item),
        conflictAlgorithm: onConflictStrategy.asSqfliteConflictAlgorithm(),
      );
    }
    final result = (await batch.commit(noResult: false)).cast<int>();
    if (result.isNotEmpty) _changeListener?.add(_entityName);
    return result;
  }

  Future<int> _insert(T item, OnConflictStrategy onConflictStrategy) async {
    final result = await _database.insert(
      _entityName,
      _valueMapper(item),
      conflictAlgorithm: onConflictStrategy.asSqfliteConflictAlgorithm(),
    );
    if (result != 0) _changeListener?.add(_entityName);
    return result;
  }
}
