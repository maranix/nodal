import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:daxle/daxle.dart';
import 'package:nodal/src/feature/profile/model/profile_model.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

abstract interface class ProfileRepoI {
  const ProfileRepoI();

  Future<Result<Profile, String>> read(String uuid);
  Future<Result<Profile, String>> create(CreateProfile cp);
  Future<Result<Profile, String>> update(UpdateProfile p);
  Future<Result<Profile, String>> delete(Profile p);
}

// TODO: This needs to be further improved via a local and remote database
//
// As of now this is only for prototyping
final class ProfileRepository implements ProfileRepoI {
  const ProfileRepository();

  @override
  Future<Result<Profile, String>> read(String uuid) async {
    final cacheDir = await getApplicationCacheDirectory();

    final profileBundle = cacheDir.listSync().firstWhereOrNull(
      (e) => e.uri.pathSegments.last == uuid,
    );

    if (profileBundle == null) {
      return .err("404: Profile not found");
    }

    final profile = Profile.fromJsonString(
      File(profileBundle.path).readAsStringSync(),
    );

    return .ok(profile);
  }

  @override
  Future<Result<Profile, String>> create(CreateProfile cp) async {
    final Profile p = .fromCreateProfile(cp);

    final cacheDir = await getApplicationCacheDirectory();

    final pBundle = File(path.join(cacheDir.path, p.uuid));

    pBundle.writeAsBytesSync(utf8.encode(jsonEncode(p.toJson())), flush: true);

    return .ok(p);
  }

  @override
  Future<Result<Profile, String>> delete(Profile p) async {
    final cacheDir = await getApplicationCacheDirectory();

    final pBundle = File(path.join(cacheDir.path, p.uuid));

    pBundle.deleteSync();

    return .ok(p);
  }

  @override
  Future<Result<Profile, String>> update(UpdateProfile p) async {
    // TODO: implement update
    throw UnimplementedError();
  }
}
