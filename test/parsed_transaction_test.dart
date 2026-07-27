import 'package:flutter_test/flutter_test.dart';
import 'package:ordo_finance/core/ai/parsed_transaction.dart';

void main() {
  group('ParsedTransaction.listFromJson', () {
    test('lee varios movimientos de una captura', () {
      final result = ParsedTransaction.listFromJson({
        'movements': [
          {'type': 'expense', 'amount': 350.5, 'description': 'Uber'},
          {'type': 'income', 'amount': 5000, 'description': 'Nómina'},
        ],
      });

      expect(result, hasLength(2));
      expect(result.first.amount, 350.5);
      expect(result.first.description, 'Uber');
      expect(result.last.type, 'income');
    });

    test('acepta un array suelto', () {
      final result = ParsedTransaction.listFromJson([
        {'type': 'expense', 'amount': 10, 'description': 'Café'},
      ]);
      expect(result, hasLength(1));
    });

    test('acepta un objeto único, como respondía antes', () {
      final result = ParsedTransaction.listFromJson({
        'type': 'expense',
        'amount': 10,
        'description': 'Café',
      });
      expect(result, hasLength(1));
      expect(result.single.description, 'Café');
    });

    test('una fila ilegible no tira el resto', () {
      final result = ParsedTransaction.listFromJson({
        'movements': [
          {'type': 'expense', 'amount': 10, 'description': 'Café'},
          'basura',
          {'type': 'expense', 'amount': 20, 'description': 'Pan'},
        ],
      });
      expect(result, hasLength(2));
    });

    test('sin movimientos devuelve lista vacía', () {
      expect(ParsedTransaction.listFromJson({'movements': []}), isEmpty);
      expect(ParsedTransaction.listFromJson(null), isEmpty);
    });

    test('recorta descripciones largas a 80 caracteres', () {
      final result = ParsedTransaction.listFromJson({
        'movements': [
          {'type': 'expense', 'amount': 1, 'description': 'x' * 200},
        ],
      });
      expect(result.single.description.length, 80);
    });
  });
}
