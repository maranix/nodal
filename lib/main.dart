import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() async {
  final db = sqlite.sqlite3.openInMemory();

  db.execute(
    "CREATE TABLE profiles (id INTEGER PRIMARY KEY, pos INTEGER NOT NULL);",
  );

  runApp(MainApp(db: db));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, required this.db});

  final sqlite.Database db;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final ValueNotifier<sqlite.ResultSet?> profileTableRowResult;

  void deleteRowCallback(int id) {
    widget.db.execute('DELETE FROM profiles WHERE id = $id');

    profileTableRowResult.value = widget.db.select('SELECT * FROM profiles');
  }

  void addRowCallback() {
    final pos = profileTableRowResult.value?.length ?? 0;

    widget.db.execute('INSERT INTO profiles (pos) VALUES (?)', [pos + 1]);

    profileTableRowResult.value = widget.db.select('SELECT * FROM profiles');
  }

  @override
  void initState() {
    super.initState();

    profileTableRowResult = .new(null);
  }

  @override
  void dispose() {
    profileTableRowResult.dispose();
    widget.db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: RowList(
            rowsNotifier: profileTableRowResult,
            onDelete: (id) => deleteRowCallback(id),
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: .end,
          children: [AddRowButton(onPressed: addRowCallback)],
        ),
      ),
    );
  }
}

class RowList extends StatelessWidget {
  const RowList({
    super.key,
    required this.rowsNotifier,
    required this.onDelete,
  });

  final ValueNotifier<sqlite.ResultSet?> rowsNotifier;
  final void Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: rowsNotifier,
      builder: (context, rows, child) {
        if (rows == null) {
          return switch (child) {
            null => Text('Nothing to be displayed here.'),
            _ => child,
          };
        }

        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                spacing: 24,
                mainAxisAlignment: .center,
                children: [
                  Text(row['pos'].toString(), textAlign: .center),
                  DeleteRowButton(onPressed: () => onDelete(row['id'])),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AddRowButton extends StatelessWidget {
  const AddRowButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(onPressed: onPressed, icon: Icon(Icons.add));
  }
}

class DeleteRowButton extends StatelessWidget {
  const DeleteRowButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(onPressed: onPressed, icon: Icon(Icons.delete));
  }
}
