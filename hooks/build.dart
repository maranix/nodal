import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final config = input.config;

    if (config.buildCodeAssets) {
      final cBuilder = CBuilder.library(
        name: 'sqlite',
        assetName: 'src/third_party/sqlite3.g.dart',
        sources: ['third_party/sqlite/sqlite3.c'],
      );

      await cBuilder.run(input: input, output: output);
    }
  });
}
