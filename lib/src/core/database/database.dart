/// The database abstraction layer for Nodal.
///
/// Provides a clean, testable API for SQLite operations without
/// leaking native binding types into application code.
///
/// ```dart
/// import 'package:nodal/src/core/database/database.dart';
/// ```
library;

export 'sqlite/sqlite_client.dart';
export 'sqlite/sqlite_client_exception.dart';
export 'sqlite/sqlite_query_result.dart';
