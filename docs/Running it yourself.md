# Running it yourself

This page takes you from nothing to your own copy of Valora, in the order you need things. Skip it if you only want to use the website.

## What you need

1. [Flutter](https://docs.flutter.dev/get-started/install). This project is built and tested with version **3.41.4**. Newer versions may fail to build, see [Fixing problems](Fixing%20problems.md).
2. A free [Supabase](https://supabase.com) project.
3. The [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started), to set up the database and the price lookups.
4. Chrome, to run the web version while you work.

## Step 1: Get the code

```bash
git clone https://github.com/Hikki-dev/valora.git
cd valora
flutter pub get
```

## Step 2: Set up the database

Link the folder to your Supabase project and apply the migrations. They run in date order and build every table, every Row Level Security rule and the price history.

```bash
supabase link --project-ref your-project-ref
supabase db push
```

Never skip a migration. The security rules are part of them.

## Step 3: Add the secrets for the price lookups

These live in Supabase, not in the code.

| Name | What it is for |
|---|---|
| `EBAY_CLIENT_ID` and `EBAY_CLIENT_SECRET` | Looking up PlayStation disc prices for free, from eBay listings (see below) |
| `PRICE_CHARTING_TOKEN` | Optional. Paid, more exact disc prices from PriceCharting. If it is set, it is used instead of eBay |
| `STEAM_API_KEY` | Importing a Steam library |
| `CRON_SECRET` | A long random value that protects the daily wishlist job |

```bash
supabase secrets set EBAY_CLIENT_ID=... EBAY_CLIENT_SECRET=... STEAM_API_KEY=... CRON_SECRET=...
```

### Getting the free eBay keys

Disc prices need one of two sources. PriceCharting is exact but costs money. eBay is free.

1. Join the eBay Developers Program at https://developer.ebay.com (it is free).
2. Create an application and open its **Production** keys.
3. eBay may ask you to either run a "Marketplace Account Deletion" web address or to apply for an **exemption** because you do not store eBay user data. Valora stores no eBay user data, so choose the exemption. The wording on eBay's screen changes now and then, so follow what it shows.
4. Copy the **App ID (Client ID)** and the **Cert ID (Client Secret)** into the two secrets above.

Valora then searches eBay for used and new copies of the game, ignores listings that are not a copy (digital codes, empty cases, lots), and uses the middle price. That is what sellers **ask**, not what games sold for, so it is rougher than PriceCharting. A game with fewer than three matching listings gets a dash instead of a guess.

## Step 4: Deploy the price lookups

```bash
supabase functions deploy
```

This publishes `fetch-price`, `search-games`, `lookup-barcode`, `sync-steam`, `check-price-alerts` and `ping`.

Then schedule `check-price-alerts` once a day, and send the `x-cron-secret` header with your `CRON_SECRET`. Without the header it answers "Unauthorized", on purpose.

## Step 5: Tell the app where your project is

Create a file called `.env.build` in the top folder. Git ignores it, so it stays on your computer.

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-publishable-key"
}
```

The publishable key is on your project's **API settings** page. Use that one. Never put the **service role** key here.

## Step 6: Run it

```bash
flutter run -d chrome --dart-define-from-file=.env.build
```

Without the two values, the app shows a **Configuration Missing** page instead of starting. That is on purpose, so you notice straight away.

For Google sign-in, also add `GOOGLE_WEB_CLIENT_ID` (and `GOOGLE_IOS_CLIENT_ID` on iPhone) to `.env.build`.

## Step 7: Check your changes

```bash
dart format .
flutter analyze
flutter test
```

These are the same three checks that run on every pull request.

## Step 8: Put it on the web

The website is hosted on Vercel. `vercel.json` already sets the build command, the output folder and the security headers.

1. Import the repository in Vercel.
2. Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` as environment variables.
3. Push to GitHub. Every branch gets its own preview, and `main` is the live site.

To build the web version yourself the same way:

```bash
./scripts/build.sh --wasm
```

## What happens when you push to `main`

1. **Valora CI/CD** checks formatting, analyzes, tests and builds the web version.
2. **Android Release Build** raises the version number and publishes an APK on the Releases page.

Changes that only touch the docs do not publish an APK.

Back to [Getting started](Getting%20started.md), or on to [Design](Design.md).
