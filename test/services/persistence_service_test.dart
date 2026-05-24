import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:footyjong/services/persistence_service.dart';

void main() {
  group('PersistenceService', () {
    setUp(() {
      PersistenceService.resetForTesting();
    });

    group('init', () {
      test('successful init makes instance ready', () async {
        SharedPreferences.setMockInitialValues({});

        final svc = await PersistenceService.init();

        expect(svc, same(PersistenceService.instance));
        expect(svc.isReady, isTrue);
      });

      test('init failure degrades gracefully — getters return defaults',
          () async {
        // Intentionally NOT setting mock initial values to simulate failure
        // (SharedPreferences will throw if the mock channel is not set up).

        // We call init and it should handle gracefully
        final svc = await PersistenceService.init();

        // The service may or may not be ready depending on the test environment;
        // in either case getters should not throw.
        expect(svc, same(PersistenceService.instance));
        expect(await svc.getString('any'), isNull);
        expect(await svc.getInt('any'), 0);
        expect(await svc.getBool('any', defaultValue: true), isTrue);
        expect(await svc.getBool('any', defaultValue: false), isFalse);
      });
    });

    group('get/set round-trip', () {
      setUp(() {
        SharedPreferences.setMockInitialValues({});
      });

      test('String round-trip', () async {
        await PersistenceService.init();
        final svc = PersistenceService.instance;

        await svc.setString('name', 'test_value');
        expect(await svc.getString('name'), 'test_value');
      });

      test('int round-trip', () async {
        await PersistenceService.init();
        final svc = PersistenceService.instance;

        await svc.setInt('count', 42);
        expect(await svc.getInt('count'), 42);
      });

      test('bool round-trip', () async {
        await PersistenceService.init();
        final svc = PersistenceService.instance;

        await svc.setBool('flag', false);
        expect(await svc.getBool('flag'), false);
      });

      test('StringList round-trip', () async {
        await PersistenceService.init();
        final svc = PersistenceService.instance;

        await svc.setStringList('tags', ['a', 'b', 'c']);
        expect(await svc.getStringList('tags'), ['a', 'b', 'c']);
      });
    });

    group('default values', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        await PersistenceService.init();
      });

      test('getInt returns defaultValue for missing key', () async {
        final svc = PersistenceService.instance;
        expect(await svc.getInt('missing', defaultValue: 99), 99);
      });

      test('getInt returns 0 when no default given', () async {
        final svc = PersistenceService.instance;
        expect(await svc.getInt('missing'), 0);
      });

      test('getBool returns defaultValue for missing key', () async {
        final svc = PersistenceService.instance;
        expect(await svc.getBool('missing', defaultValue: false), isFalse);
      });

      test('getBool returns true when no default given', () async {
        final svc = PersistenceService.instance;
        expect(await svc.getBool('missing'), isTrue);
      });

      test('getString returns null for missing key', () async {
        final svc = PersistenceService.instance;
        expect(await svc.getString('missing'), isNull);
      });

      test('getStringList returns empty list for missing key', () async {
        final svc = PersistenceService.instance;
        expect(await svc.getStringList('missing'), isEmpty);
      });
    });

    group('remove', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({'foo': 'bar'});
        await PersistenceService.init();
      });

      test('remove deletes a stored value', () async {
        final svc = PersistenceService.instance;
        expect(await svc.getString('foo'), 'bar');

        await svc.remove('foo');
        expect(await svc.getString('foo'), isNull);
      });
    });

    group('singleton semantics', () {
      test('init twice returns same instance', () async {
        SharedPreferences.setMockInitialValues({});

        final a = await PersistenceService.init();
        final b = await PersistenceService.init();

        expect(a, same(b));
      });

      test('accessing instance before init throws', () {
        expect(
          () => PersistenceService.instance,
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
