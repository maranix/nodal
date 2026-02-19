// Copyright (c) 2026, Maranix. All rights reserved.
//
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.
//

/// A comprehensive, idiomatic Dart wrapper around the FFI-generated SQLite3
/// bindings.
///
/// ```dart
/// // Open (or create) a database:
/// final db = Sqlite.open('/path/to/my.db');
///
/// // Execute DDL / DML without result sets:
/// db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');
///
/// // Prepare a parameterised statement:
/// final stmt = db.prepare('INSERT INTO users (name) VALUES (?)');
/// stmt.execute(['Alice']);
/// stmt.execute(['Bob']);
/// stmt.finalize();
///
/// // Run a query and collect all rows:
/// final rows = db.query('SELECT * FROM users');
/// for (final row in rows) {
///   print('${row['id']}: ${row['name']}');
/// }
///
/// // Access session-level metadata:
/// print('Last insert row ID: ${db.session.lastInsertRowId}');
/// print('Rows changed: ${db.session.changes}');
///
/// // Clean up:
/// db.dispose();
/// ```
///
/// ## Architecture
///
/// The public API consists of:
///
/// - [Sqlite] – Static entry-point: version info and database factory.
/// - [SqliteDatabase] – Abstract database connection contract.
/// - [SqliteStatement] – Abstract prepared-statement contract.
/// - [SqliteSession] – Abstract session-scoped state (row ID, changes, etc.).
/// - [SqliteException] – Exception type wrapping SQLite error codes.
/// - [SqliteResultCode] – Enhanced enum of SQLite primary result codes.
/// - [SqliteOpenFlag] – Enhanced enum of `sqlite3_open_v2` flags.
/// - [SqliteColumnType] – Enum of SQLite column type affinities.
///
library;

import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:nodal/src/third_party/sqlite/sqlite3.g.dart' as raw;

/// Exception thrown when a SQLite operation fails.
///
/// Carries both the numeric [resultCode] and the human-readable [message]
/// produced by the SQLite library.
///
/// ```dart
/// try {
///   db.execute('INVALID SQL');
/// } on SqliteException catch (e) {
///   print('SQLite error ${e.resultCode}: ${e.message}');
/// }
/// ```
class SqliteException implements Exception {
  /// Creates a [SqliteException] with the given [message] and optional
  /// [resultCode].
  const SqliteException(this.message, [this.resultCode]);

  /// The human-readable error description returned by SQLite.
  final String message;

  /// The numeric SQLite result code, or `null` if unavailable.
  ///
  /// Compare against [SqliteResultCode] variants for programmatic handling.
  final SqliteResultCode? resultCode;

  @override
  String toString() {
    final code = resultCode != null
        ? ' (${resultCode!.name}=${resultCode!.value})'
        : '';
    return 'SqliteException$code: $message';
  }
}

/// SQLite primary result codes.
///
/// Each variant stores its numeric [value] as defined by the SQLite C API.
///
/// ```dart
/// final code = SqliteResultCode.fromValue(rc);
/// switch (code) {
///   case .ok    => print('Success');
///   case .busy  => print('Database is locked, retry later');
///   case .error => print('Generic error');
///   _           => print('Other: ${code.name}');
/// }
/// ```
///
/// See: <https://www.sqlite.org/rescode.html>
enum SqliteResultCode {
  /// Successful result.
  ok(0),

  /// Generic error.
  error(1),

  /// Internal logic error in SQLite.
  internal(2),

  /// Access permission denied.
  perm(3),

  /// Callback routine requested an abort.
  abort(4),

  /// The database file is locked.
  busy(5),

  /// A table in the database is locked.
  locked(6),

  /// A `malloc()` failed.
  nomem(7),

  /// Attempt to write a read-only database.
  readonly(8),

  /// Operation terminated by `sqlite3_interrupt()`.
  interrupt(9),

  /// Some kind of disk I/O error occurred.
  ioerr(10),

  /// The database disk image is malformed.
  corrupt(11),

  /// Unknown opcode in `sqlite3_file_control()`.
  notfound(12),

  /// Insertion failed because database is full.
  full(13),

  /// Unable to open the database file.
  cantopen(14),

  /// Database lock protocol error.
  protocol(15),

  /// Internal use only.
  empty(16),

  /// The database schema changed.
  schema(17),

  /// String or BLOB exceeds size limit.
  toobig(18),

  /// Abort due to constraint violation.
  constraint(19),

  /// Data type mismatch.
  mismatch(20),

