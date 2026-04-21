---
title: "I rebuilt Winamp in a browser and dropped it on Neocities"
date: 2026-04-20T01:31:00-06:00
categories: ["BiP-Neocities", "Design"]
tags: ["neocities", "winamp", "midi", "webaudio"]
url: https://dade.micro.blog/2026/04/20/i-rebuilt-winamp-in-a.html
---

The homepage at [dadeog.neocities.org](https://dadeog.neocities.org) now has a working Winamp 2 replica. It's not a skin and not a visual mock. It actually plays.

What works:

- 76x16 spectrum analyzer and oscilloscope, 19 bars at 3px wide with 1px gaps, peaks that fall one pixel per frame. Reads a shared AudioAnalyser node and pauses on `document.hidden` so it stops burning CPU in background tabs.
- Playlist with shuffle and repeat, persisted in localStorage. Clean hook: `window.__dadeOnTrackEnd(curIdx, defaultNext, total)` returns false to stay, a number to override, or undefined to fall through.
- MIDI player with a self-hosted FluidR3_GM SoundFont, because Neocities' CSP blocks external fetches. 29 instruments, about 81 MB on disk. Percussion had to come from the dave4mpls fork; the gleitz upstream never shipped a drum kit.
- Per-GM-family 7-band EQ mixer with four presets (Flat / Rock / Dance / Classical), also persisted.
- Five curated 1997-98 alt-rock MIDIs loaded in: Iris, One Week, Closing Time, Sex and Candy, Torn.

Two hard lessons. Scheduling ~2000 BufferSourceNodes up front faulted the WebAudio renderer; fix was a rolling 500ms rAF lookahead scheduler with a lazy AudioContext and a GM fallback. And Neocities ignores `_headers`, so content-hashed filenames are the only cache-busting path. The build script rsyncs into `build/`, hashes CSS and JS, rewrites HTML refs including cross-file ESM imports, then pushes with `neocities push --prune .`.

viscolor.txt isn't in the base-2.91 skin pack, so the palette is hardcoded from Webamp defaults for now. One-line swap when it shows up.
