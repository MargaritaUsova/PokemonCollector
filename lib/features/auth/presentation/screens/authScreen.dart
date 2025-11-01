import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pokemon_collector/features/auth/presentation/viewModels/authViewModel.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  'assets/images/PokemonCollectorLogo.png',
                ),
              ),
              const SizedBox(height: 40),

              // Заголовок
              const Text(
                'Pokemon Collector',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              // const SizedBox(height: 16),
              
              // Подзаголовок
              const Text(
                'Собери свою коллекцию покемонов',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              // const SizedBox(height: 60),
              
              // Кнопка авторизации через Google
              Consumer<AuthViewModel>(
                builder: (context, authViewModel, child) {
                  return ElevatedButton.icon(
                    onPressed: authViewModel.isLoading 
                        ? null 
                        : () => authViewModel.signInWithGoogle(),
                    icon: authViewModel.isLoading
                        ? const SizedBox(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Image.asset(
                            'assets/images/google_logo.png',
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.login,
                                color: Colors.white,
                              );
                            },
                          ),
                    label: Text(
                      authViewModel.isLoading 
                          ? 'Вход...' 
                          : 'Войти через Google',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  );
                },
              ),
              // const SizedBox(height: 20),
              // Сообщение об ошибке
              Consumer<AuthViewModel>(
                builder: (context, authViewModel, child) {
                  if (authViewModel.errorMessage != null) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        authViewModel.errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
