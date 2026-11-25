import 'package:clean_floor_annotation/clean_floor_annotation.dart';

/// Marks a method as an insert method.
class Insert {
  /// How to handle conflicts. Defaults to [OnConflictStrategy.abort].
  final OnConflictStrategy onConflict;

  /// Marks a method as an insert method.
  const Insert({this.onConflict = OnConflictStrategy.abort});
}

/// Marks a method as an insert method.
///
/// Defaults conflict strategy to [OnConflictStrategy.abort].
const insert = Insert();
