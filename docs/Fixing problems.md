# Fixing problems

Find what you see, then follow the steps next to it.

## "Configuration Missing" when I start the app

The app did not get your Supabase address and key.

1. Make sure `.env.build` exists in the top folder.
2. Start with `flutter run -d chrome --dart-define-from-file=.env.build`.
3. Check that the file holds `SUPABASE_URL` and `SUPABASE_ANON_KEY`, with no extra spaces.

## A game shows a dash instead of a price

The source had no price for it.

1. Open the game and press refresh.
2. Check the title. A small spelling difference can stop a match.
3. If it is still a dash, the game may not be listed at the source yet. Valora will try again after the next cache time.

## "Rate limit exceeded"

You asked for more than 60 lookups in an hour. Wait until the next hour and try again.

## Prices do not update

Prices are reused for 24 hours (disc games) or 6 hours (digital games). Press refresh on the game's page to ask the source again.

## The build fails with "IconData can't be extended"

Your Flutter is too new for the `font_awesome_flutter` package.

1. Run `flutter --version`.
2. Switch to **3.41.4**, the version this project is tested with.
3. Run `flutter clean` and `flutter pub get`, then build again.

The same pin is in `.github/workflows`, so the checks use it too.

## `flutter analyze` finds something that passed before

Different Flutter versions have different checks. Use 3.41.4 to match the project, then fix what it shows.

## The check "dart format" fails on my pull request

Run `dart format .` and commit what it changes.

## Google sign-in does nothing

1. Check that `GOOGLE_WEB_CLIENT_ID` is in `.env.build` (and `GOOGLE_IOS_CLIENT_ID` on iPhone).
2. Check that your site's address is allowed in your Google client settings.
3. Check that Google is turned on under **Authentication** in Supabase.

## The daily wishlist job answers "Unauthorized"

That is correct when the secret is missing. Send the header `x-cron-secret` with the same value as your `CRON_SECRET`.

## Still stuck

Open an issue and tell us what you expected, what happened, and on which screen. Please do not paste keys, passwords or links that contain a token.

Back to [Getting started](Getting%20started.md).
