# Master.tj — клиентское приложение

Flutter-приложение **Master.tj** для клиентов: поиск мастеров, заказ услуг, рейтинги и отзывы. Проект находится в папке `masterchas_app` внутри репозитория `Masater.tj.ff`.

---

## Содержание

- [О проекте](#о-проекте)
- [Технологии](#технологии)
- [Что реализовано](#что-реализовано)
- [Пользовательский сценарий](#пользовательский-сценарий)
- [Маршруты](#маршруты)
- [Структура файлов](#структура-файлов)
- [Запуск проекта](#запуск-проекта)
- [Дизайн и цвета](#дизайн-и-цвета)
- [Что ещё заглушка](#что-ещё-заглушка)
- [Планы развития](#планы-развития)

---

## О проекте

**Master.tj** — маркетплейс услуг, где клиенты находят мастеров, а специалисты предлагают свои услуги. Текущая версия приложения содержит:

- анимированный splash-экран;
- выбор роли (клиент / мастер);
- онбординг для клиента из 4 экранов «Как это работает?»;
- базовую авторизацию (демо);
- дизайн-систему и UI-компоненты для дальнейшей разработки.

Архитектура: **feature-first** (по фичам) + общий слой `core`.

---

## Технологии

| Технология | Назначение |
|------------|------------|
| **Flutter** 3.5+ | UI для Web, Android, iOS |
| **Dart** | Язык приложения |
| **flutter_riverpod** | Управление состоянием |
| **go_router** | Навигация и редиректы |
| **google_fonts** | Шрифт Inter |
| **flutter_lucide** | Иконки Lucide |
| **flutter_secure_storage** | Безопасное хранение токена |

---

## Что реализовано

### 1. Splash-экран (`/splash`)

**Файл:** `lib/features/splash/presentation/splash_screen.dart`

- Зелёный фон `#57B55E`
- Текст **Master.tj** и **для клиентов** (белый, Inter)
- 12 outline-иконок инструментов вокруг текста (белые, волновая анимация)
- Индикатор из 3 пульсирующих точек
- Автовход по сохранённому токену (`tryAutoLogin`)
- Плавное исчезновение (fade-out ~700 мс) перед переходом
- Минимальное время показа ~4.2 с

### 2. Выбор роли (`/role`)

**Файл:** `lib/features/role/presentation/role_selection_screen.dart`

Экран разделён на две половины:

| Верх (зелёный) | Низ (тёмно-синий) |
|----------------|-------------------|
| **Я клиент** | **Я мастер** |
| Иконка: пользователь + лупа | Иконка: молоток + ключ |
| Фоновые «боке»-круги | Фоновые «боке»-круги |
| Кнопка-стрелка | Кнопка-стрелка |

- Вся половина экрана кликабельна
- **Я клиент** → онбординг `/client/onboarding`
- **Я мастер** → экран входа `/login` (пока заглушка)

### 3. Онбординг клиента (`/client/onboarding`)

**Файл:** `lib/features/onboarding/presentation/client_onboarding_screen.dart`

4 страницы с заголовком **«Как это работает ?»**, свайпом и индикатором точек:

| № | Заголовок | Иконка |
|---|-----------|--------|
| 1 | Мастер рядом с вами | Ящик с инструментами (CustomPaint) |
| 2 | Рейтинг и отзывы | Человек, график, стрелка к мишени |
| 3 | Оформите заявку на услугу | Два человека, стрелки, галочка в чате |
| 4 | Сопоставляйте стоимость | Три человека, сердце, монета $ |

**Кнопка внизу:**

- Страницы 1–3: **«Пропустить»** — переход на следующую страницу
- Страница 4: **«Начать»** — переход на `/login`

### 4. Авторизация (`/login`)

**Файл:** `lib/features/auth/presentation/login_screen.dart`

- Заглушка с кнопкой **«Войти (демо)»**
- Сохраняет токен в secure storage и переходит на главную

**Связанные файлы:**

- `lib/features/auth/providers/auth_provider.dart` — логика входа/выхода
- `lib/features/auth/models/auth_state.dart` — модель состояния
- `lib/core/storage/secure_storage_service.dart` — работа с токеном
- `lib/core/storage/secure_storage_provider.dart` — Riverpod-провайдер

### 5. Главная (`/`)

**Файл:** `lib/features/home/presentation/home_screen.dart`

- Заглушка с текстом «Главная»
- Кнопка **«Выйти»** → возврат на `/role`

### 6. Роутинг и защита маршрутов

**Файл:** `lib/core/router/app_router.dart`

- Fade-переходы между экранами (~550 мс)
- Редиректы в зависимости от `authProvider`
- Автообновление при смене состояния авторизации

### 7. Дизайн-система (`lib/core/`)

| Папка / файл | Описание |
|--------------|----------|
| `theme/app_colors.dart` | Цвета светлой и тёмной темы |
| `theme/app_typography.dart` | Типографика Inter |
| `theme/app_theme.dart` | Material-тема |
| `theme/app_spacing.dart` | Отступы |
| `theme/app_radius.dart` | Скругления |
| `theme/app_shadows.dart` | Тени |
| `widgets/buttons/app_button.dart` | Кнопка |
| `widgets/inputs/app_text_field.dart` | Поле ввода |
| `widgets/cards/app_card.dart` | Карточка |
| `widgets/badges/app_badge.dart` | Бейдж |
| `widgets/navigation/app_bottom_nav.dart` | Нижняя навигация (5 вкладок) |
| `widgets/feedback/app_loader.dart` | Лоадер |
| `widgets/feedback/app_modal.dart` | Модальное окно |
| `widgets/feedback/app_toast.dart` | Toast-уведомления |

### 8. Скрипты запуска

| Файл | Описание |
|------|----------|
| `run.sh` | Запуск в Chrome (Git Bash / Linux / macOS) |
| `run.bat` | Запуск в Chrome (Windows CMD) |
| `../run.sh` | Запуск из корня репозитория |
| `../run.bat` | Запуск из корня репозитория |

Скрипты ищут Flutter в `PATH`, затем в `FLUTTER_ROOT`, затем в типичных путях установки.

### 9. Инструменты разработки

| Файл | Описание |
|------|----------|
| `tools/splash_capture.py` | Скриншоты splash-экрана с задержками |
| `tools/splash_capture.mjs` | Node-версия скрипта захвата splash |
| `tools/package.json` | Зависимости для Node-скриптов |
| `splash_capture_output/` | Папка с сохранёнными скриншотами splash |

### 10. Тесты

| Файл | Описание |
|------|----------|
| `test/widget_test.dart` | Проверка старта приложения на splash-экране |

---

## Пользовательский сценарий

```
Splash (анимация)
    │
    ├─ есть токен ──────────────► Главная (/)
    │
    └─ нет токена ──────────────► Выбор роли (/role)
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
              Я клиент                            Я мастер
                    │                                   │
                    ▼                                   ▼
         Онбординг (4 страницы)                  Вход (/login)
                    │
         Пропустить × 3 / Начать
                    │
                    ▼
              Вход (/login)
                    │
              Войти (демо)
                    │
                    ▼
              Главная (/)
```

---

## Маршруты

| Путь | Экран | Доступ |
|------|-------|--------|
| `/splash` | Splash | Всегда при старте |
| `/role` | Выбор роли | Без авторизации |
| `/client/onboarding` | Онбординг клиента | Без авторизации |
| `/login` | Вход | Без авторизации |
| `/` | Главная | Только с авторизацией |

---

## Структура файлов

```
Masater.tj.ff/
├── run.sh                          # Запуск из корня репозитория
├── run.bat
└── masterchas_app/
    ├── pubspec.yaml                # Зависимости Flutter
    ├── analysis_options.yaml       # Правила линтера
    ├── run.sh                      # Запуск приложения
    ├── run.bat
    ├── README.md                   # Этот файл
    │
    ├── lib/
    │   ├── main.dart               # Точка входа, MaterialApp.router
    │   │
    │   ├── core/
    │   │   ├── router/
    │   │   │   └── app_router.dart
    │   │   ├── storage/
    │   │   │   ├── secure_storage_service.dart
    │   │   │   └── secure_storage_provider.dart
    │   │   ├── theme/
    │   │   │   ├── app_colors.dart
    │   │   │   ├── app_typography.dart
    │   │   │   ├── app_theme.dart
    │   │   │   ├── app_spacing.dart
    │   │   │   ├── app_radius.dart
    │   │   │   └── app_shadows.dart
    │   │   └── widgets/
    │   │       ├── buttons/app_button.dart
    │   │       ├── inputs/app_text_field.dart
    │   │       ├── cards/app_card.dart
    │   │       ├── badges/app_badge.dart
    │   │       ├── navigation/app_bottom_nav.dart
    │   │       └── feedback/
    │   │           ├── app_loader.dart
    │   │           ├── app_modal.dart
    │   │           └── app_toast.dart
    │   │
    │   └── features/
    │       ├── splash/
    │       │   └── presentation/splash_screen.dart
    │       ├── role/
    │       │   └── presentation/role_selection_screen.dart
    │       ├── onboarding/
    │       │   └── presentation/client_onboarding_screen.dart
    │       ├── auth/
    │       │   ├── models/auth_state.dart
    │       │   ├── providers/auth_provider.dart
    │       │   └── presentation/login_screen.dart
    │       └── home/
    │           └── presentation/home_screen.dart
    │
    ├── test/
    │   └── widget_test.dart
    │
    ├── tools/
    │   ├── splash_capture.py
    │   ├── splash_capture.mjs
    │   └── package.json
    │
    ├── android/                    # Платформа Android
    ├── ios/                        # Платформа iOS
    └── splash_capture_output/      # Скриншоты splash для проверки
```

---

## Запуск проекта

### Требования

- Flutter SDK 3.5+
- Chrome (для веб-запуска)

### Первый запуск

```bash
cd masterchas_app
flutter pub get
./run.sh
```

Из корня репозитория:

```bash
./run.sh
```

Windows (CMD):

```bat
cd masterchas_app
flutter pub get
run.bat
```

### Если `flutter` не найден

```bash
export FLUTTER_ROOT="/c/path/to/flutter"   # Git Bash
./run.sh
```

### Ручной запуск

```bash
cd masterchas_app
flutter run -d chrome
```

### Горячие клавиши (во время `flutter run`)

| Клавиша | Действие |
|---------|----------|
| `r` | Hot reload |
| `R` | Hot restart |
| `q` | Выход |

### Проблема: «Waiting for startup lock»

```bash
taskkill //F //IM dart.exe
rm -f /c/Users/HP/flutter/bin/cache/lockfile
```

Затем снова `./run.sh`.

---

## Дизайн и цвета

| Элемент | Цвет |
|---------|------|
| Splash / акцент онбординга | `#57B55E` |
| Панель «Я мастер» | `#1C2438` |
| Фон онбординга | `#FFFFFF` |
| Текст заголовков | `#111827` |
| Текст описания | `#6B7280` |
| Неактивные точки пагинации | `#D1D5DB` |
| Шрифт | Inter (Google Fonts) |

---

## Что ещё заглушка

Следующие части созданы как основа, но требуют доработки:

- **Экран входа** — демо-кнопка без реального API
- **Главная** — пустая страница
- **Путь мастера** — сразу на login, без своего онбординга
- **Нижняя навигация** — компонент есть, на экранах не подключён
- **Реальный backend** — не подключён

---

## Планы развития

- [ ] Реальная авторизация (телефон, SMS, OAuth)
- [ ] Онбординг для мастера
- [ ] Главная с поиском и фильтрами
- [ ] Каталог услуг и профили мастеров
- [ ] Чат и оформление заявок
- [ ] Рейтинги и отзывы
- [ ] Подключение API Master.tj

---

## Версия

- **Приложение:** 1.0.0+1
- **Пакет:** `masterchas_app`
- **Платформы:** Web (Chrome), Android, iOS
