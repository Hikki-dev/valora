# How everything fits together

Valora has a few small parts. Each one does a single job, and together they turn "I own this game" into "it is worth this much today".

<p align="center"><a href="images/how-it-fits.svg"><img src="images/how-it-fits.svg" alt="Diagram: you use the Valora app, which saves to a locked database and asks Edge Functions for prices from PriceCharting, the Steam store, CheapShark and UPCitemdb" width="100%"></a></p>

Click the picture to see it full size.

## The story of one game

1. You add a game in the **app**. It runs in your browser or on your phone.
2. The app saves the game in your **database**. The database is locked so that only you can read your rows.
3. The app asks a **price lookup** (an Edge Function) for today's price.
4. The lookup first checks that you are signed in, and that you have not asked too many times this hour. The limit is 60 an hour for each kind of request.
5. It asks the right public source for the price. See [Where prices come from](Where%20prices%20come%20from.md).
6. The price is saved **with today's date**. Over time the dates build the chart on the game's page.
7. Every day a small job looks at your **wishlist** and marks the games that have reached your target price.

## What each part is for

| Part | What it does for you | Where it lives |
|---|---|---|
| The app | Everything you see and tap | `lib/` (Flutter), built for web, iPhone and Android |
| The database | Keeps your games, wishlist, profile and price history | Supabase Postgres, set up by `supabase/migrations` |
| Row Level Security | Makes sure nobody else can see your rows | Rules in the database, one set for each table |
| Price lookups | Fetch and save prices, and look up barcodes and Steam libraries | `supabase/functions` |
| The daily job | Marks wishlist games that reached your target | `supabase/functions/check-price-alerts` |
| The website | Serves the web app | Vercel, set up by `vercel.json` |
| The checks | Format, analyze, test and build every change | GitHub Actions, in `.github/workflows` |

## Why it is built this way

* **The phone does the showing, the server does the work.** Price lookups happen on the server, so your phone does not spend battery on them.
* **Prices are saved with the date.** One number tells you little. A history tells you whether a game is rising or falling.
* **Prices are cached.** A lookup is reused for a while (24 hours for disc games, 6 hours for digital ones), so the same game is not fetched again and again.
* **A missing price is a dash.** Valora would rather show nothing than show something false.

## The folders

| Folder | What is in it |
|---|---|
| `lib/views` | The screens: sign-in, home, library, game page, wishlist, insights, profile |
| `lib/widgets` | Shared pieces: the comic style, loading screen, forms, app shell |
| `lib/controllers`, `lib/repositories`, `lib/services` | Sign-in, saving data, and talking to the price lookups |
| `lib/core` | Theme, colours, number and currency formatting |
| `supabase/functions` | The price lookups and the daily job |
| `supabase/migrations` | The database, step by step, in date order |
| `test` | Tests for prices, currencies and platforms |

Next: [Where prices come from](Where%20prices%20come%20from.md), or [Your privacy and data](Your%20privacy%20and%20data.md).
