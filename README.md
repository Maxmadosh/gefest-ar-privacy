# GefestAR — iOS App
## ОсОО «Гефест Строй-Монтаж» · AR для АМО

---

## Структура проекта

```
GefestAR/
├── App/
│   └── GefestARApp.swift          # Точка входа @main
├── Models/
│   └── AMOObject.swift            # Модели данных + тестовые данные
├── Services/
│   └── AuthManager.swift          # Авторизация + подписки
├── Views/
│   ├── LoginView.swift            # Экран входа
│   ├── HomeView.swift             # Папки + список объектов + табы
│   ├── ObjectDetailView.swift     # ТТХ / Описание / Чертежи
│   ├── ARViewScreen.swift         # AR камера + фото/видео
│   └── SubscriptionView.swift     # Тарифы + заявка на объект
└── Resources/
    ├── *.usdz                     # 3D-модели из Shapr3D (сюда!)
    └── *.pdf                      # Чертежи
```

---

## Шаг 1 — Создать проект в Xcode

1. Xcode → **New Project** → **App**
2. Product Name: `GefestAR`
3. Interface: **SwiftUI**
4. Language: **Swift**
5. Minimum Deployment: **iOS 16.0**
6. Скопировать все `.swift` файлы в соответствующие папки

---

## Шаг 2 — Добавить разрешения в Info.plist

Добавьте эти ключи в `Info.plist`:

```xml
<!-- Камера (обязательно для AR) -->
<key>NSCameraUsageDescription</key>
<string>Необходима для просмотра объектов в дополненной реальности</string>

<!-- Микрофон (для записи видео) -->
<key>NSMicrophoneUsageDescription</key>
<string>Необходим для записи видео с места установки</string>

<!-- Галерея — сохранение -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Для сохранения фото и видео в вашу галерею</string>

<!-- Галерея — чтение (превью) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Для отображения сохранённых материалов</string>
```

---

## Шаг 3 — Добавить USDZ модели

Из Shapr3D экспортируйте каждый объект:
- Формат: **USDZ**
- Единицы: **метры** (или миллиметры — тогда в ARCoordinator поставьте `scale = 0.001`)
- Имена файлов (строго как в `AMOObject.usdzFileName`):

| Объект     | Файл         |
|------------|--------------|
| БА-24      | `BA_24.usdz` |
| БА-30      | `BA_30.usdz` |
| БДК-14     | `BDK_14.usdz`|
| МБС-КНТ-12 | `MBS_KNT_12.usdz` |
| МП-23      | `MP_23.usdz` |
| ОР-РК      | `OR_RK.usdz` |

Перетащите файлы в Xcode → `Resources/` → ✅ **Add to target: GefestAR**

---

## Шаг 4 — Добавить чертежи (PDF)

Аналогично для PDF-чертежей. Имена файлов берутся из `AMOObject.drawings[].fileName`:
- `BA24_front.pdf`, `BA24_side.pdf`, `BA24_base.pdf` и т.д.

---

## Шаг 5 — Подключить Backend (авторизация)

В `AuthManager.swift` замените заглушку на реальный API:

```swift
// POST https://api.gefest-ar.com/v1/auth/login
// Body: { "email": "...", "password": "..." }
// Response: { "token": "...", "user": {...}, "subscription": {...} }
```

Рекомендуем: **Supabase** (бесплатный tier) — готовая авторизация + база данных.

---

## Шаг 6 — Масштаб AR-модели

В `ARCoordinator.placeObject()` откорректируйте масштаб:

```swift
// Если Shapr3D экспортировал в мм:
modelEntity.scale = SIMD3<Float>(repeating: 0.001)

// Если в см:
modelEntity.scale = SIMD3<Float>(repeating: 0.01)

// Если в метрах (правильно): ничего не менять
```

---

## Шаг 7 — Подписи + бандл

В Xcode → Target → **Signing & Capabilities**:
- Team: ваш Apple Developer аккаунт
- Bundle ID: `com.gefest.GefestAR`

Capabilities добавить:
- ✅ **ARKit** (автоматически через RealityKit)

---

## Кнопка «Поделиться» — почему её нет

Мы не используем системный QuickLook для AR — вместо него собственный `ARView` через RealityKit. Поэтому системной кнопки «Поделиться» нет совсем. Пользователь может только:
- Сделать фото (одиночное нажатие шторки)
- Записать видео (долгое нажатие шторки)
Всё сохраняется напрямую в галерею.

---

## Требования

- iPhone с чипом A12+  (ARKit 3+)
- iOS 16.0+
- Xcode 15+
- Apple Developer аккаунт ($99/год) для публикации в App Store

---

## Следующие шаги

- [ ] Интеграция backend (Supabase / Firebase)
- [ ] StoreKit 2 для in-app подписок (альтернатива — счёт через email)
- [ ] Push-уведомления при активации доступа
- [ ] Загрузка USDZ с сервера (не из bundle) для обновлений
- [ ] Добавление новых объектов без обновления приложения
