# Questions and answers

## About Valora

### What is it?

An app that shows what your game collection is worth today, and how that changes over time. You add games, and it looks up prices for you.

### Is it free?

Yes. It is open source under the MIT licence.

### Where does it run?

In your browser at [valora-umber.vercel.app](https://valora-umber.vercel.app), and as an Android app from the Releases page. The same code builds for iPhone.

### Is a price a real offer?

No. It is an estimate from public market data. See [Where prices come from](Where%20prices%20come%20from.md).

## Your data

### Who can see my collection?

Only you. Every table is locked with Row Level Security. See [Your privacy and data](Your%20privacy%20and%20data.md).

### Do you sell my data?

No. There are no adverts and nothing is sold.

### Can I hide the numbers?

Yes. Turn on **Hide values** in Settings.

## Using it

### Why does a game show a dash?

The price source had no price for it. Valora shows a dash instead of inventing a number, and leaves it out of your total.

### How fresh are the prices?

Disc games are reused for 24 hours and digital games for 6 hours. Press refresh on a game's page to ask again.

### What do Game only, Complete and Sealed mean?

**Game only** is just the disc or cartridge, with no case and no manual. **Complete** is the game with its case and manual (collector sites call this "CIB", complete in box). **Sealed** is brand new, still in its shrink-wrap. The same game is worth different amounts in each, so choose the one that matches your copy.

### Can I add many games at once?

Yes. **Sync Steam** brings in your whole Steam library. For boxed games, use the barcode scanner.

### Can I see my values in another currency?

US dollars and Sri Lankan rupees. Switch in Settings.

## Running your own copy

### What do I need?

Flutter 3.41.4, a free Supabase project and the Supabase CLI. The steps are in [Running it yourself](Running%20it%20yourself.md).

### Why does my build fail with an IconData error?

You are using a newer Flutter than this project supports. See [Fixing problems](Fixing%20problems.md).

### Can I use my own pictures?

Yes. Put them in `assets/art` under the same names, or change the names in the code. Keep them under 1600 pixels wide.

## Legal

Prices are estimates, not advice. Game names and logos belong to their owners. The comic artwork is third-party, so check you may use it. More in the README under [Legal and responsibility](../README.md#legal-and-responsibility).
