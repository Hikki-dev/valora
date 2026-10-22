# Valora

[![Valora CI/CD](https://github.com/Hikki-dev/valora/actions/workflows/flutter_cicd.yml/badge.svg)](https://github.com/Hikki-dev/valora/actions/workflows/flutter_cicd.yml)
[![Flutter](https://img.shields.io/badge/built%20with-Flutter-02569B)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/backend-Supabase-3ECF8E)](https://supabase.com)

Find out what your game collection is worth, and watch it change.

<p align="center"><img src="docs/images/demo.gif" alt="The Valora sign-in page on a computer, then on a phone, then the create account form on a phone" width="100%"></p>

<p align="center"><sub>The sign-in page on a computer and on a phone. Click a picture further down to see it full size.</sub></p>

Add the games you own, physical or digital. Valora shows what each one sells for today, what you paid, and how your whole shelf adds up. It works in the browser and on your phone.

You do not need to know anything about prices or investing. Everything is explained in plain words on the way.

## On this page

* [What you get](#what-you-get): the main parts of the app
* [How a price gets to your screen](#how-a-price-gets-to-your-screen)
* [Before you start](#before-you-start): what you need to run it yourself
* [Run it](#run-it): on your computer, then on the web
* [Your privacy and safety](#your-privacy-and-safety)
* [Look and feel](#look-and-feel): the Midnight Manga design, phone and desktop
* [Project layout](#project-layout)
* [Help and more reading](#help-and-more-reading)
* [Legal and responsibility](#legal-and-responsibility)

## What you get

| Part | What it does |
|---|---|
| **Home** | Your collection's total value, how it moved, and your most valuable games |
| **Library** | Every game you own. Search, sort, and switch between a grid and a list |
| **Game page** | The price range over time, the value for each condition, and what you paid |
| **Wishlist** | Games you want, with a target price. It tells you when a game reaches it |
| **Insights** | Where your money is: by console, by value, by how rare a game is |
| **Steam sync** | Brings in your Steam library in one tap |
| **Barcode scanner** | Point your phone at a boxed game to add it |
| **Share a snapshot** | A clean picture of your ten most valuable games to post |
| **Settings** | Light or dark mode, your currency, and a switch to hide the numbers |

When there is no price for a game, Valora shows a dash. It never shows a made up number.

## How a price gets to your screen

1. You add a game by searching, scanning its barcode, or syncing Steam.
2. A small server function (a Supabase Edge Function) looks up the current market price.
3. The price is saved with the date, so the app can draw a history instead of one number.
4. Your device only has to show it, so it stays fast and does not drain the battery.

Prices are cached for a while so the same game is not looked up again and again: 6 hours for digital games and 24 hours for physical ones.

## Before you start

You need three things:

1. [Flutter](https://docs.flutter.dev/get-started/install) (stable channel).
2. A free [Supabase](https://supabase.com) project. This is where your data lives.
3. Chrome, to run the web version while you work.

## Run it

```bash
git clone https://github.com/Hikki-dev/valora.git
cd valora
flutter pub get
```

Create a file called `.env.build` in the top folder. It is ignored by Git, so it never leaves your computer:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-publishable-key"
}
```

Then start the app:

```bash
flutter run -d chrome --dart-define-from-file=.env.build
```

Without those two values the app shows a "Configuration Missing" page instead of starting. That is on purpose.

To build the web version the way the website does:

```bash
./scripts/build.sh --wasm
```

The database is set up by the files in `supabase/migrations`. The price and barcode lookups live in `supabase/functions`.

## Your privacy and safety

* **Only you can see your games.** Every table is locked with Row Level Security, so one person can never read another person's collection.
* **Your password never reaches Valora.** Google sign-in uses the standard ID token check.
* **Secrets stay out of the code.** The keys are added when the app is built and are never stored in the repository.
* **No selling of data.** Your library stays between you and your account.
* **Safe connections.** All traffic uses HTTPS, and the website sends security headers (see `vercel.json`).

To report a problem privately, read [SECURITY.md](SECURITY.md).

## Look and feel

The design is called **Midnight Manga**: bold outlines, hard shadows and comic panels, in a light theme by default with a dark one you can switch to.

* On a **computer** (900 pixels wide or more) the sign-in page uses a landscape picture beside the form.
* On a **phone** the sign-in page uses a portrait picture behind the form, with a large Valora logo at the top.
* The loading screen shows its three comic panels on larger screens and a clean logo on a phone.

<a href="docs/images/login-desktop.png"><img src="docs/images/login-desktop.png" alt="Sign-in page on a computer: comic art on the left, the sign-in form on the right" width="100%"></a>

On a computer, the left side shows a landscape picture, the Valora name and the three comic panels.

<p align="center"><a href="docs/images/login-mobile.png"><img src="docs/images/login-mobile.png" alt="Sign-in page on a phone: a large Valora logo above the sign-in form, on a portrait comic background" width="320"></a></p>

On a phone, a large Valora logo sits above the form. The comic panels are left out so the form comes first.

The pictures are in `assets/art`. They are sized for the web, so the page stays quick to open.

## Project layout

| Folder | What is in it |
|---|---|
| `lib/views` | The screens: auth, home, collections, wishlists, onboarding |
| `lib/widgets` | Shared pieces: the comic style, loader, forms, app shell |
| `lib/controllers`, `lib/repositories`, `lib/services` | Sign-in, data access and background jobs |
| `supabase/functions` | Edge Functions for prices, barcodes, Steam sync and price alerts |
| `supabase/migrations` | The database, step by step |
| `test` | Unit tests for prices, currencies and platforms |
| `scripts` | Build and version helpers |

## Help and more reading

* [CHANGELOG.md](CHANGELOG.md): what changed in each version, in plain words
* [CONTRIBUTING.md](CONTRIBUTING.md): how to make a change that is easy to accept
* [SECURITY.md](SECURITY.md): how to report a security problem

## Legal and responsibility

Prices are estimates from public market data. They are not an offer to buy or sell, and not financial advice. What a game really sells for depends on the buyer, the condition and the day.

Game names, console names and logos belong to their owners. Valora is not made by or connected to them.

The comic pictures in `assets/art` are artwork from third parties. Make sure you are allowed to use them before you publish your own copy of this project.

## Contributing

Pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) first. It is short.

## Licence

MIT. See [LICENSE](LICENSE).

---

Made for collectors, by a collector.
