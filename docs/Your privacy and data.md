# Your privacy and data

Your collection is yours. This page says what Valora keeps, who can see it, and how that is enforced.

## What Valora keeps

| What | Why |
|---|---|
| Your email, or your Google profile name | So you can sign in |
| The games you added, with condition and what you paid | So Valora can show your value |
| Your wishlist and target prices | So it can tell you when a game gets cheap |
| Price history for your games | So it can draw a chart |
| Your settings, such as theme and currency | So the app looks the way you left it |

Valora does not sell your data, and it does not show adverts.

## Who can see it

Only you. This is not a promise in a policy. It is a rule in the database.

Every table uses **Row Level Security**. A rule on each table says "a person can only read and change rows that belong to them". Even if the app had a bug, the database would refuse to hand over somebody else's rows.

A database view that lists your games with their values used to skip these rules. It now runs as the person who asks, so the rules apply to it too.

## Signing in

* **Google:** Valora checks Google's signed ID token. Your Google password never reaches Valora.
* **Email:** your password is handled by Supabase Auth. It is stored as a hash, never as plain text.

## Secrets

* The app only holds a **publishable** key, which is meant to be public. It can do nothing the database rules do not allow.
* Powerful keys, such as the service role key, live in the server's secret store, never in the code or in this repository.
* The daily wishlist job can only be started by someone who knows a secret value. Anyone else gets an "Unauthorized" answer.
* A `.env.build` file is ignored by Git, so it can never be committed by accident.

## On the server

* Every price lookup checks who you are before it does anything.
* Every request is checked for the right shape, so odd input is refused early.
* Lookups are limited to 60 an hour for each kind, so nobody can flood them.
* The website sends security headers, set in `vercel.json`, so it cannot be put inside another page.

## Deleting your data

You can delete any game at any time, and the app gives you a few seconds to undo it. Removing a whole account is done by the person who runs the Supabase project, in its dashboard.

## Reporting a problem

If you find a way to see someone else's data, or any other security problem, do not post it in public. Follow [SECURITY.md](../SECURITY.md).

Next: [Running it yourself](Running%20it%20yourself.md), or back to [How everything fits](How%20everything%20fits.md).
