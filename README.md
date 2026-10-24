# Valora

[![Valora CI/CD](https://github.com/Hikki-dev/valora/actions/workflows/flutter_cicd.yml/badge.svg)](https://github.com/Hikki-dev/valora/actions/workflows/flutter_cicd.yml)
[![Licence: MIT](https://img.shields.io/github/license/Hikki-dev/valora)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/Hikki-dev/valora?label=latest%20build&color=ffc247)](https://github.com/Hikki-dev/valora/releases/latest)
[![Live site](https://img.shields.io/badge/live-site-15121f)](https://valora-umber.vercel.app)
[![Flutter](https://img.shields.io/badge/built%20with-Flutter-02569B)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/backend-Supabase-3ECF8E)](https://supabase.com)

Find out what your game collection is worth, and watch it change.

<p align="center"><img src="docs/images/demo.gif" alt="The Valora sign-in page on a computer, then on a phone, then the create account form on a phone" width="100%"></p>

<p align="center"><sub>The sign-in page on a computer and on a phone. <b><a href="https://valora-umber.vercel.app">Open the live site</a></b> to try it yourself.</sub></p>

Add the games you own, physical or digital. Valora looks up what each one sells for today, keeps the price with its date, and adds your whole shelf up for you. It works in the browser and on your phone.

You do not need to know anything about prices or investing. Everything is explained in plain words on the way.

## On this page

* [What you get](#what-you-get): the parts of the app, in one table
* [How everything fits together](#how-everything-fits-together): one game, from adding it to seeing its price
* [Try it first](#try-it-first): the live site and Android builds
* [The app, step by step](#the-app-step-by-step)
  * [1. Sign in](#1-sign-in)
  * [2. Add a game](#2-add-a-game)
  * [3. Home](#3-home)
  * [4. Library](#4-library)
  * [5. A game's page](#5-a-games-page)
  * [6. Wishlist](#6-wishlist)
  * [7. Insights](#7-insights)
  * [8. Share and settings](#8-share-and-settings)
* [Where prices come from](#where-prices-come-from)
* [Your privacy and safety](#your-privacy-and-safety)
* [Run your own copy](#run-your-own-copy)
* [Look and feel](#look-and-feel)
* [Help and more reading](#help-and-more-reading)
* [Legal and responsibility](#legal-and-responsibility)

## What you get

| Part | What it does |
|---|---|
| **Home** | The total value of your collection, how it moved, and your most valuable games |
| **Library** | Every game you own. Search, sort, and switch between a grid and a list |
| **Game page** | Its value, a price chart, a card for each condition, and what you paid |
| **Wishlist** | Games you want, with a target price. It shows you when a game reaches it |
| **Insights** | How many games are priced, the average, your top game, and a ranked list |
| **Steam sync** | Brings in your Steam library in one go |
| **Barcode scanner** | Point your phone at a boxed game to add it |
| **Share a snapshot** | A clean picture of your ten most valuable games |
| **Settings** | Light or dark mode, US dollars or rupees, and a switch to hide the numbers |

When a game has no price, Valora shows a dash. It never shows a made up number.

## How everything fits together

You add a game, and Valora does the rest. The app saves it in a locked database, asks a small server function for the price, and saves that price with today's date. Every day a job marks the wishlist games that reached your target.

<p align="center"><a href="docs/images/how-it-fits.svg"><img src="docs/images/how-it-fits.svg" alt="Diagram: you use the Valora app, which saves to a locked database and asks Edge Functions for prices from PriceCharting, the Steam store, CheapShark and UPCitemdb" width="100%"></a></p>

Click the picture to see it full size. The full story, part by part, is in [How everything fits](docs/How%20everything%20fits.md).

## Try it first

* **[Open the live site](https://valora-umber.vercel.app).** Sign in with Google or an email address. It works on phones too.
* **[Get an Android build](https://github.com/Hikki-dev/valora/releases/latest).** Every change to `main` that touches the app publishes a new APK.

## The app, step by step

Each screen explains itself. This is the order you will meet them. The pictures below show the real screens filled with made-up demo games (the games and prices are samples, not a real collection). Game covers are left as plain title tiles in these pictures. The same walk through, with more detail, is in [Getting started](docs/Getting%20started.md).

### 1. Sign in

<p align="center"><img src="docs/images/login-mobile.png" alt="Sign-in page on a phone: a large Valora logo above the sign-in form, on a portrait comic background" width="300"></p>

Choose **Continue with Google**, or use an email and a password. Valora never sees your Google password.

### 2. Add a game

Search for it, scan its barcode, or sync your Steam library. For a disc game, choose how it is kept: **Loose**, **CIB** (complete in box), **Boxed** or **New**, because a sealed game is worth more than a loose disc. Add what you paid, if you like, and Valora will show whether you are up or down.

### 3. Home

<p align="center"><a href="docs/images/home-desktop.png"><img src="docs/images/home-desktop.png" alt="Home: total value, a rising price chart, value by platform and the most valuable games on a computer" width="100%"></a></p>

<p align="center"><img src="docs/images/home-mobile.png" alt="Home: total value, a rising price chart, value by platform and the most valuable games on a phone" width="300"></p>

Home answers one question: what is my collection worth today? You get the total, a chart of how it moved, and your most valuable games. A game with no price is left out of the total, so the total is never wrong in secret.

### 4. Library

<p align="center"><a href="docs/images/library-desktop.png"><img src="docs/images/library-desktop.png" alt="Library: search box, platform filters, sort, and a grid of game cards each with a price on a computer" width="100%"></a></p>

<p align="center"><img src="docs/images/library-mobile.png" alt="Library: search box, platform filters, sort, and a grid of game cards each with a price on a phone" width="300"></p>

Every game in one place. Search waits until you stop typing, so it stays smooth with thousands of games. Sort by value, name or most recently added, and switch between covers and a list.

### 5. A game's page

The game's value, what you paid, a price chart that fills in day by day, and a card for each condition. You can refresh the price, edit the game, or delete it. A delete can be undone for a few seconds.

### 6. Wishlist

<p align="center"><a href="docs/images/wishlist-desktop.png"><img src="docs/images/wishlist-desktop.png" alt="Wishlist: games with a target price, a current price and a "Target hit" tag on a computer" width="100%"></a></p>

<p align="center"><img src="docs/images/wishlist-mobile.png" alt="Wishlist: games with a target price, a current price and a "Target hit" tag on a phone" width="300"></p>

Add a game you want and set a target price. When the market price drops to it, the game is marked as hit, so you know it is time to buy.

### 7. Insights

<p align="center"><a href="docs/images/insights-desktop.png"><img src="docs/images/insights-desktop.png" alt="Insights: three number cards and a ranked list of the most valuable games on a computer" width="100%"></a></p>

<p align="center"><img src="docs/images/insights-mobile.png" alt="Insights: three number cards and a ranked list of the most valuable games on a phone" width="300"></p>

Three numbers (games with a price, the average, your top game) and a ranked list from most to least valuable. It tells you how many games have no price yet.

### 8. Share and settings

**Share** makes a clean picture of your ten most valuable games. In Settings you pick light or dark mode, US dollars or Sri Lankan rupees, and can **hide values** to show someone your shelf without the numbers.

## Where prices come from

Disc games are looked up at PriceCharting, Steam games at the Steam store, and other digital games at CheapShark. Prices are saved with their date, and reused for 24 hours (disc) or 6 hours (digital), so the app stays fast.

A price is an estimate, not an offer. The details, including what happens when there is no price, are in [Where prices come from](docs/Where%20prices%20come%20from.md).

## Your privacy and safety

* **Only you can see your games.** Every table is locked with Row Level Security, so one person can never read another person's collection.
* **Your Google password never reaches Valora.** Sign-in uses Google's signed ID token.
* **Secret keys stay out of the code.** The app only holds the publishable key, which is meant to be public. Powerful keys live in the server's secret store.
* **No selling of data and no adverts.**
* **Safe connections.** All traffic uses HTTPS, and the website sends security headers (see `vercel.json`).

The full picture is in [Your privacy and data](docs/Your%20privacy%20and%20data.md). To report a problem privately, read [SECURITY.md](SECURITY.md).

## Run your own copy

You need [Flutter](https://docs.flutter.dev/get-started/install) **3.41.4**, a free [Supabase](https://supabase.com) project and the Supabase CLI.

```bash
git clone https://github.com/Hikki-dev/valora.git
cd valora
flutter pub get
```

Put your project's address and publishable key in a file called `.env.build`. Git ignores it, so it stays on your computer:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-publishable-key"
}
```

```bash
flutter run -d chrome --dart-define-from-file=.env.build
```

Without those two values the app shows a "Configuration Missing" page instead of starting. That is on purpose.

Setting up the database, the secrets and the price lookups, and putting it on the web, are covered one step at a time in [Running it yourself](docs/Running%20it%20yourself.md). Before you push a change, run:

```bash
dart format .
flutter analyze
flutter test
```

## Look and feel

The design is called **Midnight Manga**: bold outlines, hard shadows and comic panels, light by default with a dark theme you can switch to.

<a href="docs/images/login-desktop.png"><img src="docs/images/login-desktop.png" alt="Sign-in page on a computer: comic art on the left, the sign-in form on the right" width="100%"></a>

On a computer (900 pixels wide or more) the left side shows a landscape picture, the Valora name and three comic panels. On a phone, a large Valora logo sits above the form, and the panels are left out so the form comes first. The rules behind the look are in [Design](docs/Design.md).

## Help and more reading

| Page | What it answers |
|---|---|
| [Getting started](docs/Getting%20started.md) | How do I use each screen? |
| [How everything fits](docs/How%20everything%20fits.md) | What are the parts, and how do they work together? |
| [Where prices come from](docs/Where%20prices%20come%20from.md) | Where does a price come from, and how fresh is it? |
| [Your privacy and data](docs/Your%20privacy%20and%20data.md) | What is kept, and who can see it? |
| [Running it yourself](docs/Running%20it%20yourself.md) | How do I set up my own copy? |
| [Design](docs/Design.md) | Why does it look like this, and what are the rules? |
| [FAQ](docs/FAQ.md) | Quick answers |
| [Fixing problems](docs/Fixing%20problems.md) | Something does not look right |
| [CHANGELOG](CHANGELOG.md) | What changed in each version |

## Legal and responsibility

Prices are estimates from public market data. They are not an offer to buy or sell, and not financial advice. What a game really sells for depends on the buyer, the condition and the day.

Game names, console names and logos belong to their owners. Valora is not made by or connected to them.

The comic pictures in `assets/art` are artwork from third parties. Make sure you are allowed to use them before you publish your own copy of this project.

## Contributing

Pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) first. It is short.

## Credits

Prices come from [PriceCharting](https://www.pricecharting.com), the [Steam store](https://store.steampowered.com) and [CheapShark](https://www.cheapshark.com). Barcodes are looked up with [UPCitemdb](https://www.upcitemdb.com). Built with [Flutter](https://flutter.dev) and [Supabase](https://supabase.com), and hosted on [Vercel](https://vercel.com). The fonts are Dela Gothic One, Zen Kaku Gothic New and DotGothic16, under the SIL Open Font Licence.

## Licence

MIT. See [LICENSE](LICENSE).
