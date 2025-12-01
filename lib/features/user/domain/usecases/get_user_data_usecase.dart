import 'package:pokemon_collector/features/user/domain/repositories/user_repository.dart';
import 'package:pokemon_collector/features/user/domain/entities/user_data_entity.dart';

class GetUserDataUseCase {
  final UserRepository repository;

  GetUserDataUseCase(this.repository);

  Future<UserDataEntity?> execute(String userId) async {
    return await repository.getUserData(userId);
  }
}
