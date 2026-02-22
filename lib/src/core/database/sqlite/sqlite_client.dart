import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:nodal/src/core/database/sqlite/sqlite_query_result.dart';
import 'package:nodal/src/core/database/sqlite/sqlite_client_exception.dart';

/// The abstract interface for interacting with a SQLite database.
///
/// Implementations of this interface wrap the underlying SQLite driver
/// and provide a clean, testable API for database operations.
///
/// Use the factory constructors to create an instance:
///
/// ```dart
/// final client = SqliteClient.inMemory();
///
/// client.execute(
///   'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)',
/// );
///
/// client.execute('INSERT INTO users (name) VALUES (?)', ['Alice']);
///
/// final result = client.query('SELECT * FROM users');
/// for (final row in result) {
///   print(row['name']);
/// }
///
/// client.close();
/// ```
abstract interface class SqliteClient {
  /// Opens a database file at the given [path].
  ///
  /// The file is created if it does not already exist.
  factory SqliteClient.open(String path) = _SqliteClient.open;

  /// Opens an in-memory database.
  ///
  /// In-memory databases are fast and ephemeral — they are destroyed when
  /// the client is closed. Ideal for testing.
  factory SqliteClient.inMemory() = _SqliteClient.inMemory;

  /// Runs a SQL statement that does not return rows.
  ///
  /// Use this for `CREATE`, `INSERT`, `UPDATE`, `DELETE`, and other
  /// data-definition or data-manipulation statements.
  ///
  /// Optional [parameters] are bound positionally to `?` placeholders in
  /// the [sql] string, preventing SQL injection.
  void execute(String sql, [List<Object?> parameters = const []]);

  /// Runs a SQL query and returns the full result set.
  ///
  /// Use this for `SELECT` statements. The returned [SqliteQueryResult] is
  /// iterable and supports indexed access to individual rows.
  ///
  /// Optional [parameters] are bound positionally to `?` placeholders.
  SqliteQueryResult query(String sql, [List<Object?> parameters = const []]);

  /// Prepares a SQL statement for repeated execution.
  ///
  /// Prepared statements are compiled once and can be executed many times
  /// with different parameters, which is more efficient for repeated
  /// operations.
  ///
  /// The caller is responsible for calling [SqlitePreparedStatement.close] when
  /// the statement is no longer needed.
  SqlitePreparedStatement prepare(String sql);

  /// The number of rows affected by the most recent `INSERT`, `UPDATE`,
  /// or `DELETE` statement.
  int get updatedRows;

  /// Closes the database connection and releases all associated resources.
  ///
  /// After calling this method, no further operations should be performed
  /// on this client.
  void close();

  /// The underlying `sqlite3` [sqlite.Database].
  ///
  /// Use this for advanced operations not covered by this interface,
  /// such as custom functions, collations, or sessions.
  sqlite.Database get nativeDatabase;
}

// ---------------------------------------------------------------------------
// Private implementation
// ---------------------------------------------------------------------------

final class _SqliteClient implements SqliteClient {
  final sqlite.Database _db;

  _SqliteClient._(this._db);

  factory _SqliteClient.open(String path) {
    try {
      return _SqliteClient._(sqlite.sqlite3.open(path));
    } on sqlite.SqliteException catch (e) {
      throw SqliteClientException.fromSqliteException(e);
    }
  }

  factory _SqliteClient.inMemory() {
    try {
      return _SqliteClient._(sqlite.sqlite3.openInMemory());
    } on sqlite.SqliteException catch (e) {
      throw SqliteClientException.fromSqliteException(e);
    }
  }

  @override
  void execute(String sql, [List<Object?> parameters = const []]) {
    try {
      _db.execute(sql, parameters);
    } on sqlite.SqliteException catch (e) {
      throw SqliteClientException.fromSqliteException(e);
    } on StateError catch (e) {
      throw SqliteClientException(message: e.message, sql: sql);
    }
  }

  @override
  SqliteQueryResult query(String sql, [List<Object?> parameters = const []]) {
    try {
      final resultSet = _db.select(sql, parameters);
      return _SqliteQueryResult(resultSet);
    } on sqlite.SqliteException catch (e) {
      throw SqliteClientException.fromSqliteException(e);
    } on StateError catch (e) {
      throw SqliteClientException(message: e.message, sql: sql);
    }
  }

