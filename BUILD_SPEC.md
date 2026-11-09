# Bible Study App — verified data and sources

User request (2026-11-07): "Create me a bible study app using these 3 resources
King James's Bible, https://webstersdictionary1828.com and https://www.e-sword.net"

## 1. King James Bible (public domain) — VERIFIED, downloaded
- File: `~/workspace/bible-study-app/data/en_kjv.json` (4.25 MB)
- Source: https://raw.githubusercontent.com/thiagobodruk/bible/master/json/en_kjv.json
- Structure: array of 66 books: `[{abbrev, name, chapters: [[verse strings...]]}]`
- Verified: 66 books, 31,102 verses total. John 3:16 reads correctly
  ("For God so loved the world, that he gave his only begotten Son...").
- KJV vocabulary: 12,463 unique words.

## 2. Webster's Dictionary 1828 — VERIFIED, downloaded and filtered
- Full file: `~/workspace/bible-study-app/data/webster1828.csv` (16.7 MB, 62,391 entries)
- Source: https://raw.githubusercontent.com/akaitsurugi/webster1828/master/webster1828.csv
  (Noah Webster's 1828 American Dictionary, public domain text; repo is CC-BY-SA-4.0)
- Format per row: `"word","<p><b>WORD</b>, <i>part of speech</i> ...definition HTML...</p>"`
  Definitions are HTML with <p>, <b>, <i> tags — render as HTML.
- Filtered file: `~/workspace/bible-study-app/data/webster1828_kjv.json` (4.82 MB)
  — 6,067 entries, only words that appear in the KJV text.
- Spot-checked real 1828 text: faith, grace, salvation, love, sin, holy,
  righteousness, believe, pray, hope, repent (entry covers adjective + verb).
- 6,396 KJV words have NO 1828 entry — mostly proper names (Aaron, Abana...)
  and archaic verb forms (abhorreth, abideth). For those, link out to
  https://webstersdictionary1828.com/Dictionary/<word> (that site's URL pattern).

## 3. e-Sword — VERIFIED links
- Home: https://www.e-sword.net/ — free Bible study software, refined over 25 years.
- Downloads: https://www.e-sword.net/downloads.html
  - e-Sword v15.2.0 install, 54.4 MB, updated 08-14-2026, Windows 7–11.
  - Basic install includes: King James Bible, KJV with Strong's numbers,
    Strong's Hebrew and Greek Dictionaries, Smith's Bible Dictionary,
    Through the Bible Day by Day (F. B. Meyer) commentary,
    Treasury of Scripture Knowledge cross references,
    Morning & Evening (Charles H. Spurgeon) devotional.
  - Hundreds more books via the Download menu inside the e-Sword app.

## App features (for the builder)
- KJV reader: pick book + chapter, read verses; reference lookup (e.g. John 3:16).
- Keyword search across the KJV text.
- Tap/click any word in a verse → Webster's 1828 definition panel
  (from the bundled filtered dictionary; link out to webstersdictionary1828.com
  when the word has no bundled entry).
- Standalone word-study lookup box for any word.
- Verse of the day on the home screen.
- e-Sword page: what e-Sword is, what the free install includes, download link.
- If built fullstack: save personal notes per verse and favorite/bookmark verses.