  /// Library used incorrectly.
  misuse(21),

  /// OS features not available on host.
  nolfs(22),

  /// Authorization denied.
  auth(23),

  /// Not used.
  format(24),

  /// 2nd parameter to `sqlite3_bind` out of range.
  range(25),

  /// File opened that is not a database file.
  notadb(26),

  /// Notifications from `sqlite3_log()`.
  notice(27),

  /// Warnings from `sqlite3_log()`.
  warning(28),

  /// `sqlite3_step()` has another row ready.
  row(100),

  /// `sqlite3_step()` has finished executing.
  done(101);

  const SqliteResultCode(this.value);

  /// The numeric value as defined in the SQLite C header.
  final int value;

  /// Looks up an enum variant by its integer [value].
  ///
  /// Returns `null` if no matching variant exists
  static SqliteResultCode? fromValue(int value) {
    for (final code in values) {
      if (code.value == value) return code;
    }
    return null;
  }
}

/// Flags for [Sqlite.open], controlling how the database file is opened.
///
/// ```dart
/// final db = Sqlite.open(
///   '/path/to/db',
///   flags: {.readOnly},
/// );
/// ```
///
/// **VFS Only values are not supported**
///
/// See: <https://www.sqlite.org/c3ref/open.html>
/// Value Reference: <https://www.sqlite.org/c3ref/c_open_autoproxy.html>
enum SqliteOpenFlag {
  /// The database is opened in read-only mode.
  ///
  /// If the database does not already exist, an error is returned.
  readOnly(0x00000001),

  /// The database is opened for reading and writing if possible.
  ///
  /// If the disk is full or write-permission is denied the database is opened
  /// read-only instead.
  readWrite(0x00000002),

  /// The database is created if it does not already exist.
  ///
  /// Must be combined with [readWrite].
  create(0x00000004),

  /// The filename is interpreted as a URI.
  uri(0x00000040),

  /// The database will be opened as an in-memory database.
  memory(0x00000080),

  /// The new database connection will use the "multi-thread" threading mode.
  ///
  /// This means that separate threads are allowed to use SQLite at the same
  /// time, as long as each thread is using a different database connection.
  noMutex(0x00008000),

  /// The new database connection will use the "serialized" threading mode.
  ///
  /// This means the database connection can be used by multiple threads
  /// without restriction.
  fullMutex(0x00010000),

  /// The database is opened with shared cache enabled.
  sharedCache(0x00020000),

  /// The database is opened with shared cache disabled.
  privateCache(0x00040000),

  /// The database filename is not allowed to contain a symbolic link.
  noFollow(0x01000000);

  const SqliteOpenFlag(this.value);

  /// The numeric flag value as defined in the SQLite C header.
  final int value;
}

/// The fundamental data types that SQLite can store in a column.
///
/// Returned by [SqliteStatement.columnType] to indicate the storage class of
/// the value in a result row.
///
/// ```dart
/// while (stmt.step()) {
///   switch (stmt.columnType(0)) {
///     case .integer => print(stmt.columnInt(0));
///     case .float   => print(stmt.columnDouble(0));
///     case .text    => print(stmt.columnText(0));
///     case .blob    => print(stmt.columnBlob(0));
///     case .nil     => print('NULL');
///   }
/// }
/// ```
///
/// See: <https://www.sqlite.org/c3ref/c_blob.html>
enum SqliteColumnType {
  /// 64-bit signed integer.
  integer(1),

  /// 64-bit IEEE floating-point number.
  float(2),

  /// UTF-8 text string.
  text(3),

  /// Binary large object.
  blob(4),

  /// SQL NULL.
  nil(5);

  const SqliteColumnType(this.value);

  /// The numeric value as defined in the SQLite C header.
  final int value;

  /// Looks up an enum variant by its integer [value].
  ///
  /// Throws [ArgumentError] if no match is found.
  static SqliteColumnType fromValue(int value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    throw ArgumentError.value(value, 'value', 'Unknown SQLite column type');
  }
}

/// Read-only session-level state associated with an open database connection.
///
/// Obtain an instance via [SqliteDatabase.session]. Values are live and
/// reflect the current state of the underlying connection.
abstract interface class SqliteSession {
  /// The row ID of the most recent successful INSERT on this connection.
  ///
  /// Returns `0` if no INSERT has been performed.
  int get lastInsertRowId;

  /// The number of rows modified, inserted, or deleted by the most recent
  /// INSERT, UPDATE, or DELETE statement on this connection.
  int get changes;