  @override
  SqlitePreparedStatement prepare(String sql) {
    try {
      final stmt = _db.prepare(sql);
      return _SqlitePreparedStatement(stmt);
    } on sqlite.SqliteException catch (e) {
      throw SqliteClientException.fromSqliteException(e);
    } on StateError catch (e) {
      throw SqliteClientException(message: e.message, sql: sql);
    }
  }

  @override
  int get updatedRows => _db.updatedRows;

  @override
  void close() {
    _db.close();
  }

  @override
  sqlite.Database get nativeDatabase => _db;
}

final class _SqliteQueryResult implements SqliteQueryResult {
  @override
  final sqlite.ResultSet nativeResultSet;

  _SqliteQueryResult(this.nativeResultSet);

  @override
  List<String> get columnNames => nativeResultSet.columnNames;

  @override
  int get length => nativeResultSet.length;

  @override
  bool get isEmpty => nativeResultSet.isEmpty;

  @override
  bool get isNotEmpty => nativeResultSet.isNotEmpty;

  @override
  SqliteQueryRow operator [](int index) =>
      _SqliteQueryRow(nativeResultSet[index]);

  @override
  Iterator<SqliteQueryRow> get iterator =>
      _SqliteQueryRowIterator(nativeResultSet);

  @override
  bool any(bool Function(SqliteQueryRow) test) =>
      nativeResultSet.any((r) => test(_SqliteQueryRow(r)));

  @override
  Iterable<T> cast<T>() => map((e) => e as T);

  @override
  bool contains(Object? element) => false;

  @override
  SqliteQueryRow elementAt(int index) => this[index];

  @override
  bool every(bool Function(SqliteQueryRow) test) =>
      nativeResultSet.every((r) => test(_SqliteQueryRow(r)));

  @override
  Iterable<T> expand<T>(Iterable<T> Function(SqliteQueryRow) toElements) =>
      nativeResultSet.expand((r) => toElements(_SqliteQueryRow(r)));

  @override
  SqliteQueryRow get first => _SqliteQueryRow(nativeResultSet.first);

  @override
  SqliteQueryRow firstWhere(
    bool Function(SqliteQueryRow) test, {
    SqliteQueryRow Function()? orElse,
  }) {
    for (final row in nativeResultSet) {
      final wrapped = _SqliteQueryRow(row);
      if (test(wrapped)) return wrapped;
    }
    if (orElse != null) return orElse();
    throw StateError('No element');
  }

  @override
  T fold<T>(T initialValue, T Function(T, SqliteQueryRow) combine) =>
      nativeResultSet.fold(
        initialValue,
        (acc, r) => combine(acc, _SqliteQueryRow(r)),
      );

  @override
  Iterable<SqliteQueryRow> followedBy(Iterable<SqliteQueryRow> other) sync* {
    yield* this;
    yield* other;
  }

  @override
  void forEach(void Function(SqliteQueryRow) action) {
    for (final result in nativeResultSet) {
      action(_SqliteQueryRow(result));
    }
  }

  @override
  String join([String separator = '']) =>
      map((e) => e.toString()).join(separator);

  @override
  SqliteQueryRow get last => _SqliteQueryRow(nativeResultSet.last);

  @override
  SqliteQueryRow lastWhere(
    bool Function(SqliteQueryRow) test, {
    SqliteQueryRow Function()? orElse,
  }) {
    SqliteQueryRow? result;
    for (final row in nativeResultSet) {
      final wrapped = _SqliteQueryRow(row);
      if (test(wrapped)) result = wrapped;
    }
    if (result != null) return result;
    if (orElse != null) return orElse();
    throw StateError('No element');
  }

  @override
  Iterable<T> map<T>(T Function(SqliteQueryRow) toElement) =>
      nativeResultSet.map((r) => toElement(_SqliteQueryRow(r)));

