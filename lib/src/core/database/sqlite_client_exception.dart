import 'package:sqlite3/sqlite3.dart' as sqlite;

/// An exception thrown by [SqliteClient] operations.
///
/// Wraps the underlying `sqlite3` package's [sqlite.SqliteException] into
/// a domain-specific type so that consumers do not depend directly on the
/// `sqlite3` package.
class SqliteClientException implements Exception {
  /// A human-readable description of what went wrong.
  final String message;

  /// The SQLite extended result code, if available.
  ///
  /// See https://sqlite.org/rescode.html for the full list.
  final int? resultCode;

  /// The SQL statement that caused this exception, if known.
  final String? sql;

  /// An optional explanation providing additional detail.
  final String? explanation;

  const SqliteClientException({
    required this.message,
    this.resultCode,
    this.sql,
    this.explanation,
  });

  /// Creates a [SqliteClientException] from a [sqlite.SqliteException].
  factory SqliteClientException.fromSqliteException(sqlite.SqliteException e) {
    return SqliteClientException(
      message: e.message,
      resultCode: e.extendedResultCode,
      sql: e.causingStatement,
      explanation: e.explanation,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('SqliteClientException');

    if (resultCode != null) {
      buffer.write('($resultCode)');
    }

    buffer.write(': $message');

    if (explanation != null) {
      buffer.write(', $explanation');
    }

    if (sql != null) {
      buffer
        ..writeln()
        ..write('  Causing statement: $sql');
    }

    return buffer.toString();
  }
}
