# Changelog

All notable changes to **Valora** are written here in plain words.

## Free disc prices, and fixes found on the live site

1. PlayStation disc prices can now come from eBay, which is free. The price function uses eBay listings when no PriceCharting token is set; the middle asking price of used copies is the Complete value and of new copies the Sealed value. Fewer than three matching listings gives a dash. The app now tells the function whether a disc is for a PS4 or a PS5. Needs `EBAY_CLIENT_ID` and `EBAY_CLIENT_SECRET`; see Running it yourself.
2. Disc games showed no market value because `PRICE_CHARTING_TOKEN` was never set. That is why Refresh did nothing.
3. Adding a game failed with "Couldn't save" because the `games` table had no `notes` column. It was added (see `supabase/migrations`).
4. The "removed" banner now goes away after 5 seconds, and the delete really runs.
5. Cover art from Steam and GamesGate shows on the web again.

## [Unreleased] - 2026-10-25

### Fixed
- Adding a game by search showed a blank box instead of the results. The results were found, but each row was drawn without a height, so it could not be shown. Search results now appear.
- If a search really does fail, the box now says so instead of looking like "no matches".


### Better docs
- The README now shows the real Home, Library, Wishlist and Insights screens, on a computer and on a phone, using made-up demo games.
- A small test makes those pictures, so they can be refreshed with one command.
- Added a 1280 by 640 picture for the GitHub link preview.
- The README is now one long walkthrough of the app, nine steps with a picture each: sign in, add a game, Home, Library, a game's page, Wishlist, Insights, Settings and dark mode.
- Fixed the names of a disc game's condition in the guides. The app says Game only, Complete and Sealed.

### A new look: Midnight Manga
- Every screen has a new look: Home, Library, game pages, Wishlist, Insights, Profile and Settings.
- Light mode is now the default, and Valora remembers your choice.
- Sign-in uses your own comic pictures. A landscape picture shows on computers and a portrait picture shows on phones.
- On a phone the sign-in page has a large, bold Valora logo, and the comic panels no longer take up room on small screens.

### Better to use
- Library: sort, switch between grid and list, and search that waits for you to stop typing.
- Deleting a game can be undone for a few seconds.
- Wishlist shows when a game has reached your target price.
- Forms check what you type and explain mistakes in plain words.
- Settings: theme, currency, a switch to hide your values, and a short explanation of where prices come from.

### Prices and safety
- Prices are honest: a missing price shows a dash, never a made up number.
- The web version starts faster.
- Server functions are locked down further, and a database view no longer bypasses Row Level Security.
- The database in this repository now matches the live one.
- Nintendo consoles are matched to the right platform.

### Documentation
- The README now tells the story from "what is this" to "run it yourself", one step at a time.
- New guides in `docs/`: Getting started, How everything fits, Where prices come from, Your privacy and data, Running it yourself, Design, FAQ and Fixing problems.
- A diagram of how the parts fit together, and screenshots of the sign-in page.
- Issue and pull request templates, and a licence file (MIT).
- Docs-only changes no longer publish a new Android build.

### Behind the scenes
- All code is formatted, so the automatic checks pass.
- The automatic checks use Flutter 3.41.4, the same as the website build.
- Old fonts and unused pictures were removed to keep the app small.
- Added `CONTRIBUTING.md`, `SECURITY.md` and a rewritten README.

## [1.1.0+2] - 2026-04-11
### 💨 Speed & Web Updates
- **Faster Browsing**: Optimized the web version to be twice as fast.
- **Better Loading**: Images now load more efficiently to prevent crashes.
- **Smooth Scrolling**: Refined the library grid for a smoother experience.

### 📐 New Layouts
- **Tablet & Desktop Support**: Added new custom views for larger screens.
- **Smart Navigation**: The app now adjusts its menu based on your screen size.

### 🔒 Security Updates
- **Data Protection**: Improved how your information is stored and isolated.
- **Secure Logic**: Moved sensitive settings to a more secure system.

### 📸 New Features
- **Collection Snapshots**: Share a beautiful summary of your 10 most valuable games.
- **Better Sync**: Improved the Steam & Epic sync tools for more reliable imports.
