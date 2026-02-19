import 'dart:io';

import 'package:ffigen/ffigen.dart';

const _thirdPartyDir = 'third_party';
const _sqliteDir = '$_thirdPartyDir/sqlite';

void main(List<String> args) {
  final pkgRoot = Platform.script.resolve('..');

  FfiGenerator(
    output: Output(
      dartFile: pkgRoot.resolve('lib/src/$_sqliteDir/sqlite3.g.dart'),
    ),
    headers: Headers(
      entryPoints: [pkgRoot.resolve('$_sqliteDir/sqlite3.h')],
      compilerOptions: [
        // PATH is hardcoded for now in initial development phase
        //
        // TODO: Make this more dynamic and look for solutions to avoid doing this
        if (Platform.isLinux) "-I/usr/lib/clang/21/include",
      ],
    ),
    functions: .includeAll,
  ).generate();
}
