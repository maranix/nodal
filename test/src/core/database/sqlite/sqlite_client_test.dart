import 'package:flutter_test/flutter_test.dart';
import 'package:nodal/src/core/database/database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  group('SqliteClient', () {
    late SqliteClient client;

    setUp(() {
      client = SqliteClient.inMemory();
    });

    tearDown(() {
      client.close();
    });

    group('lifecycle', () {
      test('inMemory creates a working client', () {
        expect(client, isA<SqliteClient>());
      });

      test('close disposes the client', () {
        final c = SqliteClient.inMemory();
        c.close();

        // After closing, any operation should fail.
        expect(
          () => c.execute('SELECT 1'),
          throwsA(isA<SqliteClientException>()),
        );
      });
    });

    group('execute', () {
      test('creates a table', () {
        expect(
          () => client.execute(
            'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)',
          ),
          returnsNormally,
        );
      });

      test('inserts a row', () {
        client.execute(
          'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)',
        );

        client.execute('INSERT INTO users (name) VALUES (?)', ['Alice']);

        expect(client.updatedRows, equals(1));
      });

      test('inserts multiple rows', () {
        client.execute(
          'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)',
        );

        client.execute('INSERT INTO users (name) VALUES (?)', ['Alice']);
        client.execute('INSERT INTO users (name) VALUES (?)', ['Bob']);
        client.execute('INSERT INTO users (name) VALUES (?)', ['Charlie']);

        final result = client.query('SELECT * FROM users');
        expect(result.length, equals(3));
      });

      test('updates a row', () {
        client.execute(
          'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)',
        );
        client.execute('INSERT INTO users (name) VALUES (?)', ['Alice']);

        client.execute('UPDATE users SET name = ? WHERE id = 1', ['Alicia']);

        expect(client.updatedRows, equals(1));

        final result = client.query('SELECT name FROM users WHERE id = 1');
        expect(result[0]['name'], equals('Alicia'));
      });

      test('deletes a row', () {
        client.execute(
          'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)',
        );
        client.execute('INSERT INTO users (name) VALUES (?)', ['Alice']);

        client.execute('DELETE FROM users WHERE id = 1');

        expect(client.updatedRows, equals(1));

        final result = client.query('SELECT * FROM users');
        expect(result.isEmpty, isTrue);
      });

      test('throws SqliteClientException on invalid SQL', () {
        expect(
          () => client.execute('INVALID SQL'),
          throwsA(isA<SqliteClientException>()),
        );
      });

      test('throws SqliteClientException on constraint violation', () {
        client.execute(
          'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)',
        );

        // name is NOT NULL, so this should fail.
        expect(
          () => client.execute('INSERT INTO users (name) VALUES (NULL)'),
          throwsA(isA<SqliteClientException>()),
        );
      });
    });

    group('query', () {
      setUp(() {
        client.execute(
          'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, age INTEGER)',
        );
        client.execute('INSERT INTO users (name, age) VALUES (?, ?)', [
          'Alice',
          30,
        ]);
        client.execute('INSERT INTO users (name, age) VALUES (?, ?)', [
          'Bob',
          25,
        ]);
      });

      test('returns correct column names', () {
        final result = client.query('SELECT id, name, age FROM users');

        expect(result.columnNames, equals(['id', 'name', 'age']));
      });

      test('returns correct row count', () {
        final result = client.query('SELECT * FROM users');

        expect(result.length, equals(2));
      });

      test('accesses row by index', () {
        final result = client.query('SELECT * FROM users ORDER BY id');
        final firstRow = result[0];

        expect(firstRow['name'], equals('Alice'));
      });

      test('returns empty result for no matches', () {
        final result = client.query('SELECT * FROM users WHERE name = ?', [
          'Nobody',
        ]);

        expect(result.isEmpty, isTrue);
        expect(result.isNotEmpty, isFalse);
        expect(result.length, equals(0));
      });

      test('supports parameterized queries', () {
        final result = client.query('SELECT name FROM users WHERE age > ?', [
          27,
        ]);

        expect(result.length, equals(1));
        expect(result[0]['name'], equals('Alice'));
      });

      test('throws SqliteClientException on invalid SQL', () {
        expect(
          () => client.query('SELECT * FROM nonexistent_table'),
          throwsA(isA<SqliteClientException>()),
        );
      });
    });

    group('SqliteQueryResult iteration', () {
      setUp(() {
        client.execute(
          'CREATE TABLE items (id INTEGER PRIMARY KEY, value TEXT NOT NULL)',
        );
        client.execute('INSERT INTO items (value) VALUES (?)', ['first']);
        client.execute('INSERT INTO items (value) VALUES (?)', ['second']);
        client.execute('INSERT INTO items (value) VALUES (?)', ['third']);
      });

      test('is iterable with for-in', () {
        final result = client.query('SELECT value FROM items ORDER BY id');
        final values = <String>[];

        for (final row in result) {
          values.add(row['value'] as String);
        }

        expect(values, equals(['first', 'second', 'third']));
      });

      test('supports map', () {
        final result = client.query('SELECT value FROM items ORDER BY id');
        final values = result.map((row) => row['value'] as String).toList();

        expect(values, equals(['first', 'second', 'third']));
      });

      test('supports where', () {
        final result = client.query('SELECT value FROM items ORDER BY id');
        final filtered = result
            .where((row) => row['value'] != 'second')
            .toList();

        expect(filtered.length, equals(2));
      });

      test('supports toList', () {
        final result = client.query('SELECT * FROM items');
        final list = result.toList();

        expect(list, isA<List<SqliteQueryRow>>());
        expect(list.length, equals(3));
      });
    });

    group('SqliteQueryRow', () {
      late SqliteQueryRow row;

      setUp(() {
        client.execute(
          'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, age INTEGER)',
        );
        client.execute('INSERT INTO users (name, age) VALUES (?, ?)', [
          'Alice',
          30,
        ]);

        row = client.query('SELECT id, name, age FROM users')[0];
      });

      test('accesses column by name', () {
        expect(row['name'], equals('Alice'));
        expect(row['age'], equals(30));
      });

      test('accesses column by index', () {
        expect(row.columnAt(0), equals(1)); // id
        expect(row.columnAt(1), equals('Alice')); // name
        expect(row.columnAt(2), equals(30)); // age
      });

      test('exposes column names', () {
        expect(row.columnNames, equals(['id', 'name', 'age']));
      });

      test('converts to Map', () {
        final map = row.toMap();

        expect(map, isA<Map<String, dynamic>>());
        expect(map['id'], equals(1));
        expect(map['name'], equals('Alice'));
        expect(map['age'], equals(30));
      });

      test('returns null for unknown column name', () {
        expect(row['nonexistent'], isNull);
      });
    });

    group('prepare', () {
      setUp(() {
        client.execute(
          'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)',
        );
      });

      test('prepares and executes a statement', () {
        final stmt = client.prepare('INSERT INTO users (name) VALUES (?)');

        stmt.execute(['Alice']);
        stmt.execute(['Bob']);
        stmt.close();

        final result = client.query('SELECT * FROM users ORDER BY id');
        expect(result.length, equals(2));
        expect(result[0]['name'], equals('Alice'));
        expect(result[1]['name'], equals('Bob'));
      });

      test('prepares and queries with a statement', () {
        client.execute('INSERT INTO users (name) VALUES (?)', ['Alice']);
        client.execute('INSERT INTO users (name) VALUES (?)', ['Bob']);

        final stmt = client.prepare('SELECT name FROM users WHERE id = ?');

        final result1 = stmt.query([1]);
        expect(result1.length, equals(1));
        expect(result1[0]['name'], equals('Alice'));

        final result2 = stmt.query([2]);
        expect(result2.length, equals(1));
        expect(result2[0]['name'], equals('Bob'));

        stmt.close();
      });

      test('throws SqliteClientException for invalid prepared SQL', () {
        expect(
          () => client.prepare('INVALID SQL'),
          throwsA(isA<SqliteClientException>()),
        );
      });
    });

    group('native type access', () {
      test('nativeDatabase returns the underlying sqlite3 Database', () {
        expect(client.nativeDatabase, isA<sqlite.Database>());
      });

      test('nativeResultSet returns the underlying sqlite3 ResultSet', () {
        client.execute('CREATE TABLE t (id INTEGER PRIMARY KEY)');
        client.execute('INSERT INTO t (id) VALUES (1)');

        final result = client.query('SELECT * FROM t');
        expect(result.nativeResultSet, isA<sqlite.ResultSet>());
        expect(result.nativeResultSet.length, equals(1));
      });

      test('nativeRow returns the underlying sqlite3 Row', () {
        client.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT)');
        client.execute('INSERT INTO t (name) VALUES (?)', ['test']);

        final row = client.query('SELECT * FROM t')[0];
        expect(row.nativeRow, isA<sqlite.Row>());
        expect(row.nativeRow['name'], equals('test'));
      });

      test(
        'nativeStatement returns the underlying sqlite3 PreparedStatement',
        () {
          client.execute('CREATE TABLE t (id INTEGER PRIMARY KEY)');

          final stmt = client.prepare('SELECT * FROM t');
          expect(stmt.nativeStatement, isA<sqlite.PreparedStatement>());
          stmt.close();
        },
      );
    });

    group('SqliteClientException', () {
      test('has meaningful message on SQL error', () {
        try {
          client.execute('INVALID SQL');
          fail('Should have thrown');
        } on SqliteClientException catch (e) {
          expect(e.message, isNotEmpty);
          expect(e.resultCode, isNotNull);
          expect(e.toString(), contains('SqliteClientException'));
        }
      });

      test('toString includes all relevant information', () {
        const exception = SqliteClientException(
          message: 'table not found',
          resultCode: 1,
          sql: 'SELECT * FROM missing',
          explanation: 'no such table',
        );

        final str = exception.toString();
        expect(str, contains('SqliteClientException'));
        expect(str, contains('table not found'));
        expect(str, contains('1'));
        expect(str, contains('SELECT * FROM missing'));
        expect(str, contains('no such table'));
      });
    });
  });
}
