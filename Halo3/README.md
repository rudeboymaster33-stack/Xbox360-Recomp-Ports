# Halo 3 — Xbox 360 static recompilation for Android (Retroid Pocket 6)

> **AI-generated:** the code, scripts and patches in this repository were written by Claude
> (Anthropic's AI), directed and play-tested by the repository owner.

A static recompilation of the Xbox 360 version of *Halo 3* with the
[ReXGlue SDK](https://github.com/rexglue/rexglue-sdk), built as a native Android app for the
Retroid Pocket 6 (Snapdragon 8 Gen 2). There is no PC build.

**No game files are included.** You need your own copy of the game disc.

## Status
- Boots, menus and Forge play at the game's own 30 fps with sound.
- Effects, water, decals and vehicles render correctly; frame pacing is even; the game pauses
  when you leave the app and resumes when you come back.
- The busiest views of the map can still dip below 30 fps (the GPU is fully used there).

## Requirements
- Windows PC, the Retroid Pocket 6 connected over USB with USB debugging on.
- The **Universe at War** port from this collection set up first, in the `UniverseAtWar` folder
  next to this one: this port reuses its toolkit (`UniverseAtWar\rexglue-sdk`, built by its
  option 1) and its Android build tools (its option 2).
- Python 3 (for unpacking the disc).
- The game disc image at
  `C:\ROMS\Xbox 360\Halo 3 (USA, Europe) (En,Ja,Fr,De,Es,It,Pt,Zh,Ko)\Halo 3 (USA, Europe) (En,Ja,Fr,De,Es,It,Pt,Zh,Ko).iso`
  (change `scripts\paths.bat` for another location).

## How to use
Double-click **Start here.bat**:

| Option | What it does |
|---|---|
| 1 | Unpack the game disc |
| 2 | Retroid: build, install and start the game (the first build takes a few hours; the first install copies about 6 GB of game files) |

Build and install logs go to the `logs` folder.

## Layout
| Path | What |
|---|---|
| `files/halo3_manifest.toml` | ReXGlue manifest for the game |
| `project/` | Game project (`src/`, CMake) — the generated C++ is created by the build and never committed |
| `android/` | Android app (`Halo3Activity.java`: default settings) |
| `patches/` | Changes to the ReXGlue SDK, applied automatically by the build |
| `scripts/` | Build, install and unpack scripts used by the menu |
