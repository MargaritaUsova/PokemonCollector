import 'package:pokemon_collector/features/user/domain/repositories/user_repository.dart';

class UpdateCardTimestampUseCase {
  final UserRepository repository;

  UpdateCardTimestampUseCase(this.repository);

  Future<void> execute(String userId) async {
    await repository.updateCardTimestamp(userId);
  }
}
