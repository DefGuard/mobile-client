# Defguard mobile client

## Getting Started

This is a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Database and migrations

We use [drift](https://drift.simonbinder.eu/) persistence library with [SQLite](https://sqlite.org/index.html)
database. The model is defined in `lib/data/db/database.dart`.

When changing the schema:

1. Make changes to the model in `database.dart` file.
2. Bump schema version in `class AppDatabase`.
3. Generate migrations and tests:

```bash
flutter pub run drift_dev make-migrations
```

4. Add your migration step to `AppDatabase` `onUpgrade`.
5. Run the tests:

```bash
flutter test
```
