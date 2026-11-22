# NYXEL — Living-Room TV Console Dashboard for Pegasus Frontend (v6.1)

![Version](https://img.shields.io/badge/version-v6.1-7c3aed)
![QtQuick](https://img.shields.io/badge/QtQuick-2.12-41a5f5)
![Performance](https://img.shields.io/badge/rendering-60fps%20%7C%20zero--shader-16a34a)
![Platforms](https://img.shields.io/badge/platforms-Android%20TV%20%7C%20PC%20%7C%20Handhelds-64748b)
![License](https://img.shields.io/badge/license-MIT-blue)

Nyxel is a couch-first theme for [Pegasus Frontend](https://pegasus-frontend.org/), designed for 720p and 1080p living-room screens as well as PCs and handhelds. Its visual approach aims for a smooth, readable 60fps experience on modest Android TV boxes and set-top boxes: QtQuick 2.12, no shader effects, and no expensive full-screen blur.

> **Version:** 6.1 · **Theme:** Nyxel · **Author:** [@aj5649169-svg](https://github.com/aj5649169-svg)

## Preview

Add screenshots or a short gameplay/UI capture here when available:

- Main Shelf & Cinema Backdrop
- Frosted Glass Action Drawer
- Discovery Hub
- Keyword Search

## Highlights

### A living-room-first visual system
- Split-contrast composition: a pitch-black navigation side against a vibrant, console-coloured content side.
- Ambient colour drift, couch-sized hero cards, concentric breathing bloom, diagonal glass sheen, and per-card reflections.
- Monogram artwork fallback when game artwork is unavailable.

### Cinema backdrops
- Widescreen backdrops rendered at approximately 62% opacity, with left-side black feathering and a console-colour rim tint.
- A restrained zoom-settle treatment keeps the backdrop alive without relying on shader-heavy effects.
- Artwork fallback order: local background/screenshot, Libretro named snaps across supported regions, then box art.

### 15 audio cues
The theme package includes 15 WAV cues: 14 synthesized interaction sounds plus a keepalive cue.

| File | Purpose |
| --- | --- |
| `boot.wav` | Startup |
| `move.wav` | Horizontal navigation |
| `move_vert.wav` | Vertical navigation |
| `tab.wav` | Console/tab change |
| `select.wav` | Selection |
| `back.wav` | Back |
| `fav.wav` | Favorite |
| `wishlist.wav` | Wishlist |
| `drawer_open.wav` | Open action drawer |
| `drawer_close.wav` | Close action drawer |
| `key_tap.wav` | Virtual keyboard |
| `roulette_tick.wav` | Roulette tick |
| `roulette_win.wav` | Roulette result |
| `launch.wav` | Launch |
| `keepalive.wav` | Audio keepalive |

### Action Drawer
- Translucent deep-blue glass drawer with Play, Favorite, and Wishlist actions.
- Large, readable descriptions and play statistics (approximately 17–19px).
- Gliding focus pill, Shelf / five-column Poster Grid view toggle, and roulette.
- Sort options: A–Z, Most Played, Recently Played, and Favorites First.
- UI Sounds, Low-Latency Audio, and Online Fetch toggles, plus controller guidance and debug tools.

### Discovery Hub
Open the Discovery Hub with **X** or **Up**. It is independent of the L1/R1 console tabs and can surface:
- Continue Last Played
- Popular Classics
- 120+ automatically grouped franchise collections
- Multiplayer picks
- Wishlist
- Unplayed gems
- D-pad console switcher

### Keyword Search
Press **Y** to search across consoles. The virtual keyboard supports **X** to delete and **Y** to insert a space; a physical keyboard is supported as well.

### Artwork and metadata
Nyxel is designed to work with zero-key metadata. Its cached cover-art lookup pipeline prioritizes local art, then Libretro regional artwork, then Wikipedia thumbnails, and finally a monogram tile fallback across 18+ systems.

### Lightweight operation
- Avoids a lag-prone all-games tab.
- Uses lazy indexing for hub content.
- Can resume the exact console and game after returning from RetroArch, skipping the splash sequence.
- Includes a three-minute breathing-clock screensaver.
- Protects against accidental repeat launches from held controller buttons.

## Controls

| Input | Action |
| --- | --- |
| D-pad / left stick | Browse |
| Up | Open Discovery Hub |
| Down | Cycle console in Shelf view |
| A / OK / Enter | Open the action drawer / confirm |
| B / Back / Esc | Go back |
| X | Open Discovery Hub; delete in search |
| Y | Open keyword search; insert a space in search |
| L1 / R1 | Switch console tabs |
| L2 / R2 | Alphabet navigation or ±10 |
| Menu | Open native Pegasus settings |

Exact mappings can depend on the controller and Android input mode. Use Controller Debug in the action drawer to inspect the detected key and scan code.

## Installation

### PC, Steam Deck, handhelds, and Android phones

1. Install Pegasus Frontend from the [official website](https://pegasus-frontend.org/).
2. Download the **Nyxel v6.1** ZIP from the [GitHub Releases page](https://github.com/aj5649169-svg/Nyxel/releases).
3. Extract the theme package into your Pegasus themes directory, keeping this layout:

   ```text
   themes/
   └── nyxel/
       ├── theme.qml
       ├── theme.cfg
       └── sounds/
           └── *.wav
   ```

4. In Pegasus Settings, choose **Nyxel** as the theme, then restart Pegasus if needed.

### Android TV using atvTools

This route uses Android TV developer options and atvTools to copy the theme into Pegasus' app-accessible storage.

1. Install Pegasus from the [official website](https://pegasus-frontend.org/) and launch it once.
2. On the TV, enable Developer Options by tapping **Build Number** seven times.
3. Enable **USB debugging** and **Network debugging** (wording varies by Android TV version). Note the TV's IP address.
4. Install atvTools on your phone, connect the phone and TV to the same Wi-Fi network, then connect to the TV IP and port `5555`. Approve the connection on the TV and select **Always Allow** if offered.
5. Download the Nyxel ZIP to the phone, then use atvTools **Tools → Files** to copy it into `/sdcard/Download/`.
6. Open **atvTools → Shell** and run:

   ```sh
   Z=$(ls -t /sdcard/Download/*.zip | head -n 1); echo "Using: $Z"
   rm -rf /sdcard/Download/_t && mkdir -p /sdcard/Download/_t && unzip -o "$Z" -d /sdcard/Download/_t
   Q=$(find /sdcard/Download/_t -name "theme.qml" | head -n 1); S="${Q%/*}"
   P1="/sdcard/pegasus-frontend/themes/gamedeck"; P2="/sdcard/Android/data/org.pegasus_frontend.android/files/pegasus-frontend/themes/gamedeck"
   mkdir -p "$P1" "$P2" && cp -rf "$S"/* "$P1"/ && cp -rf "$S"/* "$P2"/ && chmod -R 777 "$P1" "$P2" 2>/dev/null
   rm -rf /sdcard/Download/_t && ls -la "$P1/theme.qml"
   am force-stop org.pegasus_frontend.android && monkey -p org.pegasus_frontend.android -c android.intent.category.LAUNCHER 1
   ```

7. In Pegasus Settings → Theme, select **Nyxel**. The folder name `gamedeck` in the command is only the install directory name; Pegasus still identifies the theme from `theme.cfg`.

If your Pegasus build uses a different storage layout, check its configured themes directory and adjust both destination paths before running the copy command.

## Troubleshooting

### Pegasus opens to a blank screen or shows no games

On some Android 11+ TV builds, the All Files Access control is hidden or not granted. From an authorized ADB shell, try:

```sh
appops set org.pegasus_frontend.android MANAGE_EXTERNAL_STORAGE allow
pm grant org.pegasus_frontend.android android.permission.READ_EXTERNAL_STORAGE 2>/dev/null
pm grant org.pegasus_frontend.android android.permission.WRITE_EXTERNAL_STORAGE 2>/dev/null
am force-stop org.pegasus_frontend.android && monkey -p org.pegasus_frontend.android -c android.intent.category.LAUNCHER 1
```

Also verify that each ROM directory contains a `metadata.pegasus.txt` file and that its path is listed in `/sdcard/pegasus-frontend/game_dirs.txt`.

### Joystick works but A/B/X/Y buttons do not

An accessibility service may be intercepting face-button input.

- First try Settings → Device Preferences → Accessibility and temporarily disable active services.
- If you understand the effect and have an ADB shell, the following disables enabled accessibility services globally:

```sh
settings put secure enabled_accessibility_services ""
settings put secure accessibility_enabled 0
am force-stop org.pegasus_frontend.android && monkey -p org.pegasus_frontend.android -c android.intent.category.LAUNCHER 1
```

For Projectivy Launcher, the optional home-activity command is:

```sh
cmd package set-home-activity com.spocky.projengmenu/.ui.home.MainActivity
```

For SHANWAN multi-mode controllers, hold **Home** (or **Select + Start**) for around 5–7 seconds to switch from Android D-Input to X-Input, if supported by the controller.

### Theme does not update or Pegasus returns to its default grid

Inspect the end of the Pegasus log:

```sh
tail -n 30 /sdcard/pegasus-frontend/lastrun.log
```

Confirm that the selected theme folder contains both `theme.qml` and `theme.cfg`.

### HDMI audio delay or unmapped keys

Open the action drawer with **A** and keep **LOW-LATENCY AUDIO** enabled if your device benefits from it. Turn on **CONTROLLER DEBUG** to inspect live key and scan-code values.

## Reporting bugs and requesting features

Found a bug, hit an error on your TV/controller, or have an idea for a new feature? Please [open a GitHub Issue](https://github.com/aj5649169-svg/Nyxel/issues/new/choose).

When reporting a problem, include:
- Device / TV model
- Controller model
- Pegasus version
- What happened and how to reproduce it
- The last 20 lines of `lastrun.log`, or a clear photo of the TV screen

## Changelog — v6.1

- Fixed gamepad A-button collision.
- Added 62% cinema backdrops with automatic artwork fallback.
- Added 15 audio cues.
- Removed the lag-prone all-games tab.
- Improved description readability with 17–19px text.
- Expanded multi-region cover-art lookup.
- Added Android TV accessibility troubleshooting guidance.

## License

Nyxel is released under the [MIT License](LICENSE).
