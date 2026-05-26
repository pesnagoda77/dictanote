# DictaNote — IAP Integration Guide

## Сравнение: Adapty vs raw in_app_purchase

### Adapty SDK

**Плюсы:**
- Быстрая интеграция (4-6 часов)
- Серверная валидация чеков из коробки
- No-code paywall builder (создаём экран покупки без кода)
- A/B тестирование цен без обновления приложения
- Аналитика по подпискам (конверсии, отток, LTV)
- Поддержка StoreKit 2 (iOS) и Play Billing Library 8 (Android)
- Обработка grace period, billing retry, refunds
- Бесплатный тариф (до $10k MRR)

**Минусы:**
- Платный после $10k MRR (~$300/мес)
- Зависимость от стороннего сервиса
- Нужен API ключ

**Цена:** Бесплатно до $10k MRR, потом ~$300/мес

### raw in_app_purchase (официальный плагин Flutter)

**Плюсы:**
- Полностью бесплатно
- Полный контроль над кодом
- Нет зависимости от сторонних сервисов
- Flutter team поддерживает

**Минусы:**
- Дольше интеграция (8-12 часов)
- Нужен свой сервер для валидации чеков
- Нужно самому обрабатывать подписки, grace period, refunds
- Нет аналитики из коробки
- Нет A/B тестирования
- Нет no-code paywall

**Цена:** $0, но нужен сервер (~$5-20/мес)

---

## Рекомендация для DictaNote

**Выбор: Adapty (бесплатный тариф)**

**Причины:**
1. Быстрее выйти на рынок (4-6 часов vs 8-12)
2. Нет серверных затрат на старте
3. Валидация чеков из коробки (безопасность)
4. A/B тестирование поможет найти оптимальную цену
5. До $10k MRR — бесплатно, а это ~1000 продаж по $10

**Когда переходить на raw:**
- Когда MRR > $10k (экономия на комиссии Adapty)
- Когда нужен полный контроль
- Когда есть ресурсы на свой сервер

---

## План интеграции Adapty

### Шаг 1: Подготовка (30 мин)
- Создать аккаунт Adapty (adapty.io)
- Получить API ключ
- Настроить продукты в App Store Connect и Google Play Console

### Шаг 2: Интеграция SDK (2 часа)
- Добавить зависимость `adapty_flutter`
- Инициализировать SDK в `main.dart`
- Создать обработчик покупок

### Шаг 3: Paywall (2 часа)
- Создать экран покупки в Adapty no-code builder
- Или сделать свой Flutter-экран
- Подключить к Adapty SDK

### Шаг 4: Тестирование (2 часа)
- Тестовые покупки в sandbox
- Проверка валидации чеков
- Проверка восстановления покупок

### Итого: ~6 часов

---

## Код: Базовая интеграция Adapty

```dart
import 'package:adapty_flutter/adapty_flutter.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  Future<void> init() async {
    await Adapty().activate(
      configuration: AdaptyConfiguration(apiKey: 'YOUR_API_KEY')
        ..withLogLevel(AdaptyLogLevel.debug),
    );
  }

  Future<bool> isProUser() async {
    final profile = await Adapty().getProfile();
    return profile.accessLevels['premium']?.isActive ?? false;
  }

  Future<void> makePurchase() async {
    final paywall = await Adapty().getPaywall(placementId: 'main');
    final products = await Adapty().getPaywallProducts(paywall: paywall);
    
    if (products.isNotEmpty) {
      final result = await Adapty().makePurchase(product: products.first);
      // Обработка результата
    }
  }

  Future<void> restorePurchases() async {
    await Adapty().restorePurchases();
  }
}
```

---

## Продукты для DictaNote

**Вариант 1: Разовая покупка PRO**
- Цена: $4.99 (или локальный эквивалент)
- Включает: все функции, без рекламы, экспорт всех форматов
- Lifetime access

**Вариант 2: Подписка (опционально)**
- Monthly: $2.99/мес
- Yearly: $19.99/год (экономия 44%)
- Включает: облачное хранение, синхронизация, AI-улучшения

**Рекомендация:** Начать с разовой покупки PRO. Проще, понятнее пользователю, быстрее интегрировать.

---

## Документация

- Adapty Flutter SDK: https://github.com/adaptyteam/AdaptySDK-Flutter
- Adapty Docs: https://docs.adapty.io/
- App Store Connect: https://appstoreconnect.apple.com
- Google Play Console: https://play.google.com/console

---

## Статус

- **Решение:** Adapty (бесплатный тариф)
- **Тип покупки:** Разовая PRO ($4.99)
- **Срок интеграции:** 4-6 часов
- **Блокер:** APK должен быть рабочим
- **Дата:** 2026-05-26