  @override
  SqliteQueryRow reduce(
    SqliteQueryRow Function(SqliteQueryRow, SqliteQueryRow) combine,
  ) {
    return nativeResultSet
        .map(_SqliteQueryRow.new)
        .reduce((a, b) => combine(a, b) as _SqliteQueryRow);
  }

  @override
  SqliteQueryRow get single => _SqliteQueryRow(nativeResultSet.single);

  @override
  SqliteQueryRow singleWhere(
    bool Function(SqliteQueryRow) test, {
    SqliteQueryRow Function()? orElse,
  }) {
    SqliteQueryRow? result;
    bool found = false;
    for (final row in nativeResultSet) {
      final wrapped = _SqliteQueryRow(row);
      if (test(wrapped)) {
        if (found) throw StateError('Too many elements');
        result = wrapped;
        found = true;
      }
    }
    if (found) return result!;
    if (orElse != null) return orElse();
    throw StateError('No element');
  }

  @override
  Iterable<SqliteQueryRow> skip(int count) sync* {
    int skipped = 0;
    for (final row in this) {
      if (skipped >= count) yield row;
      skipped++;
    }
  }

  @override
  Iterable<SqliteQueryRow> skipWhile(bool Function(SqliteQueryRow) test) sync* {
    bool skipping = true;
    for (final row in this) {
      if (skipping && test(row)) continue;
      skipping = false;
      yield row;
    }
  }

  @override
  Iterable<SqliteQueryRow> take(int count) sync* {
    int taken = 0;
    for (final row in this) {
      if (taken >= count) break;
      yield row;
      taken++;
    }
  }

  @override
  Iterable<SqliteQueryRow> takeWhile(bool Function(SqliteQueryRow) test) sync* {
    for (final row in this) {
      if (!test(row)) break;
      yield row;
    }
  }

  @override
  List<SqliteQueryRow> toList({bool growable = true}) =>
      nativeResultSet.map(_SqliteQueryRow.new).toList(growable: growable);

  @override
  Set<SqliteQueryRow> toSet() =>
      nativeResultSet.map(_SqliteQueryRow.new).toSet();

  @override
  Iterable<SqliteQueryRow> where(bool Function(SqliteQueryRow) test) =>
      nativeResultSet.map(_SqliteQueryRow.new).where(test);

  @override
  Iterable<T> whereType<T>() =>
      nativeResultSet.map(_SqliteQueryRow.new).whereType<T>();
}

final class _SqliteQueryRow implements SqliteQueryRow {
  @override
  final sqlite.Row nativeRow;

  _SqliteQueryRow(this.nativeRow);

  @override
  dynamic operator [](String columnName) => nativeRow[columnName];

  @override
  dynamic columnAt(int index) => nativeRow.columnAt(index);

  @override
  List<String> get columnNames => nativeRow.keys;

  @override
  Map<String, dynamic> toMap() => Map<String, dynamic>.fromEntries(
    columnNames.map((name) => MapEntry(name, nativeRow[name])),
  );

  @override
  String toString() => toMap().toString();
}

final class _SqlitePreparedStatement implements SqlitePreparedStatement {
  @override
  final sqlite.PreparedStatement nativeStatement;

  _SqlitePreparedStatement(this.nativeStatement);

  @override
  void execute([List<Object?> parameters = const []]) {
    try {
      nativeStatement.execute(parameters);
    } on sqlite.SqliteException catch (e) {
      throw SqliteClientException.fromSqliteException(e);
    }
  }

  @override
  SqliteQueryResult query([List<Object?> parameters = const []]) {
    try {
      final resultSet = nativeStatement.select(parameters);
      return _SqliteQueryResult(resultSet);
    } on sqlite.SqliteException catch (e) {
      throw SqliteClientException.fromSqliteException(e);
    }
  }

  @override
  void close() {
    nativeStatement.close();
  }
}

final class _SqliteQueryRowIterator implements Iterator<SqliteQueryRow> {
  final sqlite.ResultSet _resultSet;
  int _index = -1;

  _SqliteQueryRowIterator(this._resultSet);

  @override
  SqliteQueryRow get current => _SqliteQueryRow(_resultSet[_index]);

  @override
  bool moveNext() {
    _index++;
    return _index < _resultSet.length;
  }
}
