# Инструкция по настройке Google Sign-In в Firebase

## Проблема
Прозрачное окно и ошибка при нажатии на "Войти через Google" указывают на неправильную настройку Google Sign-In в Firebase консоли.

## Решение

### 1. Настройка в Firebase консоли

1. **Откройте Firebase консоль:** https://console.firebase.google.com/
2. **Выберите ваш проект:** pokemoncollector-73859
3. **Перейдите в Authentication:**
   - В левом меню выберите "Authentication"
   - Перейдите на вкладку "Sign-in method"
4. **Включите Google Sign-In:**
   - Найдите "Google" в списке провайдеров
   - Нажмите на него
   - Включите переключатель "Enable"
   - Нажмите "Save"

### 2. Настройка OAuth клиента

1. **В том же окне Google Sign-In:**
   - Найдите секцию "Web SDK configuration"
   - Скопируйте "Web client ID" (он должен быть заполнен)
2. **Если Web client ID пустой:**
   - Перейдите в Google Cloud Console: https://console.cloud.google.com/
   - Выберите проект pokemoncollector-73859
   - Перейдите в "APIs & Services" > "Credentials"
   - Создайте новый "OAuth 2.0 Client ID" для Web application
   - Добавьте домены: localhost:3000, localhost:8080
   - Скопируйте Client ID и добавьте в Firebase

### 3. Обновление google-services.json

После настройки OAuth клиента:
1. **Скачайте новый google-services.json:**
   - В Firebase консоли перейдите в Project Settings
   - В разделе "Your apps" найдите Android приложение
   - Нажмите "Download google-services.json"
2. **Замените файл:**
   - Замените старый файл в `android/app/google-services.json`
   - Новый файл должен содержать секцию `oauth_client` с данными

### 4. Проверка настройки

После выполнения всех шагов:
1. **Очистите проект:**
   ```bash
   flutter clean
   flutter pub get
   ```
2. **Пересоберите проект:**
   ```bash
   flutter build apk --debug
   ```
3. **Запустите приложение:**
   ```bash
   flutter run
   ```

### 5. Альтернативное решение

Если проблема persists, можно использовать анонимную авторизацию для тестирования:

```dart
// В GoogleSignInService добавьте метод:
static Future<User?> signInAnonymously() async {
  try {
    final UserCredential userCredential = await _auth.signInAnonymously();
    return userCredential.user;
  } catch (e) {
    debugPrint('Ошибка анонимного входа: $e');
    rethrow;
  }
}
```

## Ожидаемый результат

После правильной настройки:
1. Нажатие на кнопку откроет стандартное окно Google Sign-In
2. Пользователь сможет выбрать аккаунт Google
3. После авторизации приложение переключится на главный экран
4. Прозрачное окно больше не будет появляться

