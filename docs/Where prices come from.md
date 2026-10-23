# Where prices come from

A price is only useful if you know what it means. This page explains where each number comes from, how fresh it is, and what Valora does when it does not know.

## What a price is

A price in Valora is an **estimate** of what a game sells for today. It comes from public market data. It is not an offer to buy, and it is not financial advice. What a game really sells for depends on the buyer, the condition, and the day.

## Where each kind of game is looked up

| Kind of game | Where the price comes from |
|---|---|
| PlayStation disc games | PriceCharting, found by the game's ID, or by its title if there is no ID |
| Steam games | The Steam store, by the game's Steam ID |
| Other digital games (PlayStation Store, Epic, Nintendo) | CheapShark, found by the game's title |

Other helpers do smaller jobs:

| Job | Where it comes from |
|---|---|
| Searching for a game to add | CheapShark |
| Reading a barcode | UPCitemdb |
| Importing your Steam library | The Steam web service, after you sign in with Steam |

## How fresh a price is

A price is saved and reused for a while, so Valora is quick and kind to the sources.

| Kind | Reused for |
|---|---|
| Disc games | 24 hours |
| Digital games | 6 hours |

After that time, the next look asks the source again. You can also press the refresh button on a game's page to ask again.

## What condition does

For disc games the price depends on how the game is kept. A game page shows a card for each condition, so you can see the difference between **Loose**, **CIB** (complete in box), **Boxed** and **New**. The Home total uses the condition you chose for each game.

## When there is no price

Sometimes the source has no price for a game. Then Valora:

1. saves it as **missing**, not as zero
2. shows a **dash** instead of a number
3. leaves it out of your total

A made up number would make your total wrong without telling you. A dash is honest.

## Dollars or rupees

Prices are found in US dollars. If you switch Settings to Sri Lankan rupees, Valora converts them for you with a fixed rate and shows a Rs. sign.

## How often you can ask

To keep things fair and fast, each person can make up to 60 requests an hour for each kind of lookup. Searching cannot use up the budget for price lookups, because they are counted separately.

Next: [Your privacy and data](Your%20privacy%20and%20data.md).
