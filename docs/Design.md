# Design: Midnight Manga

Valora looks like a comic book on purpose. A collection of games is something people love, so the app should feel like fun, not like a bank. This page explains the rules behind the look, so new screens match the old ones.

## The idea

* **Bold outlines** around everything, like inked panels.
* **Hard shadows**, with no blur, like a printed page.
* **Flat colour** with a halftone dot pattern and speed lines in the background.
* **Light by default.** A dark theme is one tap away, and the app remembers your choice.

## Colours

All colours come from one file, `lib/core/tokens.dart`. Screens never use a raw colour. They ask for a role, such as the background, the money colour, or a gain or loss colour, so light and dark always stay in step.

| Role | Used for |
|---|---|
| Money (yellow) | The main action on each screen, and your value |
| Ink (near black) | Outlines, shadows and text |
| Gain and loss | Up and down in value. They always come with a sign or word, never colour alone |

## Type

Three fonts, each with one job:

| Font | Used for |
|---|---|
| Dela Gothic One | Big titles and the Valora name |
| Zen Kaku Gothic New | Everything you read |
| DotGothic16 | Small labels above a heading |

All three are free (SIL Open Font Licence) and trimmed to the letters the app uses, so they are small.

## Phone and computer

The sign-in page shows how the layout changes:

* **900 pixels wide or more:** a landscape picture beside the form, with the Valora name and three comic panels.
* **Narrower:** a portrait picture behind the form, a large tilted V and a bold yellow Valora name at the top. The comic panels are left out so the form comes first.
* The loading screen shows its three comic panels from **600 pixels** wide.

The app's menu also changes with the screen. It sits at the bottom on a phone and at the side on larger screens.

<a href="images/login-desktop.png"><img src="images/login-desktop.png" alt="Sign-in page on a computer" width="100%"></a>

## Artwork

The pictures are in `assets/art`:

| File | Used for |
|---|---|
| `hero_landscape.jpg` | The left side of the sign-in page on a computer |
| `hero_portrait.jpg` | The sign-in page background on a phone |
| `panel_1.jpg`, `panel_2.jpg`, `panel_3.jpg` | The three comic panels |

They are cut down to the size the screen needs (no wider than 1600 pixels, 900 for the panels), so the page opens quickly. Keep your full-size originals outside the repository.

The pictures are third-party artwork. Make sure you may use them before you publish your own copy.

## Rules for every screen

1. Every tap target is at least 44 pixels.
2. Anything that carries meaning also has a text label, so screen readers can read it.
3. Motion stops when the person has asked their device for reduced motion.
4. Errors are said in plain words, next to the thing that went wrong.
5. Anything that deletes can be undone for a few seconds.

Back to [How everything fits](How%20everything%20fits.md).
