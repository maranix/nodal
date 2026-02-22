import 'dart:io';

import 'package:ffigen/ffigen.dart';

void main(List<String> args) {
  final pkgRoot = Platform.script.resolve('..');

  FfiGenerator(
    output: Output(
      dartFile: pkgRoot.resolve('lib/src/third_party/sqlite3.g.dart'),
    ),
    headers: Headers(
      entryPoints: [pkgRoot.resolve('third_party/sqlite/sqlite3.h')],
      compilerOptions: [
        // PATH is hardcoded for now in initial development phase
        //
        // TODO: Make this more dynamic and look for solutions to avoid doing this
        if (Platform.isLinux) "-I/usr/lib/clang/21/include",
      ],
    ),
    functions: Functions.includeSet({'sqlite3_libversion'}),
  ).generate();
}
