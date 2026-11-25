import 'package:clean_floor_common/src/migration.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart';

// ignore: avoid_classes_with_only_static_members
abstract class MigrationAdapter {
  /// Runs the given [migrations] for migrating the database schema and data.
  static Future<void> runMigrations(
    Database migrationDatabase,
    int startVersion,
    int endVersion,
    List<Migration> migrations,
  ) async {
    final relevantMigrations =
        migrations
            .where((migration) => migration.startVersion >= startVersion)
            .toList()
          ..sort(
            (first, second) =>
                first.startVersion.compareTo(second.startVersion),
          );

    if (relevantMigrations.isEmpty ||
        relevantMigrations.last.endVersion != endVersion) {
      throw StateError(
        'There is no migration supplied to update the database to the current version.'
        ' Aborting the migration.',
      );
    }

    for (final migration in relevantMigrations) {
      await migration.migrate(migrationDatabase);
    }
  }
}
