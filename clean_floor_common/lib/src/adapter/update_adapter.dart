import 'dart:async';

import 'package:clean_floor_annotation/clean_floor_annotation.dart';
import 'package:clean_floor_common/src/extension/on_conflict_strategy_extensions.dart';
import 'package:clean_floor_common/src/util/primary_key_helper.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart';

class UpdateAdapter<T> {
  final DatabaseExecutor _database;
  final String _entityName;
  final List<String> _primaryKeyColumnName;
  final Map<String, Object?> Function(T) _valueMapper;
  final StreamController<String>? _changeListener;

  UpdateAdapter(
    DatabaseExecutor database,
    String entityName,
    List<String> primaryKeyColumnName,
    Map<String, Object?> Function(T) valueMapper, [
    StreamController<String>? changeListener,
  ]) : assert(entityName.isNotEmpty),
       assert(primaryKeyColumnName.isNotEmpty),
       _database = database,
       _entityName = entityName,
       _valueMapper = valueMapper,
       _primaryKeyColumnName = primaryKeyColumnName,
       _changeListener = changeListener;

  Future<void> update(T item, OnConflictStrategy onConflictStrategy) async {
    await _update(item, onConflictStrategy);
  }

  Future<void> updateList(
    List<T> items,
    OnConflictStrategy onConflictStrategy,
  ) async {
    if (items.isEmpty) return;
    await _updateList(items, onConflictStrategy);
  }

  Future<int> updateAndReturnChangedRows(
    T item,
    OnConflictStrategy onConflictStrategy,
  ) {
    return _update(item, onConflictStrategy);
  }

  Future<int> updateListAndReturnChangedRows(
    List<T> items,
    OnConflictStrategy onConflictStrategy,
  ) async {
    if (items.isEmpty) return 0;
    return _updateList(items, onConflictStrategy);
  }

  Future<int> _update(T item, OnConflictStrategy onConflictStrategy) async {
    final values = _valueMapper(item);

    final result = await _database.update(
      _entityName,
      values,
      where: PrimaryKeyHelper.getWhereClause(_primaryKeyColumnName),
      whereArgs: PrimaryKeyHelper.getPrimaryKeyValues(
        _primaryKeyColumnName,
        values,
      ),
      conflictAlgorithm: onConflictStrategy.asSqfliteConflictAlgorithm(),
    );
    if (result != 0) _changeListener?.add(_entityName);
    return result;
  }

  Future<int> _updateList(
    List<T> items,
    OnConflictStrategy onConflictStrategy,
  ) async {
    final batch = _database.batch();
    for (final item in items) {
      final values = _valueMapper(item);

      batch.update(
        _entityName,
        values,
        where: PrimaryKeyHelper.getWhereClause(_primaryKeyColumnName),
        whereArgs: PrimaryKeyHelper.getPrimaryKeyValues(
          _primaryKeyColumnName,
          values,
        ),
        conflictAlgorithm: onConflictStrategy.asSqfliteConflictAlgorithm(),
      );
    }
    final result = (await batch.commit(noResult: false)).cast<int>();
    if (result.isNotEmpty) _changeListener?.add(_entityName);
    return result.isNotEmpty
        ? result.reduce((sum, element) => sum + element)
        : 0;
  }
}