  /// Whether the underlying database connection is still open.
  bool get isOpen;
}

/// An open connection to a SQLite database.
///
/// Obtain an instance via [Sqlite.open]. Once you are done with the
/// connection, call [dispose] (or [close]) to release native resources.
///
/// ```dart
/// final db = Sqlite.open(':memory:');
/// db.execute('CREATE TABLE t (x INTEGER)');
/// db.execute("INSERT INTO t VALUES (42)");
/// print(db.query('SELECT * FROM t')); // [{x: 42}]
/// db.dispose();
/// ```
abstract interface class SqliteDatabase {
  /// Session-scoped metadata for this connection (row ID, changes, etc.).
  SqliteSession get session;

  /// Executes one or more SQL statements that do **not** return a result set.
  ///
  /// Use this for DDL (`CREATE`, `ALTER`, `DROP`) and DML (`INSERT`,
  /// `UPDATE`, `DELETE`) that do not require parameter binding.
  ///
  /// Throws [SqliteException] on failure.
  void execute(String sql);

  /// Compiles [sql] into a prepared statement for repeated or parameterised
  /// execution.
  ///
  /// The caller is responsible for calling [SqliteStatement.finalize] when
  /// the statement is no longer needed.
  ///
  /// Throws [SqliteException] if the SQL is malformed.
  SqliteStatement prepare(String sql);

  /// Convenience method that prepares [sql], steps through every result row,
  /// collects them into a `List<Map<String, Object?>>`, and finalizes the
  /// statement.
  ///
  /// Each entry's key in the map is the column name and the value is the Dart equivalent of
  /// the SQLite value (`int`, `double`, `String`, `Uint8List`, or `null`).
  ///
  /// ```dart
  /// final rows = db.query('SELECT id, name FROM users');
  /// ```
  List<Map<String, Object?>> query(String sql);

  /// Closes the database connection, releasing all native resources.
  ///
  /// It is safe to call this more than once — subsequent calls are no-ops.
  /// Using any [SqliteStatement] prepared from this connection after closing
  /// is undefined behaviour.
  void close();

  /// Alias for [close].
  void dispose();
}

/// A compiled (prepared) SQL statement.
///
/// Obtain via [SqliteDatabase.prepare]. Call [finalize] when done.
///
/// ```dart
/// final stmt = db.prepare('SELECT * FROM users WHERE age > ?');
/// stmt.bind([18]);
/// while (stmt.step()) {
///   print(stmt.columnText(0));
/// }
/// stmt.finalize();
/// ```
abstract interface class SqliteStatement {
  /// The number of columns in the result set.
  int get columnCount;

  /// Binds [parameters] to the positional placeholders (`?`) in the
  /// statement.
  ///
  /// Supported Dart types: `int`, `double`, `String`, `Uint8List`, `bool`
  /// (stored as 0/1), and `null`.
  ///
  /// Throws [SqliteException] on failure.
  void bind(List<Object?> parameters);

  /// Binds [parameters] by name to the named placeholders (`:key`, `@key`,
  /// or `$key`) in the statement.
  ///
  /// Throws [SqliteException] if a named parameter does not exist in the
  /// statement.
  void bindByName(Map<String, Object?> parameters);

  /// Advances the statement to the next result row.
  ///
  /// Returns `true` if a row is available (i.e. `SQLITE_ROW`), or `false`
  /// when the statement has finished executing (`SQLITE_DONE`).
  ///
  /// Throws [SqliteException] on error.
  bool step();

  /// Resets the statement so it can be re-executed with new bindings.
  ///
  /// Does **not** clear the current parameter bindings — call
  /// [clearBindings] for that.
  void reset();

  /// Clears all parameter bindings, setting them to NULL.
  void clearBindings();

  /// Releases all resources associated with this statement.
  ///
  /// It is safe to call this more than once.
  void finalize();

  /// Returns the name of the column at [index].
  String columnName(int index);

  /// Returns the storage type of the value at [index] in the current row.
  SqliteColumnType columnType(int index);

  /// Reads the value at [index] as a 64-bit integer.
  int columnInt(int index);

  /// Reads the value at [index] as a 64-bit floating-point number.
  double columnDouble(int index);

  /// Reads the value at [index] as a UTF-8 string.
  String columnText(int index);

  /// Reads the value at [index] as a byte array.
  Uint8List columnBlob(int index);

  /// Reads the value at [index] as the appropriate Dart type based on
  /// [columnType].
  ///
  /// Returns `int`, `double`, `String`, `Uint8List`, or `null`.
  Object? columnValue(int index);

