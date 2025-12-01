import 'package:flutter/foundation.dart';
import 'package:pokemon_collector/features/user/domain/entities/user_data_entity.dart';
import 'package:pokemon_collector/features/user/domain/usecases/get_user_data_usecase.dart';
import 'package:pokemon_collector/features/user/domain/usecases/save_pokemon_usecase.dart';
import 'package:pokemon_collector/features/user/domain/usecases/update_card_timestamp_usecase.dart';

class UserViewModel extends ChangeNotifier {
  final GetUserDataUseCase getUserDataUseCase;
  final SavePokemonUseCase savePokemonUseCase;
  final UpdateCardTimestampUseCase updateCardTimestampUseCase;

  UserViewModel({
    required this.getUserDataUseCase,
    required this.savePokemonUseCase,
    required this.updateCardTimestampUseCase,
  });

  UserDataEntity? _userData;
  bool _isLoading = true;
  String? _error;
  bool _isSaving = false;
  int? _pendingPokemonId;

  UserDataEntity? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSaving => _isSaving;

  Future<void> loadUserData(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _userData = await getUserDataUseCase.execute(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPendingPokemon(int pokemonId) {
    _pendingPokemonId = pokemonId;
  }

  Future<void> savePokemonAndUpdateTimestamp(String userId) async {
    if (_isSaving) {
      return;
    }

    try {
      _isSaving = true;
      notifyListeners();

      if (_pendingPokemonId != null) {
        await savePokemonUseCase.execute(userId, _pendingPokemonId!);
        _pendingPokemonId = null;
      }

      await updateCardTimestampUseCase.execute(userId);

      _isSaving = false;
      notifyListeners();
    } catch (e) {
      print('Error saving: $e');
      _isSaving = false;
      notifyListeners();
    }
  }

  void updateUserData(UserDataEntity? newData) {
    _userData = newData;
    notifyListeners();
  }
}
