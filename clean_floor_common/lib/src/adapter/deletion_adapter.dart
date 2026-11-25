import 'dart:async';

import 'package:clean_floor_common/src/util/primary_key_helper.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart';

class DeletionAdapter<T> {
  final DatabaseExecutor _database;
  final String _entityName;
  final List<String> _primaryKeyColumnNames;
  final Map<String, Object?> Function(T) _valueMapper;
  final StreamController<String>? _changeListener;

  DeletionAdapter(
    DatabaseExecutor database,
    String entityName,
    List<String> primaryKeyColumnName,
    Map<String, Object?> Function(T) valueMapper, [
    StreamController<String>? changeListener,
  ]) : assert(entityName.isNotEmpty),
       assert(primaryKeyColumnName.isNotEmpty),
       _database = database,
       _entityName = entityName,
       _primaryKeyColumnNames = primaryKeyColumnName,
       _valueMapper = valueMapper,
       _changeListener = changeListener;

  Future<void> delete(T item) async {
    await _delete(item);
  }

  Future<void> deleteList(List<T> items) async {
    if (items.isEmpty) return;
    await _deleteList(items);
  }

  Future<int> deleteAndReturnChangedRows(T item) {
    return _delete(item);
  }

  Future<int> deleteListAndReturnChangedRows(List<T> items) async {
    if (items.isEmpty) return 0;
    return _deleteList(items);
  }

  Future<int> _delete(T item) async {
    final result = await _database.delete(
      _entityName,
      where: PrimaryKeyHelper.getWhereClause(_primaryKeyColumnNames),
      whereArgs: PrimaryKeyHelper.getPrimaryKeyValues(
        _primaryKeyColumnNames,
        _valueMapper(item),
      ),
    );
    if (result != 0) _changeListener?.add(_entityName);
    return result;
  }

  Future<int> _deleteList(List<T> items) async {
    final batch = _database.batch();
    for (final item in items) {
      batch.delete(
        _entityName,
        where: PrimaryKeyHelper.getWhereClause(_primaryKeyColumnNames),
        whereArgs: PrimaryKeyHelper.getPrimaryKeyValues(
          _primaryKeyColumnNames,
          _valueMapper(item),
        ),
      );
    }
    final result = (await batch.commit(noResult: false)).cast<int>();
    if (result.isNotEmpty) _changeListener?.add(_entityName);
    return result.isNotEmpty
        ? result.reduce((sum, element) => sum + element)
        : 0;
  }
}
