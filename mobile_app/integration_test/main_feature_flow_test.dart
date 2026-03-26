import 'package:OrderzHouse/core/models/api_response.dart';
import 'package:OrderzHouse/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('repository reports failure for retry scenarios', (tester) async {
    final repository = _MockAuthRepository();
    when(() => repository.requestSignupOtp(any())).thenAnswer(
      (_) async => const ApiResponse<void>(
        success: false,
        message: 'Service unavailable',
      ),
    );

    final result = await repository.requestSignupOtp('user@example.com');

    expect(result.success, isFalse);
    expect(result.message, 'Service unavailable');
  });
}
