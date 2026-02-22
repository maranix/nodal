import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nodal/src/feature/profile/model/profile_model.dart';
import 'package:nodal/src/feature/profile/repository/profile_repository.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  static Future<List<Profile>> getCacheDirectoryProfiles() async {
    final content = await getApplicationCacheDirectory();
    final data = content.listSync();

    if (data.isEmpty) {
      return [];
    }

    return data
        .map((e) => Profile.fromJsonString(File(e.path).readAsStringSync()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FutureBuilder(
          future: getCacheDirectoryProfiles(),
          builder: (context, profileList) {
            if (profileList.hasData) {
              if (profileList.requireData.isEmpty) {
                return Center(
                  child: Text(
                    "What The FUCk: ${profileList.requireData.length}",
                  ),
                );
              }

              return Center(
                child: Column(
                  spacing: 4,
                  mainAxisAlignment: .center,
                  children: profileList.requireData
                      .map(
                        (p) => ListTile(
                          title: Text(p.uuid),
                          trailing: IconButton.filled(
                            onPressed: () async =>
                                await ProfileRepository().delete(p),
                            color: Colors.red,
                            icon: Icon(Icons.delete),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            }
            return Center(child: Text('Hello World!'));
          },
        ),
        floatingActionButton: FloatingActionButton.small(
          onPressed: () async {
            final date = DateTime.now();

            await ProfileRepository().create(
              .defaults(firstName: date.toIso8601String(), dob: date),
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
