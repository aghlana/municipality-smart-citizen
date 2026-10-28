import 'package:flutter_test/flutter_test.dart';
import 'package:municipality_citizen/main.dart';

void main() {
  test('app class can be constructed', () {
    const app = MunicipalityApp();
    expect(app, isA<MunicipalityApp>());
  });
}