  /// Steps through every remaining result row and returns them as a list of
  /// column-name → value maps.
  ///
  /// After this call the statement is at `SQLITE_DONE`. Call [reset] to
  /// re-execute.
  List<Map<String, Object?>> queryAll();

  /// Convenience: binds optional [parameters], steps through the statement
  /// to completion, then resets it.
  ///
  /// Use this for INSERT / UPDATE / DELETE statements where you don't need
  /// result rows.
  void execute([List<Object?>? parameters]);
}

/// Static entry-point for the SQLite library.
///
/// Provides version information and a factory method to open database
/// connections.
///
/// ```dart
/// print(Sqlite.version);          // e.g. "3.51.2"
/// print(Sqlite.versionNumber);    // e.g. 3051002
///
/// final db = Sqlite.open('/path/to/my.db');
/// ```
abstract final class Sqlite {
  /// The version string of the linked SQLite library (e.g. `"3.51.2"`).
  static String get version =>
      raw.sqlite3_libversion().cast<Utf8>().toDartString();

  /// The version number encoded as a single integer.
  ///
  /// The encoding formula is: major×1 000 000 + minor×1 000 + patch.
  /// For example version 3.51.1 becomes `3051002`.
  static int get versionNumber => raw.sqlite3_libversion_number();

  /// The source identifier of the SQLite library (check-in hash and date).
  static String get sourceId =>
      raw.sqlite3_sourceid().cast<Utf8>().toDartString();

  /// Opens a SQLite database at [path] and returns a [SqliteDatabase].
  ///
  /// Use `':memory:'` for an in-memory database, or an empty string for a
  /// temporary on-disk database.
  ///
  /// [flags] controls how the database file is opened. Defaults to
  /// `{.readWrite, .create}`, which creates the file if it does not already exist.
  ///
  /// Throws [SqliteException] if the database cannot be opened.
  ///
  /// ```dart
  /// // Read-write (default):
  /// final db = Sqlite.open('/data/app.db');
  ///
  /// // Read-only:
  /// final dbRo = Sqlite.open(
  ///   '/data/app.db',
  ///   flags: {.readOnly},
  /// );
  /// ```
  static SqliteDatabase open(
    String path, {
    Set<SqliteOpenFlag> flags = const {.readWrite, .create},
  }) {
    return _NativeSqliteDatabase.open(path, flags);
  }
}

/// Sentinel pointer value equivalent to `SQLITE_TRANSIENT` in C.
///
/// Passing this as the destructor argument to `sqlite3_bind_text` /
/// `sqlite3_bind_blob` tells SQLite to immediately make its own copy of
/// the data.
final ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>
_sqliteTransient = ffi.Pointer.fromAddress(-1);

/// Concrete [SqliteSession] implementation.
final class _NativeSqliteSession implements SqliteSession {
  _NativeSqliteSession(this._db);

  final _NativeSqliteDatabase _db;

  @override
  int get lastInsertRowId {
    _db._ensureOpen();
    return raw.sqlite3_last_insert_rowid(_db._handle);
  }

  @override
  int get changes {
    _db._ensureOpen();
    return raw.sqlite3_changes(_db._handle);
  }

  @override
  bool get isOpen => _db._isOpen;
}

/// Concrete [SqliteDatabase] implementation.
final class _NativeSqliteDatabase implements SqliteDatabase {
  _NativeSqliteDatabase._(this._handle) : _isOpen = true {
    _session = _NativeSqliteSession(this);
  }

  /// Opens the database at [path] with the given [flags].
  static _NativeSqliteDatabase open(String path, Set<SqliteOpenFlag> flags) {
    final pathC = path.toNativeUtf8().cast<ffi.Char>();
    final ppDb = calloc<ffi.Pointer<raw.sqlite3>>();

    try {
      final flagsInt = flags.fold<int>(0, (acc, f) => acc | f.value);
      final rc = raw.sqlite3_open_v2(
        pathC,
        ppDb,
        flagsInt,
        ffi.nullptr, // default VFS
      );

      final dbPtr = ppDb.value;

      if (rc != SqliteResultCode.ok.value) {
        // Even on error, sqlite3 may allocate a handle for the error message.
        String errMsg = 'Failed to open database';
        if (dbPtr != ffi.nullptr) {
          errMsg = raw.sqlite3_errmsg(dbPtr).cast<Utf8>().toDartString();
          raw.sqlite3_close_v2(dbPtr);
        }
        throw SqliteException(errMsg, SqliteResultCode.fromValue(rc));
      }

      return _NativeSqliteDatabase._(dbPtr);
    } finally {
      calloc.free(ppDb);
      calloc.free(pathC);
    }
  }

