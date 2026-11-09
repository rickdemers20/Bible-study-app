# How www/index.html differs from the website

Source: the `bible-study-website` artifact export (single self-contained HTML,
~33 MB, KJV text + Webster's 1828 dictionary embedded). The artifact itself
and the live rickdemers.com site were NOT modified — this is a copy adapted
for the app.

## Removed (app-only requirements)

1. **Local fun sites** — the entire "Family night out — Panama City Beach"
   section from the Fun tab: Guardians Legacy, Rock'it Lanes, WonderWorks,
   Coconut Creek Family Fun Park, Rainforest Black Light Golf, Goofy Golf,
   ZooWorld (and their linktr.ee / venue links). The Fun tab intro line that
   mentioned "family favorites around Panama City Beach" was rewritten to
   drop the location.
2. **Links to the training site (rickdemers.com)** — all of them:
   - Open Graph / Twitter meta tags pointing at rickdemers.com
     (og:url, og:image, twitter:image).
   - Intro line "free for everyone, from rickdemers.com" → "free for everyone."
   - The "Share this study" section: heading, lede (QR code opens
     rickdemers.com), the business card image (QR to rickdemers.com) and the
     "Download the card" / "View the card full size" buttons.
   - Footer "A page from rickdemers.com" → "Built by Rick Demers."
3. **"Save to your home screen" section** — website-only instructions
   (Safari/Chrome "Add to Home Screen"); meaningless inside the app.
4. **"Website" wording in the My Study privacy notes** — changed to "app"
   (notes save only on your own device, in this app).

## Kept

- Read, Search, Places, Word study, My Study (notes + favorites, localStorage
  on device), Fun, e-Sword tabs — all working offline (Bible text +
  dictionary bundled in the HTML).
- Fun tab online content: Kingdom Quest Games, Bible Trails, Superbook,
  Bible App for Kids, BibleProject, and the Bible Mysteries Podcast
  (https://www.biblemysteriespodcast.com — free public site).
- e-Sword tab (links out to e-sword.net), Lighthouse Church invite,
  Ko-fi "Support the Bible Study" card.
- The crosses home-screen icon artwork (apple-touch-icon, 512/192/48 icons)
  embedded as data: URIs in the page head, and extracted to assets/ for
  the native app icons.

## Places to Go map (Fun tab) — added 2026-11-08

The Fun tab ends with a **"Places to go — Christian family trips"** section:
an interactive map plus a list of 12 real, verified Christian-themed family
attractions across the country. Leaflet 1.9.4 is inlined in the page (no CDN
needed for the library); map pictures come from OpenStreetMap and need
internet. If the map picture can't load (offline), a notice appears and the
list below — name, what it is, address, website and directions — still works
fully offline, because the place data is bundled in the app. Tapping a pin
shows a popup with details; each list card has "Visit website", "Directions"
(Google Maps) and "Show on map" buttons.

Places on the map (all verified 2026-11-08 — real addresses, coordinates and
official websites; no local Panama City secular venues):
Ark Encounter (Williamstown, KY), Creation Museum (Petersburg, KY), Museum of
the Bible (Washington, DC), Sight & Sound Theatres Lancaster (Ronks, PA) and
Branson (Branson, MO), Billy Graham Library (Charlotte, NC), The Great Passion
Play (Eureka Springs, AR), Precious Moments Chapel (Carthage, MO), BibleWalk
(Mansfield, OH), ICR Discovery Center (Dallas, TX), Shrine of Christ's Passion
(St. John, IN), Creation and Earth History Museum (Santee, CA).

## Prayer of the Day + Learn to Pray (added 2026-11-08)

**Prayer of the Day** — a short daily prayer in the Read view, right under
the Verse of the Day, in the same style (kicker + serif text + verse
reference). 36 prayers bundled in the page (`POTD` array), one per day,
cycling by day of year with the same formula as the Verse of the Day, so it
works fully offline. Each prayer is brief and warm, grounded in a named
Scripture reference, and ends "In Jesus' name, amen." The block has a
"Learn how to pray" button that opens the Pray tab.

**Learn to Pray** — a new **Pray** tab (2nd in the tab bar, after Read;
tab bar grid widened from 7 to 8 columns; cross icon added to the icon set).
It teaches all three approaches the owner chose:
1. **The ACTS pattern** — Adoration, Confession, Thanksgiving, Supplication,
   as four simple steps with an example sentence for each.
2. **The Lord's Prayer as a pattern** — Matthew 6:9–13 walked through line
   by line as a prayer prompt (relationship, worship, God's will, daily
   needs, forgiveness, guidance and protection).
3. **Praying Scripture** — how to turn a verse into a prayer in your own
   words, with two worked examples (Psalm 23:1; Philippians 4:6–7).
All content is bundled in the page (offline). The tab system is generic
(`showTab` loops over `TABS`), so the new tab needed only a `TABS` entry, a
`view-pray` section, and the icon — no change to the switching logic.

## Free app, voluntary donations (added 2026-11-08)

The app is **free** — free to download, no paywall, no in-app purchase, and
no content gated behind a payment. The only donation option is the existing
Ko-fi **"Support the Bible Study"** button (ko-fi.com/rickdemers), which is
voluntary — a gift of any size is welcome but never required. The support
card wording was updated for the app (it used to say "Help keep this site
online" / "keeping the site online", carried over from the website): it now
reads **"Help keep this app free"** and says the app is free with no paywall,
gifts are voluntary, and gifts help keep the app free and support charitable
giving. **Proceeds go to charity; the specific charity has not been named
yet** — the owner will name it later, and the wording deliberately names
none. No charity name was invented. (The privacy policy has a matching
"Donations" note.)

## Verification (after adapting)

- `rickdemers.com`: 0 occurrences
- `supercast`: 0 occurrences
- `Panama City`: 0 occurrences
- Local venue names / linktr.ee: 0 occurrences
- `biblemysteriespodcast.com`: present (podcast link kept)
- All 8 tabs present (view-read, view-pray, view-search, view-places,
  view-words, view-saved, view-fun, view-esword); fav-list and note-list present.
- Prayer of the Day + Learn to Pray (2026-11-08): 36 prayers in the `POTD`
  array (verified: all have text + verse reference; day-of-year cycling
  checked for Jan 1, Feb 5, Dec 31 and all 366 days); `renderPotd()` builds
  kicker + prayer text + reference + "Learn how to pray" button; the button
  opens the Pray tab (8 tabs total, Pray 2nd, cross icon); both inline
  `<script>` blocks pass `node --check`; `npx cap sync` done — both platform
  copies carry the new content.
- Free/donations (2026-11-08): support card reads "Help keep this app free"
  (no "site online" wording left); "Support the Bible Study" button and
  ko-fi.com/rickdemers link unchanged; no charity named anywhere; no
  in-app-purchase or paywall code in the app.
