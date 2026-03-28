import 'dart:io';

import 'package:odin_core/odin_core.dart';
import 'package:test/test.dart';

void main() {
  group('OdinEnvironment.resolveForCli', () {
    test('fails with both keys when nothing is set', () {
      final r = OdinEnvironment.resolveForCli(environmentForTesting: const {});
      expect(r.isSuccess(), isFalse);
      r.resolve((_) => fail('expected failure'), (e) {
        expect(e.missingVariables, containsAll(['API_URL', 'API_VERSION']));
        expect(e.message, contains('API_URL'));
        expect(e.message, contains('API_VERSION'));
        expect(e.message, contains('export API_URL'));
      });
    });

    test('fails when only API_URL is set', () {
      final r = OdinEnvironment.resolveForCli(
        environmentForTesting: const {'API_URL': 'https://a.example/'},
      );
      r.resolve(
        (_) => fail('expected failure'),
        (e) => expect(e.missingVariables, ['API_VERSION']),
      );
    });

    test('succeeds when both are set in process env map', () {
      final r = OdinEnvironment.resolveForCli(
        environmentForTesting: const {
          'API_URL': 'https://a.example/',
          'API_VERSION': 'v2',
        },
      );
      r.resolve((env) {
        expect(env.apiUrl, 'https://a.example/');
        expect(env.apiVersion, 'v2');
        expect(env.successfulStatusCode, 200);
      }, (_) => fail('expected success'));
    });

    test('CLI overrides fill missing env', () {
      final r = OdinEnvironment.resolveForCli(
        environmentForTesting: const {'API_URL': 'https://a.example/'},
        apiVersionOverride: 'v9',
      );
      expect(r.isSuccess(), isTrue);
      r.resolve((env) {
        expect(env.apiUrl, 'https://a.example/');
        expect(env.apiVersion, 'v9');
      }, (_) => fail('expected success'));
    });

    test('process env overrides file values', () async {
      final dir = await Directory.systemTemp.createTemp('odin_env_test');
      final path = '${dir.path}/.env';
      File(path).writeAsStringSync('''
API_URL=https://from-file.example/
API_VERSION=v1
''');
      final r = OdinEnvironment.resolveForCli(
        envFilePath: path,
        environmentForTesting: const {
          'API_URL': 'https://from-shell.example/',
          'API_VERSION': 'v1',
        },
      );
      await dir.delete(recursive: true);
      r.resolve((env) {
        expect(env.apiUrl, 'https://from-shell.example/');
        expect(env.apiVersion, 'v1');
      }, (_) => fail('expected success'));
    });

    test('SUCCESSFUL_STATUS_CODE from env is applied', () {
      final r = OdinEnvironment.resolveForCli(
        environmentForTesting: const {
          'API_URL': 'https://a.example/',
          'API_VERSION': 'v1',
          'SUCCESSFUL_STATUS_CODE': '201',
        },
      );
      r.resolve(
        (env) => expect(env.successfulStatusCode, 201),
        (_) => fail('expected success'),
      );
    });
  });
}