  ffi.Pointer<raw.sqlite3> _handle;
  bool _isOpen;
  late final _NativeSqliteSession? _session;

  /// Throws if the connection is closed.
  void _ensureOpen() {
    if (!_isOpen) {
      throw const SqliteException('Database connection is closed');
    }
  }

  /// Checks [rc] against `SQLITE_OK`. If it is not OK, reads the error
  /// message from the database handle and throws a [SqliteException].
  void _checkResult(int rc) {
    if (rc != SqliteResultCode.ok.value) {
      final msg = raw.sqlite3_errmsg(_handle).cast<Utf8>().toDartString();
      throw SqliteException(msg, SqliteResultCode.fromValue(rc));
    }
  }

  @override
  SqliteSession get session {
    _ensureOpen();
    return _session!;
  }

  @override
  void execute(String sql) {
    _ensureOpen();
    final sqlC = sql.toNativeUtf8().cast<ffi.Char>();
    final pErr = calloc<ffi.Pointer<ffi.Char>>();
    try {
      final rc = raw.sqlite3_exec(
        _handle,
        sqlC,
        ffi.nullptr, // no callback
        ffi.nullptr, // no callback context
        pErr,
      );
      if (rc != SqliteResultCode.ok.value) {
        String errMsg = 'sqlite3_exec failed';
        if (pErr.value != ffi.nullptr) {
          errMsg = pErr.value.cast<Utf8>().toDartString();
          raw.sqlite3_free(pErr.value.cast());
        }
        throw SqliteException(errMsg, SqliteResultCode.fromValue(rc));
      }
    } finally {
      calloc.free(pErr);
      calloc.free(sqlC);
    }
  }

  @override
  SqliteStatement prepare(String sql) {
    _ensureOpen();
    final sqlC = sql.toNativeUtf8().cast<ffi.Char>();
    final ppStmt = calloc<ffi.Pointer<raw.sqlite3_stmt>>();
    try {
      final rc = raw.sqlite3_prepare_v2(
        _handle,
        sqlC,
        -1, // read until NUL terminator
        ppStmt,
        ffi.nullptr, // we don't need the tail pointer
      );
      _checkResult(rc);
      return _NativeSqliteStatement._(ppStmt.value, this);
    } finally {
      calloc.free(ppStmt);
      calloc.free(sqlC);
    }
  }

  @override
  List<Map<String, Object?>> query(String sql) {
    final stmt = prepare(sql);
    try {
      return stmt.queryAll();
    } finally {
      stmt.finalize();
    }
  }

  @override
  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    final rc = raw.sqlite3_close_v2(_handle);
    _handle = ffi.nullptr;
    if (rc != SqliteResultCode.ok.value) {
      // Restore state so caller can retry if needed.
      throw SqliteException(
        'Failed to close database',
        SqliteResultCode.fromValue(rc),
      );
    }
  }

  @override
  void dispose() => close();
}

/// Concrete [SqliteStatement] implementation.
final class _NativeSqliteStatement implements SqliteStatement {
  _NativeSqliteStatement._(this._handle, this._db);

  ffi.Pointer<raw.sqlite3_stmt> _handle;
  final _NativeSqliteDatabase _db;

  /// Throws if the statement has been finalized.
  void _ensureAlive() {
    if (_handle == ffi.nullptr) {
      throw const SqliteException('Statement has been finalized');
    }
  }

  @override
  void bind(List<Object?> parameters) {
    _ensureAlive();
    for (var i = 0; i < parameters.length; i++) {
      _bindValue(i + 1, parameters[i]); // SQLite indices are 1-based
    }
  }

  @override
  void bindByName(Map<String, Object?> parameters) {
    _ensureAlive();
    for (final entry in parameters.entries) {
      final name = entry.key;
      // Ensure the name has a prefix recognised by SQLite.
      final prefixed =
          (name.startsWith(':') ||
              name.startsWith('@') ||
              name.startsWith(r'$'))
          ? name
          : ':$name';
      final nameC = prefixed.toNativeUtf8().cast<ffi.Char>();
      try {
        final idx = raw.sqlite3_bind_parameter_index(_handle, nameC);
        if (idx == 0) {
          throw SqliteException('Unknown parameter name: $name');
        }
        _bindValue(idx, entry.value);
      } finally {
        calloc.free(nameC);
      }
    }
  }

