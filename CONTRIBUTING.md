# Contributing

Thank you for helping. This page explains how to make a change that is easy to accept.

## What we ask of every change

1. Use plain English in anything a person reads. Short sentences. No jargon. If a technical word is needed, explain it in the same place.
2. Never put a password, key or personal address in the code, the docs or a test.
3. Never show an invented price. If a price is missing, show a dash.
4. Keep every table behind Row Level Security. A new table needs a policy in the same migration.
5. Make every tap target at least 44 pixels and every image or icon that carries meaning has a text label.
6. Check the phone view and the desktop view before you open a pull request.

## Where things are

1. `lib/views` holds the screens and `lib/widgets` holds the shared pieces. The look comes from `lib/core/tokens.dart`.
2. `supabase/functions` holds the server functions and `supabase/migrations` holds the database.
3. Pictures go in `assets/art`. Resize them for the web first. A background picture rarely needs to be wider than 1600 pixels.

## Running the checks

From the top folder, run these three. The same checks run on every pull request.

```bash
dart format .
flutter analyze
flutter test
```

If `dart format .` changes a file, commit the result. The check fails when a file is not formatted.

## Trying a change safely

Use a separate Supabase project for testing, never the one that holds your real collection. Put its address and key in `.env.build`, which Git ignores.

```bash
flutter run -d chrome --dart-define-from-file=.env.build
```

## Commit messages

Start with a short word that says what kind of change it is: `feat`, `fix`, `docs`, `style`, `perf`, `chore` or `db`. Then say what changed in one line.
