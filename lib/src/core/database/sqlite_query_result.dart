import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Represents a set of rows returned from a SQL query.
///
/// A [SqliteQueryResult] is iterable and supports indexed access, making it
/// natural to work with in both loops and direct lookups:
///
/// ```dart
/// final result = client.query('SELECT id, name FROM users');
///
/// // Iterate over all rows
/// for (final row in result) {
///   print('${row['id']}: ${row['name']}');
/// }
///
/// // Access a specific row by index
/// final firstRow = result[0];
/// ```
abstract interface class SqliteQueryResult implements Iterable<SqliteQueryRow> {
  /// The column names in this result set, in order.
  List<String> get columnNames;

  /// The number of rows in this result set.
  @override
  int get length;

  /// Whether this result set contains no rows.
  @override
  bool get isEmpty;

  /// Whether this result set contains at least one row.
  @override
  bool get isNotEmpty;

  /// Returns the row at the given [index] (zero-based).
  SqliteQueryRow operator [](int index);

  /// The underlying `sqlite3` [sqlite.ResultSet].
  ///
  /// Use this for advanced operations not covered by this interface.
  sqlite.ResultSet get nativeResultSet;
}

/// Represents a single row in a [SqliteQueryResult].
///
/// Column values can be accessed by name or by index:
///
/// ```dart
/// final row = result[0];
///
/// // By column name
/// final name = row['name'];
///
/// // By column index
/// final id = row.columnAt(0);
///
/// // As a Map
/// final map = row.toMap(); // {'id': 1, 'name': 'Alice'}
/// ```
abstract interface class SqliteQueryRow {
  /// Returns the value of the column with the given [columnName].
  dynamic operator [](String columnName);

  /// Returns the value of the column at the given zero-based [index].
  dynamic columnAt(int index);

  /// The column names available in this row.
  List<String> get columnNames;

  /// Converts this row to a [Map] of column names to values.
  Map<String, dynamic> toMap();

  /// The underlying `sqlite3` [sqlite.Row].
  ///
  /// Use this for advanced operations not covered by this interface.
  sqlite.Row get nativeRow;
}

/// A compiled SQL statement that can be executed multiple times.
///
/// Prepared statements are more efficient than calling [SqliteClient.execute]
/// or [SqliteClient.query] repeatedly with the same SQL, because the SQL
/// is compiled only once.
///
/// ```dart
/// final stmt = client.prepare('INSERT INTO users (name) VALUES (?)');
///
/// stmt.execute(['Alice']);
/// stmt.execute(['Bob']);
/// stmt.execute(['Charlie']);
///
/// stmt.close();
/// ```
///
/// Always call [close] when the statement is no longer needed to release
/// the underlying resources.
abstract interface class SqlitePreparedStatement {
  /// Executes this statement with the given [parameters].
  ///
  /// Use for statements that do not return rows (`INSERT`, `UPDATE`, etc.).
  void execute([List<Object?> parameters = const []]);

  /// Executes this statement as a query with the given [parameters].
  ///
  /// Use for `SELECT` statements that return rows.
  SqliteQueryResult query([List<Object?> parameters = const []]);

  /// The underlying `sqlite3` [sqlite.PreparedStatement].
  ///
  /// Use this for advanced operations not covered by this interface.
  sqlite.PreparedStatement get nativeStatement;

  /// Releases the resources held by this prepared statement.
  void close();
}