  /// Binds a single Dart value to the 1-based parameter [index].
  void _bindValue(int index, Object? value) {
    int rc;
    switch (value) {
      case null:
        rc = raw.sqlite3_bind_null(_handle, index);
      case int v:
        rc = raw.sqlite3_bind_int64(_handle, index, v);
      case double v:
        rc = raw.sqlite3_bind_double(_handle, index, v);
      case bool v:
        rc = raw.sqlite3_bind_int(_handle, index, v ? 1 : 0);
      case String v:
        final encoded = v.toNativeUtf8();
        rc = raw.sqlite3_bind_text(
          _handle,
          index,
          encoded.cast<ffi.Char>(),
          encoded.length,
          _sqliteTransient,
        );
        calloc.free(encoded);
      case Uint8List v:
        final ptr = calloc<ffi.Uint8>(v.length);
        ptr.asTypedList(v.length).setAll(0, v);
        rc = raw.sqlite3_bind_blob(
          _handle,
          index,
          ptr.cast(),
          v.length,
          _sqliteTransient,
        );
        calloc.free(ptr);
      default:
        throw SqliteException('Unsupported bind type: ${value.runtimeType}');
    }
    _db._checkResult(rc);
  }

  @override
  bool step() {
    _ensureAlive();
    final rc = raw.sqlite3_step(_handle);
    if (rc == SqliteResultCode.row.value) return true;
    if (rc == SqliteResultCode.done.value) return false;

    // Any other code is an error.
    final msg = raw.sqlite3_errmsg(_db._handle).cast<Utf8>().toDartString();
    throw SqliteException(msg, SqliteResultCode.fromValue(rc));
  }

  @override
  void reset() {
    _ensureAlive();
    _db._checkResult(raw.sqlite3_reset(_handle));
  }

  @override
  void clearBindings() {
    _ensureAlive();
    _db._checkResult(raw.sqlite3_clear_bindings(_handle));
  }

  @override
  void finalize() {
    if (_handle == ffi.nullptr) return;
    raw.sqlite3_finalize(_handle);
    _handle = ffi.nullptr;
  }

  @override
  int get columnCount {
    _ensureAlive();
    return raw.sqlite3_column_count(_handle);
  }

  @override
  String columnName(int index) {
    _ensureAlive();
    return raw.sqlite3_column_name(_handle, index).cast<Utf8>().toDartString();
  }

  @override
  SqliteColumnType columnType(int index) {
    _ensureAlive();
    return SqliteColumnType.fromValue(raw.sqlite3_column_type(_handle, index));
  }

  @override
  int columnInt(int index) {
    _ensureAlive();
    return raw.sqlite3_column_int64(_handle, index);
  }

  @override
  double columnDouble(int index) {
    _ensureAlive();
    return raw.sqlite3_column_double(_handle, index);
  }

  @override
  String columnText(int index) {
    _ensureAlive();
    final ptr = raw.sqlite3_column_text(_handle, index);
    if (ptr == ffi.nullptr) return '';
    return ptr.cast<Utf8>().toDartString();
  }

  @override
  Uint8List columnBlob(int index) {
    _ensureAlive();
    final ptr = raw.sqlite3_column_blob(_handle, index);
    if (ptr == ffi.nullptr) return Uint8List(0);
    final length = raw.sqlite3_column_bytes(_handle, index);

    // Copy the data so it outlives the current row.
    return Uint8List.fromList(ptr.cast<ffi.Uint8>().asTypedList(length));
  }

  // TODO: Introduce a generic version of this function <T> for convenience.
  @override
  Object? columnValue(int index) {
    return switch (columnType(index)) {
      .integer => columnInt(index),
      .float => columnDouble(index),
      .text => columnText(index),
      .blob => columnBlob(index),
      .nil => null,
    };
  }

  @override
  List<Map<String, Object?>> queryAll() {
    _ensureAlive();
    final results = <Map<String, Object?>>[];
    final colCount = columnCount;
    final names = List.generate(colCount, columnName);

    while (step()) {
      final row = <String, Object?>{};
      for (var i = 0; i < colCount; i++) {
        row[names[i]] = columnValue(i);
      }
      results.add(row);
    }
    return results;
  }

  @override
  void execute([List<Object?>? parameters]) {
    _ensureAlive();
    if (parameters != null) {
      bind(parameters);
    }
    try {
      while (step()) {
        // Drain all rows (if any).
      }
    } finally {
      reset();
    }
  }
}
