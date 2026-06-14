# ShopMaps

[![Version Tracker](https://img.shields.io/github/v/release/Heidarie/ShoppingGuide?display_name=tag&sort=semver)](https://github.com/Heidarie/ShoppingGuide/releases)
[![Test Tracker](https://github.com/Heidarie/ShoppingGuide/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/Heidarie/ShoppingGuide/actions/workflows/flutter-ci.yml)

ShopMaps is a Flutter mobile app for planning grocery shopping in the order of a real store layout.

It helps you:
- define a market layout (entrance to exit category order),
- build grocery lists with categorized items,
- reuse item-to-category mapping from history,
- generate a shopping list sorted by the selected market layout,
- complete items while shopping with undo support,
- keep private data stored locally on device,
- optionally sign in to create groups and share copied grocery lists or deposit codes.
- receive one grouped push notification when another member finishes adding
  products to a shared list.

## Features

- Local-first storage (`shared_preferences`) with optional Supabase sharing
- Nine supported localizations (OS language based, fallback to English)
- iOS/Android support from one Flutter codebase
- Dark mode support (follows system appearance)
- Shopping route sorting by market layout
- Persistent item-to-category memory (future item hints)
- Quantity support (`item x quantity`)
- Undo for completed shopping items
- Shopping completion time reward message

## How It Works

1. Create a **Market layout** and define category order (e.g. Drinks -> Fruits -> Vegetables).
2. Create a **Grocery list** and add items.
3. While typing items, ShopMaps suggests known items/categories from history.
4. Press **Go shopping**, choose a grocery list and market layout.
5. ShopMaps shows a shopping list grouped and sorted by the chosen market layout.

## Getting Started

### Prerequisites

- Flutter SDK (stable)
- Xcode + CocoaPods (for iOS builds on macOS)
- Android Studio / Android SDK (for Android builds)

### Run Locally

```bash
flutter pub get
flutter run
```

ShopMaps runs without an account or cloud configuration. To enable optional
accounts and groups, follow [`docs/supabase_setup.md`](docs/supabase_setup.md).

For a public release, follow the complete operator checklist:
[`docs/production-release.md`](docs/production-release.md).

### Run On iPhone (macOS)

```bash
flutter pub get
cd ios && pod install && cd ..
flutter run
```

If iOS signing fails, configure your Apple team in Xcode (`ios/Runner.xcworkspace`) under `Signing & Capabilities`.

## Quality Checks

Run locally:

```bash
flutter analyze
flutter test
```

Validate the production configuration schema:

```bash
dart run tool/validate_production_config.dart \
  config/supabase.prod.example.json --example
```

The **Test Tracker** badge above reflects the GitHub Actions CI workflow status.

## CI / GitHub Tracking

This repository includes a GitHub Actions workflow (`.github/workflows/flutter-ci.yml`) that runs:

- `flutter pub get`
- `flutter analyze`
- `flutter test`

The **Version Tracker** badge shows the latest GitHub release tag.  
If no release is published yet, it may show no version until the first release is created.

## Project Structure (Key Files)

- `lib/main.dart` - app bootstrap, themes, localization setup
- `lib/screens/home_screen.dart` - market lists, grocery lists, shopping entry flow
- `lib/screens/grocery_list_editor_screen.dart` - grocery list editing
- `lib/screens/market_layout_editor_screen.dart` - market layout editing
- `lib/screens/go_shopping_screen.dart` - shopping mode and completion flow
- `lib/app_controller.dart` - app state and business logic
- `lib/local_store.dart` - local persistence
- `lib/cloud/` - optional Supabase account and group layer
- `supabase/migrations/` - database schema, RPC functions, and RLS policies

## Notes

- App branding name: **ShopMaps**
- Private data remains stored locally; sharing is opt-in
- Portrait orientation only
