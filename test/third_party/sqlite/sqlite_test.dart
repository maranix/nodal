import 'package:flutter_test/flutter_test.dart';
import 'package:nodal/src/third_party/sqlite/sqlite3.dart';

void main() {
  group('Sqlite', () {
    test('version reports correctly', () {
      expect(Sqlite.version, startsWith("3.5"));
    });

    test('opens correctly', () {
      final db = Sqlite.open(':memory:');

      final results = db.query('SELECT sqlite_version();');
      expect(results.first.values.first, equals('3.51.2'));

      db.dispose();
    });
  });

  group('Sqlite', () {
    late final SqliteDatabase db;

    setUpAll(() {
      db = Sqlite.open(':memory:');

      db.execute('CREATE TABLE names (id integer PRIMARY KEY, name TEXT)');
    });

    tearDownAll(() => db.close());

    test('instance functions properly', () {
      expect(db.session.isOpen, isTrue);

      final stmt = db.prepare('INSERT INTO names (name) VALUES (?)');

      stmt.execute(['foo']);
      stmt.execute(['bar']);

      stmt.finalize();

      final results = db.query('SELECT * FROM names');

      expect(results.length, equals(2));
      expect(
        db.session.changes,
        equals(1),
      ); // We inserted 2 values into 'name' column in a single operation
      expect(db.session.lastInsertRowId, equals(2));

      // Collect the name column values from results
      final names = <String>[];
      for (final result in results) {
        names.add(result['name'] as String);
      }

      expect(names, unorderedEquals(['foo', 'bar']));
    });
  });
}
