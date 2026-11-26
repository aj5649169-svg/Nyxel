import QtQuick 2.12
import QtMultimedia 5.9

// ============================================================================
// NYXEL — Living-Room TV Console Dashboard for Pegasus Frontend (v6.1.1)
// Target: QtQuick 2.12 + QtMultimedia 5.9 ONLY (32-bit Android TV / Jio STB)
// Zero Qt 6 syntax | Zero shaders | Zero blur | Low-RAM safe (512x512 cap)
//
// Quick configuration knobs:
//   appName    - Change in one line before public GitHub release
//   refHeight  - Design reference height (1080 default; floor protects 720p)
//   couchBoost - Couch-distance TV text & control scale factor
// ============================================================================

FocusScope {
    id: root
    focus: true

    // ------------------------------------------------------------------
    // 1. Configuration & Reactive State
    // ------------------------------------------------------------------

    property string appName: "NYXEL"
    property real refHeight: 1080
    property real couchBoost: 1.24
    property real ui: Math.max(0.85, root.height / refHeight)

    // Primary view routing ("main" | "hub" | "search")
    property string activeView: "main"
    property bool gridMode: false

    // Main console library state (L1/R1 tabs stay pure consoles + Favorites/Recent/Collection)
    property int tabIndex: 2
    property var tabList: []
    property var currentGames: []
    property var currentLetters: []
    property real cardRatio: ratioFor(currentTabObj().key)

    // Game Action Drawer (opened by single-click [A] on any game card)
    property bool actionOpen: false
    property var actionGame: null
    property int actionZone: 0       // 0 = top 3 icon buttons, 1 = scrollable options list
    property int actionIconIdx: 0    // 0 = PLAY, 1 = FAVORITE, 2 = WISHLIST
    property int actionListIdx: 0
    property var actionMenuItems: []

    // Discovery Hub state (completely separate from L1/R1 console tabs)
    property int hubSection: 0       // 0 = Quick, 1 = Popular, 2 = Franchises, 3 = Consoles
    property int hubQuickIdx: 0
    property int hubPopularIdx: 0
    property int hubFranchiseIdx: 0
    property int hubConsoleIdx: 0
    property var hubQuickItems: []
    property var hubConsoleItems: []
    property var popularGames: []
    property var franchiseList: []
    property var multiplayerGames: []
    property var unplayedGames: []
    property var lastPlayedGame: null
    property bool hubSubOpen: false
    property string hubSubTitle: ""
    property string hubSubTag: ""
    property var hubSubGames: []
    property int hubSubIdx: 0

    // Keyword Search Engine state
    property string searchQuery: ""
    property var searchResults: []
    property int searchZone: 0       // 0 = virtual keyboard, 1 = results list
    property int kbIndex: 0
    property int searchResultIdx: 0
    property int kbFlashIdx: -1
    property string searchFrom: "main"
    property var kbKeys: [
        "A","B","C","D","E","F",
        "G","H","I","J","K","L",
        "M","N","O","P","Q","R",
        "S","T","U","V","W","X",
        "Y","Z","0","1","2","3",
        "4","5","6","7","8","9",
        "SPACE","DEL","CLEAR","RESULTS"
    ]

    // Persistent preferences & caches
    property bool soundsOn: true
    property bool onlineFetchOn: true
    property bool lowLatency: true
    property bool inputDebug: false
    property string sortMode: "az"   // "az" | "most_played" | "recent" | "fav_first"
    property var wishlistMap: ({})
    property var descCache: ({})
    property var artCache: ({})
    property var artStageMap: ({})
    property var bgStageMap: ({})
    property int cacheRev: 0

    // Android TV Accessibility Controller Auto-Detector + Fix Guide Modal
    property bool controllerFixOpen: false
    property bool gamepadFaceSeen: false
    property int navWithoutFaceCount: 0
    property bool accessHintShown: false

    // Toast, clock, screensaver, splash, launch warp & roulette state
    property string toastText: ""
    property bool toastVisible: false
    property string clockText: ""
    property bool screensaverActive: false
    property bool splashActive: false
    property bool splashDismissing: false
    property real splashBarProgress: 0.0
    property bool launching: false
    property real launchScale: 1.0
    property real launchPhase: 0.0
    property real launchFade: 0.0
    property var pendingGame: null
    property bool rouletteRunning: false
    property int rouletteStep: 0
    property int rouletteTarget: 0
    property real badgePopScale: 1.0
    property real l1Pulse: 0.0
    property real r1Pulse: 0.0
    property real actionRippleScale: 0.85
    property real actionRippleOpacity: 0.0

    // Audio pre-warm, keep-alive, lazy index & throttling state
    property double lastHNavMs: 0
    property double lastVNavMs: 0
    property double lastTabMs: 0
    property int movePoolIdx: 0
    property int keyPoolIdx: 0
    property var soundCooldowns: ({})
    property bool appActive: true
    property bool gameRunning: false
    property bool keepAliveWanted: lowLatency && soundsOn && appActive && !gameRunning && !screensaverActive && !launching
    property var warmed: ({})
    property int warmTicks: 0
    property bool bootChimePending: false
    property bool hubReady: false
    property bool indexReady: false
    property var libGames: []
    property var libSearch: []
    property var libShort: []

    // ------------------------------------------------------------------
    // 2. Sizing & Formatting Helpers
    // ------------------------------------------------------------------

    function sz(n) { return Math.round(n * ui * couchBoost); }
    function px(n) { return Math.round(n * ui); }

    function themeFor(key) {
        var k = (key || "").toLowerCase();
        if (k === "megadrive") k = "genesis";
        if (k === "sms") k = "mastersystem";
        if (k === "favorites")    return { c1: "#6b4700", c2: "#e0a100", accent: "#ffd644", badge: "FAVORITES", tag: "MY TOP PICKS" };
        if (k === "recent")       return { c1: "#5c1b4e", c2: "#b02f8e", accent: "#ff7ad1", badge: "RECENT", tag: "JUMP BACK IN" };
        if (k === "all")          return { c1: "#0c28b8", c2: "#2454ff", accent: "#6694ff", badge: "COLLECTION", tag: "ALL RETRO GAMES" };
        if (k === "n64")          return { c1: "#005c3b", c2: "#00a86b", accent: "#38e89e", badge: "NINTENDO 64", tag: "64-BIT ERA" };
        if (k === "nes")          return { c1: "#8f0e1c", c2: "#e6192e", accent: "#ff5c6c", badge: "NES", tag: "8-BIT CLASSIC" };
        if (k === "snes")         return { c1: "#421c7a", c2: "#7a42d1", accent: "#b388ff", badge: "SUPER NINTENDO", tag: "16-BIT ERA" };
        if (k === "gba")          return { c1: "#291c8a", c2: "#5c45ff", accent: "#9182ff", badge: "GAME BOY ADVANCE", tag: "32-BIT HANDHELD" };
        if (k === "gbc")          return { c1: "#005f6b", c2: "#00b4d8", accent: "#5ce1e6", badge: "GAME BOY COLOR", tag: "8-BIT COLOR" };
        if (k === "gb")           return { c1: "#334d11", c2: "#6a9923", accent: "#a3d94c", badge: "GAME BOY", tag: "DMG CLASSIC" };
        if (k === "genesis")      return { c1: "#002b80", c2: "#0066ff", accent: "#4da3ff", badge: "SEGA GENESIS", tag: "16-BIT BLAST" };
        if (k === "mastersystem") return { c1: "#6e0f22", c2: "#c91e42", accent: "#ff5c7c", badge: "MASTER SYSTEM", tag: "8-BIT SEGA" };
        return { c1: "#0c28b8", c2: "#2454ff", accent: "#6694ff", badge: k.toUpperCase(), tag: "RETRO SYSTEM" };
    }

    function repoFor(key) {
        var k = (key || "").toLowerCase();
        if (k === "nes" || k === "famicom") return "Nintendo_-_Nintendo_Entertainment_System";
        if (k === "snes" || k === "sfc") return "Nintendo_-_Super_Nintendo_Entertainment_System";
        if (k === "n64") return "Nintendo_-_Nintendo_64";
        if (k === "gba") return "Nintendo_-_Game_Boy_Advance";
        if (k === "gbc") return "Nintendo_-_Game_Boy_Color";
        if (k === "gb") return "Nintendo_-_Game_Boy";
        if (k === "nds" || k === "ds") return "Nintendo_-_Nintendo_DS";
        if (k === "genesis" || k === "megadrive" || k === "md") return "Sega_-_Mega_Drive_-_Genesis";
        if (k === "mastersystem" || k === "sms") return "Sega_-_Master_System_-_Mark_III";
        if (k === "gamegear" || k === "gg") return "Sega_-_Game_Gear";
        if (k === "dreamcast" || k === "dc") return "Sega_-_Dreamcast";
        if (k === "psx" || k === "ps1" || k === "playstation") return "Sony_-_PlayStation";
        if (k === "psp") return "Sony_-_PlayStation_Portable";
        if (k === "arcade" || k === "mame") return "MAME";
        if (k === "fba" || k === "fbneo") return "FBNeo_-_Arcade_Games";
        if (k === "neogeo") return "SNK_-_Neo_Geo";
        if (k === "pce" || k === "tg16") return "NEC_-_PC_Engine_-_TurboGrafx_16";
        if (k === "atari2600") return "Atari_-_2600";
        return "";
    }

    function ratioFor(key) {
        if (key === "n64" || key === "snes") return 1.26;
        if (key === "gba" || key === "gb" || key === "gbc") return 0.96;
        return 0.72;
    }

    function cleanTitle(t) {
        var s = (t || "");
        var c = s.replace(/\s*[\(\[].*?[\)\]]/g, "").replace(/\s+/g, " ").trim();
        return c.length > 0 ? c : s;
    }

    function gameKey(g) {
        if (!g) return "";
        return (gameShortName(g) + "::" + (g.title || "")).toLowerCase();
    }

    function letterOf(g) {
        var c = g ? cleanTitle(g.title).charAt(0).toUpperCase() : "";
        return (c >= "A" && c <= "Z") ? c : "#";
    }

    function lastPlayedMs(g) {
        if (!g || !g.lastPlayed) return 0;
        var t = new Date(g.lastPlayed).getTime();
        return (isNaN(t) || t < 0) ? 0 : t;
    }

    function formatPlayTime(sec) {
        var s = Number(sec || 0);
        if (isNaN(s) || s <= 0) return "";
        if (s < 60) return "< 1m";
        var mins = Math.floor(s / 60);
        if (mins < 60) return mins + "m";
        var hrs = Math.floor(mins / 60);
        var rem = mins % 60;
        return hrs + "h " + rem + "m";
    }

    function formatLastPlayed(g) {
        var ms = lastPlayedMs(g);
        if (ms <= 0) return "";
        return Qt.formatDate(new Date(ms), "MMM d, yyyy");
    }

    function sortLabel(mode) {
        if (mode === "most_played") return "MOST PLAYED";
        if (mode === "recent") return "RECENTLY PLAYED";
        if (mode === "fav_first") return "FAVORITES FIRST";
        return "A - Z";
    }

    function currentTabObj() {
        if (tabList.length > 0 && tabIndex >= 0 && tabIndex < tabList.length) return tabList[tabIndex];
        return { key: "all", label: "COLLECTION", colIndex: -1 };
    }

    function activeTheme() {
        if (activeView === "hub") return { c1: "#0c2478", c2: "#1f54e6", accent: "#66aaff", badge: "DISCOVERY", tag: "CURATED HUB" };
        if (activeView === "search") return { c1: "#0b385c", c2: "#1274a8", accent: "#5cd6ff", badge: "SEARCH", tag: "KEYWORD FINDER" };
        return themeFor(currentTabObj().key);
    }

    function gameShortName(g) {
        if (g && g.collections && g.collections.count > 0) {
            var c = g.collections.get(0);
            if (c) return (c.shortName || "").toLowerCase();
        }
        return "";
    }

    function activeMainGame() {
        var idx = gridMode ? gridView.currentIndex : carousel.currentIndex;
        if (currentGames.length > 0 && idx >= 0 && idx < currentGames.length) {
            return currentGames[idx];
        }
        return null;
    }

    function gameLocalArt(g) {
        if (!g || !g.assets) return "";
        if (g.assets.boxFront) return g.assets.boxFront;
        if (g.assets.poster) return g.assets.poster;
        if (g.assets.banner) return g.assets.banner;
        if (g.assets.screenshot) return g.assets.screenshot;
        return "";
    }

    function libretroUrlForStage(g, stage) {
        if (!g) return "";
        var repo = repoFor(gameShortName(g));
        if (!repo) return "";
        var title = cleanTitle(g.title).replace(/[&*\/:`<>?\\|"]/g, "_");
        if (!title) return "";
        var suffixes = [" (USA)", " (USA, Europe)", " (World)", " (Europe)", " (Japan)"];
        if (stage < 0 || stage >= suffixes.length) return "";
        return "https://raw.githubusercontent.com/libretro-thumbnails/" + repo + "/master/Named_Boxarts/"
               + encodeURIComponent(title + suffixes[stage]) + ".png";
    }

    function wikiArtFor(g, rev) {
        if (!g || !onlineFetchOn) return "";
        var k = gameKey(g);
        if (artCache[k]) return artCache[k];
        var memArt = String(memGet("ra_art_" + k, ""));
        if (memArt.length > 0) {
            artCache[k] = memArt;
            return memArt;
        }
        return "";
    }

    function artStageOf(g) {
        if (!g) return 0;
        var st = artStageMap[gameKey(g)];
        return (st === undefined || st === null) ? 0 : st;
    }

    function advanceArtStage(g) {
        if (!g) return 6;
        var k = gameKey(g);
        var next = artStageOf(g) + 1;
        artStageMap[k] = next;
        if (next === 5 && onlineFetchOn) {
            fetchOnlineMeta(g);
        }
        return next;
    }

    // Multi-stage zero-key cover loader:
    // Local art -> Libretro GitHub Raw (USA -> USA,Europe -> World -> Europe -> Japan) -> Wikipedia thumb -> Monogram tile
    function gameBoxArt(g, rev, stage) {
        if (!g) return "";
        var local = gameLocalArt(g);
        if (local) return local;
        if (!onlineFetchOn) return "";
        var st = (typeof stage === "number") ? stage : artStageOf(g);
        if (st >= 0 && st <= 4) {
            var url = libretroUrlForStage(g, st);
            if (url) return url;
        }
        if (st <= 5) return wikiArtFor(g, rev);
        return "";
    }

    function libretroSnapUrl(g, stage) {
        if (!g) return "";
        var repo = repoFor(gameShortName(g));
        if (!repo) return "";
        var title = cleanTitle(g.title).replace(/[&*\/:`<>?\\|"]/g, "_");
        if (!title) return "";
        var suffixes = [" (USA)", " (USA, Europe)", " (World)", " (Europe)", " (Japan)"];
        if (stage < 0 || stage >= suffixes.length) return "";
        return "https://raw.githubusercontent.com/libretro-thumbnails/" + repo + "/master/Named_Snaps/"
               + encodeURIComponent(title + suffixes[stage]) + ".png";
    }

    function bgStageOf(g) {
        if (!g) return 0;
        var st = bgStageMap[gameKey(g)];
        return (st === undefined || st === null) ? 0 : st;
    }

    function advanceBgStage(g) {
        if (!g) return 6;
        var k = gameKey(g);
        var next = bgStageOf(g) + 1;
        bgStageMap[k] = next;
        return next;
    }

    // Cinema Backdrop Resolver:
    // 1) Local background/screenshot/banner -> 2) Libretro Named_Snaps (5 regions) -> 3) Game box art / Wikipedia thumb
    function gameBackdrop(g, rev, stage) {
        if (!g) return "";
        if (g.assets) {
            if (g.assets.background) return g.assets.background;
            if (g.assets.screenshot) return g.assets.screenshot;
            if (g.assets.banner) return g.assets.banner;
        }
        var st = (typeof stage === "number") ? stage : bgStageOf(g);
        if (onlineFetchOn && st >= 0 && st <= 4) {
            var snap = libretroSnapUrl(g, st);
            if (snap) return snap;
        }
        // Fallback to local or cached box art so no game has a blank backdrop
        if (st <= 5) {
            var box = gameBoxArt(g, rev, artStageOf(g));
            if (box) return box;
        }
        return "";
    }

    function gameDescription(g, rev) {
        if (!g) return "";
        if (g.description && g.description.trim().length > 0) return g.description.trim();
        if (g.summary && g.summary.trim().length > 0) return g.summary.trim();
        var k = gameKey(g);
        if (descCache[k]) return descCache[k];
        var saved = memGet("ra_desc_" + k, "");
        if (saved) {
            descCache[k] = saved;
            return saved;
        }
        return "";
    }

    function isWishlisted(g, rev) {
        if (!g) return false;
        return !!wishlistMap[gameKey(g)];
    }

    function showToast(msg) {
        toastText = msg;
        toastVisible = true;
        toastTimer.restart();
    }

    function updateClock() {
        clockText = Qt.formatTime(new Date(), "hh:mm AP");
    }

    // ------------------------------------------------------------------
    // 3. Safe api.memory Persistence
    // ------------------------------------------------------------------

    function memGet(key, fallback) {
        try {
            if (api.memory && api.memory.has && api.memory.has(key)) {
                var v = api.memory.get(key);
                if (v !== undefined && v !== null) return v;
            } else if (api.memory && api.memory.get) {
                var v2 = api.memory.get(key);
                if (v2 !== undefined && v2 !== null && v2 !== "") return v2;
            }
        } catch (e) { }
        return fallback;
    }

    function memSet(key, val) {
        try {
            if (api.memory && api.memory.set) api.memory.set(key, val);
        } catch (e) { }
    }

    function loadSettings() {
        soundsOn = (Number(memGet("gamedeck_sounds", 1)) !== 0);
        onlineFetchOn = (Number(memGet("ra_online_fetch", 1)) !== 0);
        lowLatency = (Number(memGet("ra_lowlat", 1)) !== 0);
        gamepadFaceSeen = (Number(memGet("ra_face_ok", 0)) === 1);

        var sm = String(memGet("ra_sort_mode", "az"));
        if (sm === "az" || sm === "most_played" || sm === "recent" || sm === "fav_first") sortMode = sm;

        gridMode = (Number(memGet("ra_grid_mode", 0)) === 1);

        var wlRaw = String(memGet("ra_wishlist", ""));
        var map = {};
        if (wlRaw.length > 0) {
            var parts = wlRaw.split("\n");
            for (var i = 0; i < parts.length; i++) {
                if (parts[i].length > 0) map[parts[i]] = true;
            }
        }
        wishlistMap = map;
    }

    function saveWishlist() {
        var keys = [];
        for (var k in wishlistMap) {
            if (wishlistMap.hasOwnProperty(k) && wishlistMap[k]) keys.push(k);
        }
        memSet("ra_wishlist", keys.join("\n"));
    }

    // ------------------------------------------------------------------
    // 4. 15-Sound Crisp Gamedeck Audio Engine (Round-Robin + Pre-Warm + Keep-Alive)
    // ------------------------------------------------------------------

    function warmTick() {
        warmTicks++;
        var order = [
            ["boot", sndBoot],
            ["move0", sndMove0], ["move1", sndMove1], ["move2", sndMove2],
            ["move_vert", sndMoveVert], ["tab", sndTab],
            ["select", sndSelect], ["back", sndBack],
            ["drawer_open", sndDrawerOpen], ["drawer_close", sndDrawerClose],
            ["fav", sndFav], ["wishlist", sndWishlist],
            ["key0", sndKey0], ["key1", sndKey1],
            ["launch", sndLaunch], ["rtick", sndRouletteTick], ["rwin", sndRouletteWin]
        ];
        var pending = 0;
        var didOne = false;
        for (var i = 0; i < order.length; i++) {
            var nm = order[i][0];
            var s = order[i][1];
            if (warmed[nm]) continue;
            if (!s || s.status === SoundEffect.Error) { warmed[nm] = true; continue; }
            if (s.status !== SoundEffect.Ready) { pending++; continue; }
            if (didOne) { pending++; continue; }
            warmed[nm] = true;
            didOne = true;
            if (nm === "boot" && bootChimePending && splashActive) {
                bootChimePending = false;
                try { if (!s.playing) s.play(); } catch (e0) { }
            } else {
                try { s.volume = 0.0; s.play(); } catch (e1) { }
                audioRestoreTimer.restart();
            }
        }
        applyKeepAlive();
        if (pending === 0 || warmTicks > 65) warmTimer.stop();
    }

    function warmAudio() {
        if (!soundsOn) return;
        warmed = ({});
        warmTicks = 0;
        warmTimer.restart();
        warmTick();
    }

    function restoreAudioVolumes() {
        sndMove0.volume = 0.68;
        sndMove1.volume = 0.68;
        sndMove2.volume = 0.68;
        sndKey0.volume = 0.58;
        sndKey1.volume = 0.58;
        sndMoveVert.volume = 0.64;
        sndTab.volume = 0.74;
        sndSelect.volume = 0.80;
        sndBack.volume = 0.72;
        sndFav.volume = 0.82;
        sndWishlist.volume = 0.80;
        sndDrawerOpen.volume = 0.76;
        sndDrawerClose.volume = 0.72;
        sndLaunch.volume = 0.88;
        sndBoot.volume = 0.86;
        sndRouletteTick.volume = 0.74;
        sndRouletteWin.volume = 0.86;
    }

    function applyKeepAlive() {
        try {
            if (keepAliveWanted) {
                if (sndKeep.status === SoundEffect.Ready && !sndKeep.playing) sndKeep.play();
            } else if (sndKeep.playing) {
                sndKeep.stop();
            }
        } catch (e) { }
    }

    function playMove() {
        var pool = [sndMove0, sndMove1, sndMove2];
        for (var i = 0; i < 3; i++) {
            var idx = (movePoolIdx + i) % 3;
            var s = pool[idx];
            try {
                if (s.status === SoundEffect.Ready && !s.playing) {
                    movePoolIdx = (idx + 1) % 3;
                    s.play();
                    return;
                }
            } catch (e) { }
        }
    }

    function playKeyTap() {
        var pool = [sndKey0, sndKey1];
        for (var i = 0; i < 2; i++) {
            var idx = (keyPoolIdx + i) % 2;
            var s = pool[idx];
            try {
                if (s.status === SoundEffect.Ready && !s.playing) {
                    keyPoolIdx = (idx + 1) % 2;
                    s.play();
                    return;
                }
            } catch (e) { }
        }
    }

    function playSound(name) {
        if (!soundsOn) return;
        var cd = 0;
        if (name === "move") cd = 135;
        else if (name === "move_vert") cd = 105;
        else if (name === "tab") cd = 165;
        else if (name === "key_tap") cd = 45;
        if (cd > 0) {
            var now = Date.now();
            if (now - (soundCooldowns[name] || 0) < cd) return;
            soundCooldowns[name] = now;
        }

        if (name === "move") { playMove(); return; }
        if (name === "key_tap") { playKeyTap(); return; }

        var s = null;
        if (name === "move_vert")         s = sndMoveVert;
        else if (name === "tab")          s = sndTab;
        else if (name === "select")       s = sndSelect;
        else if (name === "back")         s = sndBack;
        else if (name === "fav")          s = sndFav;
        else if (name === "wishlist")     s = sndWishlist;
        else if (name === "drawer_open")  s = sndDrawerOpen;
        else if (name === "drawer_close") s = sndDrawerClose;
        else if (name === "launch")       s = sndLaunch;
        else if (name === "boot")         s = sndBoot;
        else if (name === "roulette_tick") s = sndRouletteTick;
        else if (name === "roulette_win")  s = sndRouletteWin;

        if (s && s.status === SoundEffect.Ready) {
            try {
                if (!s.playing) s.play();
            } catch (e) { }
        }
    }

    // ------------------------------------------------------------------
    // 5. Online Auto-Description & Wikipedia Artwork Fallback (Zero Keys)
    // ------------------------------------------------------------------

    property var pendingFetchGame: null
    property var fetchedKeys: ({})

    function scheduleOnlineFetch(g, immediate) {
        if (!onlineFetchOn || !g) return;
        if (gameDescription(g, cacheRev).length > 0 && (gameLocalArt(g) !== "" || artCache[gameKey(g)])) return;
        pendingFetchGame = g;
        if (immediate) {
            onlineFetchTimer.stop();
            fetchOnlineMeta(g);
        } else {
            onlineFetchTimer.restart();
        }
    }

    function fetchOnlineMeta(g) {
        if (!onlineFetchOn || !g) return;
        var k = gameKey(g);
        if (fetchedKeys[k]) return;
        fetchedKeys[k] = true;

        var title = cleanTitle(g.title);
        if (!title || title.length < 2) return;

        try {
            var xhr = new XMLHttpRequest();
            var url = "https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts%7Cpageimages&exintro=1&explaintext=1&exsentences=2&pithumbsize=400&generator=search&gsrlimit=1&gsrsearch="
                      + encodeURIComponent(title + " video game");
            xhr.onreadystatechange = function() {
                if (xhr.readyState !== XMLHttpRequest.DONE) return;
                if (xhr.status !== 200) return;
                try {
                    var data = JSON.parse(xhr.responseText);
                    if (!data || !data.query || !data.query.pages) return;
                    var pages = data.query.pages;
                    for (var pid in pages) {
                        if (!pages.hasOwnProperty(pid)) continue;
                        var p = pages[pid];
                        var changed = false;
                        if (p.extract && p.extract.trim().length > 20) {
                            var cleanDesc = p.extract.replace(/\s+/g, " ").trim();
                            descCache[k] = cleanDesc;
                            memSet("ra_desc_" + k, cleanDesc);
                            changed = true;
                        }
                        if (p.thumbnail && p.thumbnail.source && !gameLocalArt(g)) {
                            artCache[k] = p.thumbnail.source;
                            memSet("ra_art_" + k, p.thumbnail.source);
                            changed = true;
                        }
                        if (changed) cacheRev++;
                        break;
                    }
                } catch (e2) { }
            };
            xhr.open("GET", url, true);
            xhr.send();
        } catch (e) { }
    }

    // ------------------------------------------------------------------
    // 6. Tabs, Fast Decorate-Sort & Whole-Word Discovery Hub Indexing
    // ------------------------------------------------------------------

    function buildTabs() {
        var list = [
            { key: "favorites", label: "★ FAVORITES", colIndex: -2 },
            { key: "recent",    label: "RECENT",      colIndex: -3 }
        ];
        for (var i = 0; i < api.collections.count; i++) {
            var c = api.collections.get(i);
            var sn = (c.shortName || "").toLowerCase();
            var t = themeFor(sn);
            list.push({ key: sn, label: t.badge, colIndex: i });
        }
        tabList = list;
        // Start directly on the first console tab (no heavy 1,000+ All-Games tab lag)
        tabIndex = (list.length > 2) ? 2 : 0;
    }

    function sortGameList(list, skipSort, forceAz) {
        if (skipSort || list.length < 2) return list;
        var mode = forceAz ? "az" : sortMode;
        var items = [];
        for (var i = 0; i < list.length; i++) {
            var g = list[i];
            items.push({
                g: g,
                t: cleanTitle(g.title).toLowerCase(),
                pc: Number(g.playCount) || 0,
                pt: Number(g.playTime) || 0,
                lp: lastPlayedMs(g),
                fav: g.favorite ? 1 : 0
            });
        }
        items.sort(function(a, b) {
            var d = 0;
            if (mode === "most_played") d = (b.pc - a.pc) || (b.pt - a.pt);
            else if (mode === "recent") d = b.lp - a.lp;
            else if (mode === "fav_first") d = b.fav - a.fav;
            if (d !== 0) return d;
            return a.t < b.t ? -1 : (a.t > b.t ? 1 : 0);
        });
        for (var j = 0; j < items.length; j++) list[j] = items[j].g;
        return list;
    }

    function applyMainIndex(idx) {
        if (currentGames.length === 0) return;
        var i = Math.max(0, Math.min(idx, currentGames.length - 1));
        carousel.currentIndex = i;
        gridView.currentIndex = i;
        carousel.positionViewAtIndex(i, ListView.Beginning);
        gridView.positionViewAtIndex(i, GridView.Contain);
        scheduleOnlineFetch(currentGames[i], false);
    }

    function refreshGames(keepIndex, targetTitle, targetKey) {
        var tab = currentTabObj();
        var list = [];

        if (tab.colIndex === -2) {
            for (var i = 0; i < api.allGames.count; i++) {
                var g = api.allGames.get(i);
                if (g.favorite) list.push(g);
            }
            sortGameList(list, false);
        } else if (tab.colIndex === -3) {
            var played = [];
            for (var r = 0; r < api.allGames.count; r++) {
                var rg = api.allGames.get(r);
                var ms = lastPlayedMs(rg);
                if (ms > 0) played.push({ game: rg, ms: ms });
            }
            played.sort(function(a, b) { return b.ms - a.ms; });
            var cap = Math.min(played.length, 30);
            for (var m = 0; m < cap; m++) list.push(played[m].game);
        } else if (tab.colIndex === -1) {
            for (var j = 0; j < api.allGames.count; j++) list.push(api.allGames.get(j));
            sortGameList(list, false);
        } else if (tab.colIndex >= 0) {
            var col = api.collections.get(tab.colIndex);
            if (col) {
                for (var k = 0; k < col.games.count; k++) list.push(col.games.get(k));
            }
            sortGameList(list, false);
        }

        var letters = [];
        var foundIdx = -1;
        var foundTitleIdx = -1;
        for (var q = 0; q < list.length; q++) {
            letters.push(letterOf(list[q]));
            if (targetKey && foundIdx === -1 && gameKey(list[q]) === targetKey) foundIdx = q;
            if (targetTitle && foundTitleIdx === -1 && list[q].title === targetTitle) foundTitleIdx = q;
        }
        if (foundIdx < 0) foundIdx = foundTitleIdx;

        var prevIdx = gridMode ? gridView.currentIndex : carousel.currentIndex;
        currentLetters = letters;
        currentGames = list;

        var destIdx = 0;
        if (foundIdx >= 0) destIdx = foundIdx;
        else if (keepIndex) destIdx = prevIdx;

        Qt.callLater(applyMainIndex, destIdx);
    }

    function switchTab(delta, rep) {
        if (tabList.length === 0) return;
        var now = Date.now();
        if (rep && now - lastTabMs < 180) return;
        lastTabMs = now;
        tabIndex = (tabIndex + delta + tabList.length) % tabList.length;
        if (delta < 0) l1PulseAnim.restart();
        else r1PulseAnim.restart();
        refreshGames(false, "", "");
        tabCascadeAnim.restart();
        if (!rep) playSound("tab");
    }

    function norm(s) {
        return ("" + (s || "")).toLowerCase().replace(/[éèêë]/g, "e").replace(/['’`]/g, "").replace(/\s+/g, " ").trim();
    }

    function buildPattern(key) {
        var k = norm(key).split(".").join("\\.");
        return new RegExp("(^|[^a-z0-9])" + k + "(s)?([^a-z0-9]|$)");
    }

    function matchAny(patterns, text) {
        for (var i = 0; i < patterns.length; i++) {
            if (patterns[i].test(text)) return true;
        }
        return false;
    }

    function isRomanTok(w) {
        return /^(ii|iii|iv|v|vi|vii|viii|ix|x|xi|xii)$/.test(w);
    }

    function gamePlayersOf(g) {
        var p = (g && g.players) ? Number(g.players) : 0;
        return isNaN(p) ? 0 : p;
    }

    function baseSeriesName(n) {
        var s = n;
        var c1 = s.indexOf(":");
        if (c1 > 0) s = s.substring(0, c1);
        var c2 = s.indexOf(" - ");
        if (c2 > 0) s = s.substring(0, c2);
        var words = s.split(" ");
        var out = [];
        for (var i = 0; i < words.length; i++) {
            var w = words[i];
            if (i > 0 && (/^\d+$/.test(w) || isRomanTok(w) || w === "part" || w === "vol" || w === "volume" || w === "dx" || w === "advance")) break;
            out.push(w);
        }
        return out.join(" ").replace(/^the\s+/, "").replace(/,\s*the$/, "").replace(/\s+/g, " ").trim();
    }

    function ensureIndex() {
        if (!indexReady) buildDiscoveryHub();
    }

    function buildDiscoveryHub() {
        var popularKeys = [
            "super mario bros", "super mario world", "super mario 64", "mario kart", "legend of zelda",
            "ocarina of time", "majoras mask", "metroid", "contra", "mega man", "castlevania",
            "sonic the hedgehog", "donkey kong", "final fantasy", "chrono trigger", "street fighter",
            "goldeneye", "banjo", "kirby", "earthbound", "bomberman", "ninja gaiden", "metal gear",
            "pokemon", "punch-out", "ducktales", "duck tales", "tetris", "double dragon",
            "turtles in time", "battletoads", "f-zero", "star fox", "smash bros"
        ];
        var mpKeys = [
            "mario kart", "mario party", "contra", "super c", "double dragon", "battletoads",
            "teenage mutant ninja turtles", "turtles in time", "street fighter", "mortal kombat",
            "killer instinct", "goldeneye", "bomberman", "bubble bobble", "tecmo bowl",
            "tecmo super bowl", "nba", "hockey", "tennis", "golf", "smash bros", "dodge ball",
            "river city ransom", "chip n dale", "micro machines", "world cup", "wrestling",
            "sunset riders", "knights of the round", "king of dragons", "zombies ate my neighbors",
            "joe & mac", "pocky & rocky", "rock n roll racing", "top gear", "diddy kong racing",
            "snowboard", "1080", "f-zero"
        ];
        var knownSeries = [
            { name: "MARIO", keys: ["mario", "yoshi", "wario"] },
            { name: "FINAL FANTASY", keys: ["final fantasy"] },
            { name: "THE LEGEND OF ZELDA", keys: ["zelda"] },
            { name: "MEGA MAN", keys: ["mega man", "megaman", "rockman"] },
            { name: "SONIC", keys: ["sonic"] },
            { name: "CASTLEVANIA", keys: ["castlevania"] },
            { name: "DONKEY KONG", keys: ["donkey kong"] },
            { name: "KIRBY", keys: ["kirby"] },
            { name: "CONTRA", keys: ["contra", "super c", "probotector"] },
            { name: "DRAGON QUEST / WARRIOR", keys: ["dragon quest", "dragon warrior"] },
            { name: "BOMBERMAN", keys: ["bomberman"] },
            { name: "NINJA TURTLES", keys: ["teenage mutant ninja turtles", "teenage mutant hero turtles", "turtles in time", "tmnt"] },
            { name: "STREET FIGHTER", keys: ["street fighter"] },
            { name: "METROID", keys: ["metroid"] },
            { name: "POKEMON", keys: ["pokemon"] },
            { name: "FIRE EMBLEM", keys: ["fire emblem"] },
            { name: "DOUBLE DRAGON", keys: ["double dragon"] },
            { name: "NINJA GAIDEN", keys: ["ninja gaiden"] },
            { name: "ADVENTURE ISLAND", keys: ["adventure island"] },
            { name: "BATMAN", keys: ["batman"] },
            { name: "BATTLETOADS", keys: ["battletoads"] },
            { name: "MORTAL KOMBAT", keys: ["mortal kombat"] },
            { name: "GANBARE GOEMON", keys: ["goemon", "mystical ninja"] },
            { name: "WONDER BOY", keys: ["wonder boy"] },
            { name: "METAL GEAR", keys: ["metal gear"] },
            { name: "STAR FOX", keys: ["star fox"] },
            { name: "F-ZERO", keys: ["f-zero", "f zero"] },
            { name: "SMASH BROS", keys: ["smash bros"] },
            { name: "TETRIS", keys: ["tetris"] },
            { name: "PAC-MAN", keys: ["pac-man", "pac man", "pacman"] },
            { name: "GOLDEN AXE", keys: ["golden axe"] },
            { name: "STREETS OF RAGE", keys: ["streets of rage"] }
        ];
        var seriesStop = { "super": 1, "the": 1, "game": 1, "mega": 1, "big": 1, "little": 1, "new": 1, "street": 1, "world": 1, "dragon": 1 };

        var total = api.allGames.count;
        var games = [];
        var search = [];
        var names = [];
        var shorts = [];
        for (var i = 0; i < total; i++) {
            var g0 = api.allGames.get(i);
            games.push(g0);
            search.push(norm(g0 ? g0.title : ""));
            names.push(norm(cleanTitle(g0 ? g0.title : "")));
            shorts.push(gameShortName(g0));
        }
        libGames = games;
        libSearch = search;
        libShort = shorts;

        var popRe = [];
        var popBuckets = [];
        for (var p = 0; p < popularKeys.length; p++) { popRe.push(buildPattern(popularKeys[p])); popBuckets.push([]); }
        var mpRe = [];
        for (var m = 0; m < mpKeys.length; m++) mpRe.push(buildPattern(mpKeys[m]));
        var serRe = [];
        for (var s = 0; s < knownSeries.length; s++) {
            var res = [];
            for (var kk = 0; kk < knownSeries[s].keys.length; kk++) res.push(buildPattern(knownSeries[s].keys[kk]));
            serRe.push(res);
        }

        var mp = [];
        var unp = [];
        var seriesMap = {};
        var assigned = {};
        var latestGame = null;
        var latestMs = 0;

        for (var a = 0; a < total; a++) {
            var g = games[a];
            var low = names[a];

            var ms = lastPlayedMs(g);
            if (ms > latestMs) { latestMs = ms; latestGame = g; }

            if (!(Number(g.playCount) > 0)) unp.push(g);

            if (gamePlayersOf(g) > 1 || matchAny(mpRe, low)) mp.push(g);

            for (var pp = 0; pp < popRe.length; pp++) {
                if (popRe[pp].test(low)) {
                    if (popBuckets[pp].length < 2) popBuckets[pp].push(g);
                    break;
                }
            }

            for (var sx = 0; sx < knownSeries.length; sx++) {
                if (matchAny(serRe[sx], low)) {
                    var nm = knownSeries[sx].name;
                    if (!seriesMap[nm]) seriesMap[nm] = [];
                    seriesMap[nm].push(g);
                    assigned[a] = true;
                    break;
                }
            }
        }

        var autoBuckets = {};
        for (var b = 0; b < total; b++) {
            if (assigned[b]) continue;
            var base = baseSeriesName(names[b]);
            if (base.length < 4 || seriesStop[base]) continue;
            var bKey = base.toUpperCase();
            if (!autoBuckets[bKey]) autoBuckets[bKey] = [];
            autoBuckets[bKey].push(games[b]);
        }
        for (var bk in autoBuckets) {
            if (autoBuckets.hasOwnProperty(bk) && autoBuckets[bk].length >= 2 && !seriesMap[bk]) seriesMap[bk] = autoBuckets[bk];
        }

        var flist = [];
        for (var fn in seriesMap) {
            if (seriesMap.hasOwnProperty(fn) && seriesMap[fn].length >= 2) {
                var arr = seriesMap[fn];
                sortGameList(arr, false, true);
                flist.push({ name: fn, games: arr, count: arr.length, coverGame: arr[0] });
            }
        }
        flist.sort(function(x, y) {
            if (y.count !== x.count) return y.count - x.count;
            return x.name < y.name ? -1 : 1;
        });

        var pop = [];
        for (var q = 0; q < popBuckets.length; q++) {
            for (var r = 0; r < popBuckets[q].length; r++) pop.push(popBuckets[q][r]);
        }

        lastPlayedGame = latestGame;
        popularGames = pop.slice(0, 36);
        multiplayerGames = sortGameList(mp, false, true);
        unplayedGames = sortGameList(unp, false, true);
        franchiseList = flist;
        indexReady = true;
        rebuildHubQuickItems();
    }
    function getWishlistGames() {
        var out = [];
        for (var i = 0; i < api.allGames.count; i++) {
            var g = api.allGames.get(i);
            if (isWishlisted(g, cacheRev)) out.push(g);
        }
        return sortGameList(out, false, true);
    }

    function rebuildHubQuickItems() {
        var items = [];
        if (lastPlayedGame) {
            items.push({ id: "continue", title: "CONTINUE", subtitle: cleanTitle(lastPlayedGame.title), accent: "#38e89e", icon: "▶" });
        }
        items.push({ id: "search",      title: "KEYWORD SEARCH", subtitle: "ALL CONSOLES", accent: "#5cd6ff", icon: "Y" });
        items.push({ id: "multiplayer", title: "MULTIPLAYER",    subtitle: multiplayerGames.length + " GAMES", accent: "#ff7a45", icon: "2P" });
        items.push({ id: "wishlist",    title: "WISHLIST",       subtitle: getWishlistGames().length + " SAVED", accent: "#ff66b3", icon: "♡" });
        items.push({ id: "unplayed",    title: "UNPLAYED GEMS",  subtitle: unplayedGames.length + " UNTOUCHED", accent: "#b388ff", icon: "NEW" });
        hubQuickItems = items;
        if (hubQuickIdx >= items.length) hubQuickIdx = Math.max(0, items.length - 1);
    }

    // ------------------------------------------------------------------
    // 7. Navigation, Actions, Search & Roulette
    // ------------------------------------------------------------------

    function resetIdle() {
        if (screensaverActive) screensaverActive = false;
        idleTimer.restart();
    }

    function moveMainCarousel(dir, isRepeat) {
        var now = Date.now();
        var minGap = isRepeat ? 165 : 95;
        if (now - lastHNavMs < minGap) return;
        lastHNavMs = now;

        var before = carousel.currentIndex;
        if (dir < 0) carousel.decrementCurrentIndex();
        else carousel.incrementCurrentIndex();
        if (carousel.currentIndex !== before) {
            gridView.currentIndex = carousel.currentIndex;
            playSound("move");
            scheduleOnlineFetch(activeMainGame(), false);
        }
    }

    function moveGrid(dx, dy, isRepeat) {
        var now = Date.now();
        var minGap = isRepeat ? 150 : 80;
        if (now - lastHNavMs < minGap) return;
        lastHNavMs = now;

        var n = currentGames.length;
        if (n === 0) return;
        var cols = 5;
        var cur = gridView.currentIndex;
        if (dy < 0 && cur < cols) {
            if (!isRepeat) openHub();
            return;
        }
        var next = cur + dx + dy * cols;
        if (next < 0) next = 0;
        if (next >= n) next = n - 1;
        if (next !== cur) {
            gridView.currentIndex = next;
            carousel.currentIndex = next;
            gridView.positionViewAtIndex(next, GridView.Contain);
            playSound(dy !== 0 ? "move_vert" : "move");
            scheduleOnlineFetch(activeMainGame(), false);
        }
    }

    function groupStart(idx) {
        var L = currentLetters[idx];
        while (idx > 0 && currentLetters[idx - 1] === L) idx--;
        return idx;
    }

    function jumpLetter(dir) {
        var n = currentGames.length;
        if (n < 2) return;
        var i = gridMode ? gridView.currentIndex : carousel.currentIndex;
        var target = i;
        var recent = (currentTabObj().key === "recent" || sortMode !== "az");

        if (recent) {
            target = Math.max(0, Math.min(n - 1, i + dir * 10));
        } else if (dir > 0) {
            var L = currentLetters[i];
            target = i + 1;
            while (target < n && currentLetters[target] === L) target++;
            if (target >= n) target = 0;
        } else {
            var s = groupStart(i);
            if (s < i) target = s;
            else target = groupStart(s === 0 ? n - 1 : s - 1);
        }

        if (target === i) return;
        applyMainIndex(target);
        playSound("tab");
        if (!recent) showToast("JUMP: " + currentLetters[target]);
        else showToast((dir > 0 ? "+10" : "-10") + " GAMES");
    }

    function rebuildActionMenu() {
        if (actionMenuItems.length > 0) return;
        actionMenuItems = [
            { id: "view" }, { id: "roulette" }, { id: "sort" },
            { id: "sounds" }, { id: "lowlat" }, { id: "online" },
            { id: "hub" }, { id: "search" }, { id: "ctrlfix" },
            { id: "debug" }, { id: "settings" }, { id: "close" }
        ];
    }

    function actionLabel(id) {
        if (id === "view")     return gridMode ? "VIEW MODE: POSTER GRID" : "VIEW MODE: GAMEDECK SHELF";
        if (id === "roulette") return "ROULETTE RANDOM GAME";
        if (id === "sort")     return "SORT: " + sortLabel(sortMode);
        if (id === "sounds")   return soundsOn ? "UI SOUNDS: ON" : "UI SOUNDS: OFF";
        if (id === "lowlat")   return lowLatency ? "LOW-LATENCY AUDIO: ON" : "LOW-LATENCY AUDIO: OFF";
        if (id === "online")   return onlineFetchOn ? "ONLINE FETCH: ON" : "ONLINE FETCH: OFF";
        if (id === "hub")      return "OPEN DISCOVERY HUB";
        if (id === "search")   return "KEYWORD SEARCH";
        if (id === "ctrlfix")  return "FIX CONTROLLER (A/B/X/Y)";
        if (id === "debug")    return inputDebug ? "CONTROLLER DEBUG: ON" : "CONTROLLER DEBUG: OFF";
        if (id === "settings") return "SYSTEM SETTINGS";
        return "CLOSE";
    }

    function openActionPanel(g) {
        if (!g) return;
        actionGame = g;
        actionZone = 0;
        actionIconIdx = 0;
        actionListIdx = 0;
        rebuildActionMenu();
        actionOpen = true;
        playSound("drawer_open");
        scheduleOnlineFetch(g, true);
    }

    function closeActionPanel() {
        actionOpen = false;
        playSound("drawer_close");
    }

    function toggleFavoriteFor(g) {
        if (!g) return;
        g.favorite = !g.favorite;
        actionRippleAnim.restart();
        playSound("fav");
        badgePopAnim.restart();
        showToast(g.favorite ? "★ ADDED TO FAVORITES" : "REMOVED FROM FAVORITES");
        cacheRev++;
        if (activeView === "main" && currentTabObj().colIndex === -2) {
            refreshGames(true, "", "");
        }
    }

    function toggleWishlistFor(g) {
        if (!g) return;
        var k = gameKey(g);
        var next = !wishlistMap[k];
        if (next) wishlistMap[k] = true;
        else delete wishlistMap[k];
        saveWishlist();
        cacheRev++;
        rebuildHubQuickItems();
        actionRippleAnim.restart();
        playSound("wishlist");
        badgePopAnim.restart();
        showToast(next ? "♡ ADDED TO WISHLIST" : "REMOVED FROM WISHLIST");
        if (hubSubOpen && hubSubTitle === "WISHLIST") {
            hubSubGames = getWishlistGames();
            if (hubSubIdx >= hubSubGames.length) hubSubIdx = Math.max(0, hubSubGames.length - 1);
            Qt.callLater(syncHubSub);
        }
    }

    function startLaunch(g) {
        if (!g || launching || splashActive) return;
        actionOpen = false;
        launching = true;
        pendingGame = g;
        playSound("launch");

        memSet("ra_returning", 1);
        memSet("ra_last_tab", currentTabObj().key);
        memSet("ra_last_game", g.title);
        memSet("ra_last_gkey", gameKey(g));

        launchFailSafe.restart();
        launchSeqAnim.restart();
    }

    function executePendingLaunch() {
        var g = pendingGame;
        pendingGame = null;
        launchFailSafe.stop();
        launching = false;
        launchScale = 1.0;
        launchPhase = 0.0;
        launchFade = 0.0;
        gameRunning = true;
        gameRunningTimer.restart();
        try { if (sndKeep.playing) sndKeep.stop(); } catch (e) { }
        if (g) g.launch();
    }

    function forceFinishLaunch() {
        if (!launching) return;
        launchSeqAnim.stop();
        executePendingLaunch();
    }

    function forceFinishSplash() {
        splashHoldTimer.stop();
        splashInAnim.stop();
        splashOutAnim.stop();
        splashActive = false;
        splashDismissing = false;
    }

    function startRoulette() {
        var n = currentGames.length;
        if (n < 2) return;
        actionOpen = false;
        activeView = "main";
        hubSubOpen = false;
        rouletteRunning = true;
        rouletteStep = 0;
        rouletteTarget = Math.floor(Math.random() * n);
        if (rouletteTarget === (gridMode ? gridView.currentIndex : carousel.currentIndex)) rouletteTarget = (rouletteTarget + 1) % n;
        rouletteTimer.interval = 42;
        rouletteFailSafe.restart();
        rouletteTimer.restart();
    }

    function stepRoulette() {
        var n = currentGames.length;
        if (n < 2) { rouletteRunning = false; return; }
        rouletteStep++;
        var totalSteps = 8;
        if (rouletteStep < totalSteps) {
            var hop = Math.floor(Math.random() * n);
            applyMainIndex(hop);
            playSound("roulette_tick");
            rouletteTimer.interval = 42 + rouletteStep * 18;
            rouletteTimer.restart();
        } else {
            applyMainIndex(rouletteTarget);
            rouletteRunning = false;
            rouletteFailSafe.stop();
            playSound("roulette_win");
            showToast("RANDOM PICK: " + cleanTitle(currentGames[rouletteTarget].title));
        }
    }

    function activateActionMenu() {
        var item = actionMenuItems[actionListIdx];
        if (!item) return;
        var id = item.id;

        if (id === "sounds") {
            soundsOn = !soundsOn;
            memSet("gamedeck_sounds", soundsOn ? 1 : 0);
            if (soundsOn) { warmAudio(); playSound("select"); }
            return;
        }
        if (id === "lowlat") {
            lowLatency = !lowLatency;
            memSet("ra_lowlat", lowLatency ? 1 : 0);
            playSound("select");
            showToast(lowLatency ? "LOW-LATENCY AUDIO ON" : "LOW-LATENCY AUDIO OFF");
            return;
        }
        if (id === "online") {
            onlineFetchOn = !onlineFetchOn;
            memSet("ra_online_fetch", onlineFetchOn ? 1 : 0);
            playSound("select");
            if (onlineFetchOn && actionGame) scheduleOnlineFetch(actionGame, true);
            return;
        }
        if (id === "ctrlfix") {
            actionOpen = false;
            controllerFixOpen = true;
            playSound("drawer_open");
            return;
        }
        if (id === "debug") {
            inputDebug = !inputDebug;
            playSound("select");
            showToast(inputDebug ? "PRESS ANY CONTROLLER BUTTON TO SEE CODE" : "CONTROLLER DEBUG OFF");
            return;
        }
        if (id === "sort") {
            var modes = ["az", "most_played", "recent", "fav_first"];
            var nextIdx = (modes.indexOf(sortMode) + 1) % modes.length;
            sortMode = modes[nextIdx];
            memSet("ra_sort_mode", sortMode);
            refreshGames(false, actionGame ? actionGame.title : "", actionGame ? gameKey(actionGame) : "");
            playSound("select");
            showToast("SORT: " + sortLabel(sortMode));
            return;
        }
        if (id === "view") {
            var keepIdx = gridMode ? gridView.currentIndex : carousel.currentIndex;
            gridMode = !gridMode;
            memSet("ra_grid_mode", gridMode ? 1 : 0);
            actionOpen = false;
            activeView = "main";
            hubSubOpen = false;
            playSound("tab");
            showToast(gridMode ? "POSTER GRID VIEW" : "GAMEDECK SHELF VIEW");
            Qt.callLater(applyMainIndex, keepIdx);
            return;
        }
        if (id === "roulette") {
            startRoulette();
            return;
        }
        if (id === "hub") {
            actionOpen = false;
            openHub();
            return;
        }
        if (id === "search") {
            actionOpen = false;
            openSearch();
            return;
        }
        if (id === "settings") {
            actionOpen = false;
            playSound("select");
            if (api.menu && api.menu.open) api.menu.open();
            else showToast("PRESS MENU FOR SYSTEM SETTINGS");
            return;
        }
        closeActionPanel();
    }

    // Discovery Hub navigation helpers
    function openHub() {
        ensureIndex();
        hubReady = true;
        rebuildHubQuickItems();
        var ct = [];
        for (var i = 0; i < tabList.length; i++) ct.push({ label: tabList[i].label, idx: i });
        hubConsoleItems = ct;
        hubConsoleIdx = tabIndex;
        hubSection = 0;
        hubSubOpen = false;
        activeView = "hub";
        playSound("drawer_open");
        Qt.callLater(function() { hubConsoleList.currentIndex = hubConsoleIdx; });
    }

    function syncHubSub() {
        if (hubSubGames.length === 0) return;
        var i = Math.max(0, Math.min(hubSubIdx, hubSubGames.length - 1));
        hubSubList.currentIndex = i;
        hubSubList.positionViewAtIndex(i, ListView.Beginning);
    }

    function openHubSub(title, tag, gamesList) {
        hubSubTitle = title;
        hubSubTag = tag;
        hubSubGames = gamesList || [];
        hubSubIdx = 0;
        hubSubOpen = true;
        playSound("select");
        Qt.callLater(syncHubSub);
    }

    function moveHubSub(delta) {
        var n = hubSubGames.length;
        if (n === 0) return;
        var ni = Math.max(0, Math.min(n - 1, hubSubIdx + delta));
        if (ni === hubSubIdx) return;
        hubSubIdx = ni;
        hubSubList.currentIndex = ni;
        playSound("move");
    }

    function hubSectionList() {
        var s = [0];
        if (popularGames.length > 0) s.push(1);
        if (franchiseList.length > 0) s.push(2);
        if (hubConsoleItems.length > 0) s.push(3);
        return s;
    }

    function moveHubRow(dir) {
        if (hubSection === 0 && hubQuickItems.length > 0) {
            var q = Math.max(0, Math.min(hubQuickItems.length - 1, hubQuickIdx + dir));
            if (q !== hubQuickIdx) {
                hubQuickIdx = q;
                hubQuickList.currentIndex = q;
                hubQuickList.positionViewAtIndex(q, ListView.Contain);
                playSound("move");
            }
        } else if (hubSection === 1 && popularGames.length > 0) {
            var p = Math.max(0, Math.min(popularGames.length - 1, hubPopularIdx + dir));
            if (p !== hubPopularIdx) {
                hubPopularIdx = p;
                hubPopularList.currentIndex = p;
                playSound("move");
            }
        } else if (hubSection === 2 && franchiseList.length > 0) {
            var f = Math.max(0, Math.min(franchiseList.length - 1, hubFranchiseIdx + dir));
            if (f !== hubFranchiseIdx) {
                hubFranchiseIdx = f;
                hubFranchiseList.currentIndex = f;
                playSound("move");
            }
        } else if (hubSection === 3 && hubConsoleItems.length > 0) {
            var c = Math.max(0, Math.min(hubConsoleItems.length - 1, hubConsoleIdx + dir));
            if (c !== hubConsoleIdx) {
                hubConsoleIdx = c;
                hubConsoleList.currentIndex = c;
                playSound("move");
            }
        }
    }

    function selectConsoleFromHub(i) {
        if (i < 0 || i >= tabList.length) return;
        tabIndex = i;
        activeView = "main";
        hubSubOpen = false;
        refreshGames(false, "", "");
        tabCascadeAnim.restart();
        playSound("tab");
    }

    function activateHubQuick() {
        var item = hubQuickItems[hubQuickIdx];
        if (!item) return;
        if (item.id === "continue" && lastPlayedGame) {
            startLaunch(lastPlayedGame);
        } else if (item.id === "search") {
            openSearch();
        } else if (item.id === "multiplayer") {
            openHubSub("MULTIPLAYER GAMES", "CO-OP & VERSUS", multiplayerGames);
        } else if (item.id === "wishlist") {
            openHubSub("WISHLIST", "SAVED FOR LATER", getWishlistGames());
        } else if (item.id === "unplayed") {
            openHubSub("UNPLAYED GEMS", "NEVER LAUNCHED", unplayedGames);
        }
    }

    function activateHubSection() {
        if (hubSection === 0) {
            activateHubQuick();
        } else if (hubSection === 1 && popularGames.length > 0) {
            openActionPanel(popularGames[hubPopularIdx]);
        } else if (hubSection === 2 && franchiseList.length > 0) {
            var fr = franchiseList[hubFranchiseIdx];
            if (fr) openHubSub(fr.name + " SERIES", fr.count + " GAMES ACROSS CONSOLES", fr.games);
        } else if (hubSection === 3 && hubConsoleItems.length > 0) {
            selectConsoleFromHub(hubConsoleIdx);
        }
    }

    // Keyword Search Engine helpers
    function openSearch() {
        ensureIndex();
        if (activeView !== "search") searchFrom = (activeView === "hub") ? "hub" : "main";
        activeView = "search";
        searchZone = 0;
        runKeywordSearch();
        playSound("drawer_open");
    }

    function runKeywordSearch() {
        ensureIndex();
        var q = norm(searchQuery);
        var out = [];
        for (var i = 0; i < libGames.length; i++) {
            if (q.length === 0 || libSearch[i].indexOf(q) !== -1 || libShort[i] === q) {
                out.push(libGames[i]);
                if (q.length === 0 && out.length >= 40) break;
            }
        }
        sortGameList(out, false);
        searchResults = out;
        searchResultIdx = 0;
        Qt.callLater(function() {
            if (searchResults.length > 0) searchResultsList.positionViewAtIndex(0, ListView.Beginning);
        });
    }

    function pressVirtualKey(idx) {
        var key = kbKeys[idx];
        if (!key) return;
        kbFlashIdx = idx;
        kbFlashTimer.restart();
        playSound("key_tap");

        if (key === "SPACE") {
            if (searchQuery.length < 28) searchQuery += " ";
            runKeywordSearch();
        } else if (key === "DEL") {
            if (searchQuery.length > 0) searchQuery = searchQuery.slice(0, -1);
            runKeywordSearch();
        } else if (key === "CLEAR") {
            searchQuery = "";
            runKeywordSearch();
        } else if (key === "RESULTS") {
            if (searchResults.length > 0) {
                searchZone = 1;
                playSound("select");
            } else {
                showToast("NO MATCHING GAMES");
            }
        } else {
            if (searchQuery.length < 28) searchQuery += key;
            runKeywordSearch();
        }
    }

    function navGate(rep) {
        var now = Date.now();
        if (rep && now - lastVNavMs < 130) return false;
        lastVNavMs = now;
        return true;
    }

    function hStepOk(rep, tapMs, holdMs) {
        var now = Date.now();
        if (now - lastHNavMs < (rep ? holdMs : tapMs)) return false;
        lastHNavMs = now;
        return true;
    }

    function tabLabel(t) {
        if (!t) return "";
        if (height >= 900) return t.label;
        var k = t.key;
        if (k === "gba") return "GBA";
        if (k === "gbc") return "GBC";
        if (k === "snes") return "SNES";
        if (k === "n64") return "N64";
        if (k === "genesis" || k === "megadrive") return "GENESIS";
        if (k === "mastersystem" || k === "sms") return "SMS";
        return t.label;
    }

    // ------------------------------------------------------------------
    // 8. Clean Zero-Collision Controller + TV Remote Key Mapper
    //    D-pad/Stick ALWAYS use Qt.Key_Left/Right/Up/Down (zero gamepad hex overlap).
    //    Gamepad A/B/X/Y/L1/R1/L2/R2 use Pegasus's native api.keys.* first,
    //    with TV remote & keyboard fallbacks and zero button collisions.
    // ------------------------------------------------------------------

    function isUnknownRawKey(ev) {
        var k = ev.key;
        return (k === 0 || k === Qt.Key_unknown || k === 33554431);
    }

    function rawCodeMatches(ev, androidCode, evdevCode) {
        if (!isUnknownRawKey(ev)) return false;
        var sc = ev.nativeScanCode || 0;
        return sc === androidCode || sc === evdevCode;
    }

    function isNavLeft(ev)  { return ev.key === Qt.Key_Left; }
    function isNavRight(ev) { return ev.key === Qt.Key_Right; }
    function isNavUp(ev)    { return ev.key === Qt.Key_Up; }
    function isNavDown(ev)  { return ev.key === Qt.Key_Down; }

    function isAcceptKey(ev) {
        var k = ev.key;
        if (api.keys.isAccept(ev)) return true;
        if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Select) return true;
        if (activeView !== "search" && k === Qt.Key_Space) return true;
        return rawCodeMatches(ev, 96, 304) || rawCodeMatches(ev, 23, 353);
    }

    function isCancelKey(ev) {
        var k = ev.key;
        if (api.keys.isCancel(ev)) return true;
        if (k === Qt.Key_Back || k === Qt.Key_Escape) return true;
        return rawCodeMatches(ev, 97, 305) || rawCodeMatches(ev, 4, 158);
    }

    function isHubKey(ev) {
        var k = ev.key;
        if (api.keys.isDetails(ev)) return true;
        if (k === Qt.Key_I || k === Qt.Key_H) return true;
        return rawCodeMatches(ev, 99, 307);
    }

    function isSearchKey(ev) {
        var k = ev.key;
        if (api.keys.isFilters(ev)) return true;
        if (k === Qt.Key_F || k === Qt.Key_Search) return true;
        return rawCodeMatches(ev, 100, 308);
    }

    function isPrevTabKey(ev) {
        var k = ev.key;
        if (api.keys.isPrevPage(ev)) return true;
        if (k === Qt.Key_Q || k === Qt.Key_BracketLeft) return true;
        return rawCodeMatches(ev, 102, 310);
    }

    function isNextTabKey(ev) {
        var k = ev.key;
        if (api.keys.isNextPage(ev)) return true;
        if (k === Qt.Key_E || k === Qt.Key_BracketRight) return true;
        return rawCodeMatches(ev, 103, 311);
    }

    function isJumpPrevKey(ev) {
        var k = ev.key;
        if (api.keys.isPageUp(ev)) return true;
        if (k === Qt.Key_PageUp) return true;
        return rawCodeMatches(ev, 104, 312);
    }

    function isJumpNextKey(ev) {
        var k = ev.key;
        if (api.keys.isPageDown(ev)) return true;
        if (k === Qt.Key_PageDown) return true;
        return rawCodeMatches(ev, 105, 313);
    }

    function isGamepadXOnly(ev) {
        return api.keys.isDetails(ev) || rawCodeMatches(ev, 99, 307);
    }

    function isGamepadYOnly(ev) {
        return api.keys.isFilters(ev) || rawCodeMatches(ev, 100, 308);
    }

    function isClaimedKey(ev) {
        return api.keys.isAccept(ev) || api.keys.isCancel(ev) || api.keys.isDetails(ev) || api.keys.isFilters(ev)
            || api.keys.isPrevPage(ev) || api.keys.isNextPage(ev) || api.keys.isPageUp(ev) || api.keys.isPageDown(ev);
    }

    // ------------------------------------------------------------------
    // 9. Timers, 15 SoundEffects, Animations & Lifecycle
    // ------------------------------------------------------------------

    Timer { id: toastTimer; interval: 1800; onTriggered: root.toastVisible = false }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.updateClock() }
    Timer { id: idleTimer; interval: 180000; running: true; repeat: false; onTriggered: if (!root.launching && !root.splashActive) root.screensaverActive = true }
    Timer { id: audioRestoreTimer; interval: 180; onTriggered: root.restoreAudioVolumes() }
    Timer { id: onlineFetchTimer; interval: 600; onTriggered: root.fetchOnlineMeta(root.pendingFetchGame) }
    Timer { id: rouletteTimer; interval: 42; onTriggered: root.stepRoulette() }
    Timer { id: kbFlashTimer; interval: 130; onTriggered: root.kbFlashIdx = -1 }
    Timer { id: warmTimer; interval: 120; repeat: true; onTriggered: root.warmTick() }
    Timer { id: gameRunningTimer; interval: 6000; onTriggered: root.gameRunning = false }
    Timer { id: indexTimer; interval: 80; onTriggered: root.ensureIndex() }

    // Fail-safes: input can never stay permanently blocked
    Timer { id: splashFailSafe; interval: 5000; onTriggered: root.forceFinishSplash() }
    Timer { id: launchFailSafe; interval: 1400; onTriggered: root.forceFinishLaunch() }
    Timer { id: rouletteFailSafe; interval: 3500; onTriggered: root.rouletteRunning = false }

    Timer {
        id: splashHoldTimer
        interval: 1650
        onTriggered: {
            root.splashDismissing = true;
            splashOutAnim.restart();
        }
    }

    // Boot Splash Reveal
    SequentialAnimation {
        id: splashInAnim
        ParallelAnimation {
            NumberAnimation { target: splashLogo; property: "opacity"; from: 0.0; to: 1.0; duration: 420; easing.type: Easing.OutCubic }
            NumberAnimation { target: splashLogo; property: "scale"; from: 0.86; to: 1.0; duration: 480; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "splashBarProgress"; from: 0.0; to: 1.0; duration: 560; easing.type: Easing.OutCubic }
        }
        ScriptAction { script: splashHoldTimer.restart() }
    }

    ParallelAnimation {
        id: splashOutAnim
        NumberAnimation { target: splashOverlay; property: "opacity"; to: 0.0; duration: 360; easing.type: Easing.InOutQuad }
        NumberAnimation { target: splashLogo; property: "scale"; to: 1.10; duration: 360; easing.type: Easing.InQuad }
        onStopped: {
            root.splashActive = false;
            root.splashDismissing = false;
        }
    }

    // Tab-Switch Row Cascade + Shoulder Pill Pulses
    ParallelAnimation {
        id: tabCascadeAnim
        NumberAnimation { target: mainShelfContainer; property: "opacity"; from: 0.0; to: 1.0; duration: 260; easing.type: Easing.OutCubic }
        NumberAnimation { target: shelfShift; property: "x"; from: root.sz(28); to: 0; duration: 260; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: l1PulseAnim
        NumberAnimation { target: root; property: "l1Pulse"; to: 1.0; duration: 85; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "l1Pulse"; to: 0.0; duration: 190; easing.type: Easing.OutCubic }
    }
    SequentialAnimation {
        id: r1PulseAnim
        NumberAnimation { target: root; property: "r1Pulse"; to: 1.0; duration: 85; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "r1Pulse"; to: 0.0; duration: 190; easing.type: Easing.OutCubic }
    }

    // Header Title + Badge + Staggered Description Slide-In
    ParallelAnimation {
        id: headerAnim
        NumberAnimation { target: headerCol; property: "opacity"; from: 0.12; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
        NumberAnimation { target: headerShift; property: "x"; from: root.sz(26); to: 0; duration: 280; easing.type: Easing.OutCubic }
    }

    // Favorite ★ & Wishlist ♡ Pop Bounce + Action Press Ripple
    SequentialAnimation {
        id: badgePopAnim
        NumberAnimation { target: root; property: "badgePopScale"; to: 1.48; duration: 120; easing.type: Easing.OutBack }
        NumberAnimation { target: root; property: "badgePopScale"; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: actionRippleAnim
        NumberAnimation { target: root; property: "actionRippleScale"; from: 0.88; to: 1.24; duration: 260; easing.type: Easing.OutCubic }
        SequentialAnimation {
            NumberAnimation { target: root; property: "actionRippleOpacity"; from: 0.0; to: 0.85; duration: 60 }
            NumberAnimation { target: root; property: "actionRippleOpacity"; from: 0.85; to: 0.0; duration: 200; easing.type: Easing.OutQuad }
        }
    }

    // Elastic Launch Warp (Anticipation Squash -> Pop + White Bloom -> Cinema Curtain)
    SequentialAnimation {
        id: launchSeqAnim
        NumberAnimation { target: root; property: "launchScale"; from: 1.0; to: 0.96; duration: 55; easing.type: Easing.InQuad }
        ParallelAnimation {
            NumberAnimation { target: root; property: "launchScale"; to: 1.13; duration: 175; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            NumberAnimation { target: root; property: "launchPhase"; from: 0.0; to: 1.0; duration: 175; easing.type: Easing.OutQuad }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "launchFade"; from: 0.0; to: 1.0; duration: 140; easing.type: Easing.InQuad }
            NumberAnimation { target: root; property: "launchPhase"; to: 0.0; duration: 140 }
        }
        ScriptAction { script: root.executePendingLaunch() }
    }

    onCurrentGamesChanged: headerAnim.restart()
    onActiveViewChanged: root.forceActiveFocus()
    onActionOpenChanged: root.forceActiveFocus()

    Connections {
        target: carousel
        onCurrentIndexChanged: headerAnim.restart()
    }
    Connections {
        target: gridView
        onCurrentIndexChanged: if (root.gridMode) headerAnim.restart()
    }

    // 14 Crisp Gamedeck Audio Cues + Keep-Alive Track (15 WAV files)
    SoundEffect { id: sndMove0;        source: "sounds/move.wav";         volume: 0.68 }
    SoundEffect { id: sndMove1;        source: "sounds/move.wav";         volume: 0.68 }
    SoundEffect { id: sndMove2;        source: "sounds/move.wav";         volume: 0.68 }
    SoundEffect { id: sndKey0;         source: "sounds/key_tap.wav";      volume: 0.58 }
    SoundEffect { id: sndKey1;         source: "sounds/key_tap.wav";      volume: 0.58 }
    SoundEffect { id: sndMoveVert;     source: "sounds/move_vert.wav";    volume: 0.64 }
    SoundEffect { id: sndTab;          source: "sounds/tab.wav";          volume: 0.74 }
    SoundEffect { id: sndSelect;       source: "sounds/select.wav";       volume: 0.80 }
    SoundEffect { id: sndBack;         source: "sounds/back.wav";         volume: 0.72 }
    SoundEffect { id: sndFav;          source: "sounds/fav.wav";          volume: 0.82 }
    SoundEffect { id: sndWishlist;     source: "sounds/wishlist.wav";     volume: 0.80 }
    SoundEffect { id: sndDrawerOpen;   source: "sounds/drawer_open.wav";  volume: 0.76 }
    SoundEffect { id: sndDrawerClose;  source: "sounds/drawer_close.wav"; volume: 0.72 }
    SoundEffect { id: sndLaunch;       source: "sounds/launch.wav";       volume: 0.88 }
    SoundEffect { id: sndBoot;         source: "sounds/boot.wav";         volume: 0.86 }
    SoundEffect { id: sndRouletteTick; source: "sounds/roulette_tick.wav";volume: 0.74 }
    SoundEffect { id: sndRouletteWin;  source: "sounds/roulette_win.wav"; volume: 0.86 }

    SoundEffect {
        id: sndKeep
        source: "sounds/keepalive.wav"
        loops: SoundEffect.Infinite
        volume: 0.12
        onStatusChanged: root.applyKeepAlive()
    }
    onKeepAliveWantedChanged: applyKeepAlive()

    Connections {
        target: Qt.application
        onStateChanged: {
            root.appActive = (Qt.application.state === Qt.ApplicationActive);
            if (root.appActive) {
                root.gameRunning = false;
                root.forceActiveFocus();
            }
        }
    }

    Component.onCompleted: {
        loadSettings();
        buildTabs();
        rebuildActionMenu();
        updateClock();
        indexTimer.start();

        var returning = Number(memGet("ra_returning", 0)) === 1;
        var savedTab = String(memGet("ra_last_tab", ""));
        var savedGame = String(memGet("ra_last_game", ""));
        var savedKey = String(memGet("ra_last_gkey", ""));

        if (returning) {
            memSet("ra_returning", 0);
            if (savedTab.length > 0) {
                for (var i = 0; i < tabList.length; i++) {
                    if (tabList[i].key === savedTab) { tabIndex = i; break; }
                }
            }
            refreshGames(false, savedGame, savedKey);
            splashActive = false;
        } else {
            refreshGames(false, "", "");
            bootChimePending = soundsOn;
            splashActive = true;
            splashOverlay.opacity = 1.0;
            splashInAnim.restart();
            splashFailSafe.restart();
        }
        warmAudio();
        root.forceActiveFocus();
    }

    function markFaceButtonOk() {
        if (!gamepadFaceSeen) {
            gamepadFaceSeen = true;
            memSet("ra_face_ok", 1);
        }
        navWithoutFaceCount = 0;
    }

    function trackNavForAccessibilityCheck() {
        if (gamepadFaceSeen || accessHintShown || actionOpen || controllerFixOpen) return;
        navWithoutFaceCount++;
        if (navWithoutFaceCount >= 14) {
            accessHintShown = true;
            showToast("A/B/X/Y NOT WORKING? DISABLE ANDROID ACCESSIBILITY (SEE ACTION DRAWER)");
        }
    }

    // ------------------------------------------------------------------
    // 10. Unified Input Router (Zero Focus Traps, Full A/B/X/Y/L1/R1/L2/R2)
    // ------------------------------------------------------------------

    Keys.onPressed: {
        var k = event.key;
        var rep = event.isAutoRepeat;

        // Leave Qt.Key_Menu untouched for Pegasus's native settings menu
        if (k === Qt.Key_Menu) {
            if (screensaverActive) resetIdle();
            return;
        }

        // Optional live controller keycode debugger (toggle inside Action Drawer)
        if (inputDebug && !rep) {
            showToast("KEY: 0x" + Number(k).toString(16) + "  SCAN: " + (event.nativeScanCode || 0) + "  TXT: " + (event.text || "-"));
        }

        if (screensaverActive) {
            resetIdle();
            event.accepted = true;
            return;
        }
        resetIdle();

        if (splashActive) {
            if (!splashDismissing) {
                splashHoldTimer.stop();
                splashInAnim.stop();
                splashDismissing = true;
                splashOutAnim.restart();
            }
            event.accepted = true;
            return;
        }

        if (launching || rouletteRunning) {
            event.accepted = true;
            return;
        }

        var isNav = isNavLeft(event) || isNavRight(event) || isNavUp(event) || isNavDown(event);
        if (rep && !isNav) {
            event.accepted = true;
            return;
        }

        // Track whether face buttons (A/B/X/Y/L1/R1) reach Pegasus vs. being blocked by Android Accessibility
        if (isAcceptKey(event) || isCancelKey(event) || isHubKey(event) || isSearchKey(event) || isPrevTabKey(event) || isNextTabKey(event)) {
            markFaceButtonOk();
        } else if (isNav && !rep) {
            trackNavForAccessibilityCheck();
        }

        // --- LAYER 0: Controller Accessibility Fix Modal ---
        if (controllerFixOpen) {
            if (isCancelKey(event) || isAcceptKey(event) || isHubKey(event)) {
                controllerFixOpen = false;
                playSound("drawer_close");
                event.accepted = true;
            }
            return;
        }

        // --- LAYER A: Game Action Drawer ---
        if (actionOpen) {
            if (isCancelKey(event) || isHubKey(event)) {
                closeActionPanel();
                event.accepted = true;
                return;
            }
            if (actionZone === 0) {
                if (isAcceptKey(event)) {
                    if (actionIconIdx === 0) startLaunch(actionGame);
                    else if (actionIconIdx === 1) toggleFavoriteFor(actionGame);
                    else if (actionIconIdx === 2) toggleWishlistFor(actionGame);
                    event.accepted = true;
                } else if (isNavLeft(event) || isNavRight(event)) {
                    if (navGate(rep)) {
                        actionIconIdx = (actionIconIdx + (isNavLeft(event) ? 2 : 1)) % 3;
                        if (!rep) playSound("move");
                    }
                    event.accepted = true;
                } else if (isNavDown(event)) {
                    if (navGate(rep)) {
                        actionZone = 1;
                        actionListIdx = 0;
                        if (!rep) playSound("move_vert");
                    }
                    event.accepted = true;
                }
            } else {
                if (isAcceptKey(event)) {
                    activateActionMenu();
                    event.accepted = true;
                } else if (isNavUp(event)) {
                    if (navGate(rep)) {
                        if (actionListIdx === 0) actionZone = 0;
                        else actionListIdx--;
                        if (!rep) playSound("move_vert");
                    }
                    event.accepted = true;
                } else if (isNavDown(event)) {
                    if (navGate(rep)) {
                        if (actionListIdx < actionMenuItems.length - 1) actionListIdx++;
                        if (!rep) playSound("move_vert");
                    }
                    event.accepted = true;
                }
            }
            return;
        }

        // --- LAYER B: Keyword Search Engine ---
        if (activeView === "search") {
            if (k === Qt.Key_Backspace) {
                if (searchQuery.length > 0) { searchQuery = searchQuery.slice(0, -1); runKeywordSearch(); playSound("key_tap"); }
                event.accepted = true;
                return;
            }
            if (isCancelKey(event)) {
                if (searchZone === 1) searchZone = 0;
                else activeView = searchFrom;
                playSound("back");
                event.accepted = true;
                return;
            }
            if (isGamepadXOnly(event)) {
                pressVirtualKey(kbKeys.indexOf("DEL"));
                event.accepted = true;
                return;
            }
            if (isGamepadYOnly(event)) {
                pressVirtualKey(kbKeys.indexOf("SPACE"));
                event.accepted = true;
                return;
            }

            if (searchZone === 0) {
                var cols = 6;
                var total = kbKeys.length;
                if (isAcceptKey(event)) {
                    pressVirtualKey(kbIndex);
                    event.accepted = true;
                } else if (isNav) {
                    if (navGate(rep)) {
                        if (isNavLeft(event)) {
                            kbIndex = (kbIndex % cols === 0) ? Math.min(total - 1, kbIndex + cols - 1) : kbIndex - 1;
                            if (!rep) playSound("move");
                        } else if (isNavRight(event)) {
                            if ((kbIndex % cols === cols - 1 || kbIndex === total - 1) && searchResults.length > 0) {
                                searchZone = 1;
                                playSound("tab");
                            } else {
                                kbIndex = Math.min(total - 1, kbIndex + 1);
                                if (!rep) playSound("move");
                            }
                        } else if (isNavUp(event)) {
                            if (kbIndex >= cols) kbIndex -= cols;
                            if (!rep) playSound("move_vert");
                        } else {
                            if (kbIndex + cols < total) kbIndex += cols;
                            else kbIndex = total - 1;
                            if (!rep) playSound("move_vert");
                        }
                    }
                    event.accepted = true;
                }
            } else {
                if (isNavLeft(event)) {
                    searchZone = 0;
                    playSound("back");
                    event.accepted = true;
                } else if (isNavUp(event) || isNavDown(event)) {
                    if (navGate(rep)) {
                        var ni = searchResultIdx + (isNavUp(event) ? -1 : 1);
                        if (ni >= 0 && ni < searchResults.length) {
                            searchResultIdx = ni;
                            searchResultsList.positionViewAtIndex(searchResultIdx, ListView.Contain);
                            if (!rep) playSound("move_vert");
                        }
                    }
                    event.accepted = true;
                } else if (isAcceptKey(event)) {
                    if (searchResults.length > 0 && searchResultIdx < searchResults.length) {
                        openActionPanel(searchResults[searchResultIdx]);
                    }
                    event.accepted = true;
                }
            }

            if (!event.accepted && event.text && event.text.length === 1 && /^[a-zA-Z0-9 ]$/.test(event.text) && !isClaimedKey(event)) {
                if (searchQuery.length < 28) { searchQuery += event.text.toUpperCase(); runKeywordSearch(); playSound("key_tap"); }
                event.accepted = true;
            }
            return;
        }

        // --- LAYER C: Discovery Hub ---
        if (activeView === "hub") {
            if (hubSubOpen) {
                if (isCancelKey(event) || isHubKey(event)) {
                    hubSubOpen = false;
                    playSound("back");
                    event.accepted = true;
                } else if (isNavLeft(event) || isNavRight(event)) {
                    if (hStepOk(rep, 95, 165)) moveHubSub(isNavLeft(event) ? -1 : 1);
                    event.accepted = true;
                } else if (isJumpPrevKey(event) || isJumpNextKey(event)) {
                    moveHubSub(isJumpPrevKey(event) ? -10 : 10);
                    event.accepted = true;
                } else if (isAcceptKey(event)) {
                    if (hubSubGames.length > 0 && hubSubIdx < hubSubGames.length) {
                        openActionPanel(hubSubGames[hubSubIdx]);
                    }
                    event.accepted = true;
                }
                return;
            }

            if (isCancelKey(event) || isHubKey(event)) {
                activeView = "main";
                playSound("drawer_close");
                event.accepted = true;
                return;
            }
            if (isSearchKey(event)) {
                openSearch();
                event.accepted = true;
                return;
            }

            var secs = hubSectionList();
            var pos = secs.indexOf(hubSection);
            if (pos < 0) { hubSection = secs[0]; pos = 0; }

            if (isAcceptKey(event)) {
                activateHubSection();
                event.accepted = true;
            } else if (isNavUp(event) || isNavDown(event)) {
                if (navGate(rep)) {
                    var np = pos + (isNavUp(event) ? -1 : 1);
                    if (np >= 0 && np < secs.length) {
                        hubSection = secs[np];
                        if (!rep) playSound("move_vert");
                    }
                }
                event.accepted = true;
            } else if (isNavLeft(event) || isNavRight(event)) {
                if (hStepOk(rep, 90, 160)) moveHubRow(isNavLeft(event) ? -1 : 1);
                event.accepted = true;
            }
            return;
        }

        // --- LAYER D: Main Console Carousel / Poster Grid ---
        if (isPrevTabKey(event)) {
            switchTab(-1, rep);
            event.accepted = true;
        } else if (isNextTabKey(event)) {
            switchTab(1, rep);
            event.accepted = true;
        } else if (isJumpPrevKey(event)) {
            jumpLetter(-1);
            event.accepted = true;
        } else if (isJumpNextKey(event)) {
            jumpLetter(1);
            event.accepted = true;
        } else if (isHubKey(event)) {
            openHub();
            event.accepted = true;
        } else if (isSearchKey(event)) {
            openSearch();
            event.accepted = true;
        } else if (isAcceptKey(event)) {
            openActionPanel(activeMainGame());
            event.accepted = true;
        } else if (gridMode) {
            if (isNavLeft(event))       { moveGrid(-1, 0, rep); event.accepted = true; }
            else if (isNavRight(event)) { moveGrid(1, 0, rep);  event.accepted = true; }
            else if (isNavUp(event))    { moveGrid(0, -1, rep); event.accepted = true; }
            else if (isNavDown(event))  { moveGrid(0, 1, rep);  event.accepted = true; }
        } else {
            if (isNavLeft(event)) {
                moveMainCarousel(-1, rep);
                event.accepted = true;
            } else if (isNavRight(event)) {
                moveMainCarousel(1, rep);
                event.accepted = true;
            } else if (isNavUp(event)) {
                openHub();
                event.accepted = true;
            } else if (isNavDown(event)) {
                switchTab(1, rep);
                event.accepted = true;
            }
        }
    }

    // ------------------------------------------------------------------
    // 11. Razor-Sharp Gamedeck Diagonal Backdrop + Ambient Drift
    // ------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        clip: true

        Rectangle {
            width: parent.width * 2.1
            height: parent.height * 2.1
            anchors.centerIn: parent
            rotation: -33

            // Gentle living ambient diagonal drift
            SequentialAnimation on rotation {
                running: root.activeView === "main" && !root.screensaverActive
                loops: Animation.Infinite
                NumberAnimation { from: -33.6; to: -32.2; duration: 4200; easing.type: Easing.InOutSine }
                NumberAnimation { from: -32.2; to: -33.6; duration: 4200; easing.type: Easing.InOutSine }
            }

            gradient: Gradient {
                GradientStop { position: 0.00; color: "#000000" }
                GradientStop { position: 0.455; color: "#000000" }
                GradientStop {
                    position: 0.49
                    color: root.activeTheme().c1
                    Behavior on color { ColorAnimation { duration: 320 } }
                }
                GradientStop {
                    position: 0.75
                    color: root.activeTheme().c2
                    Behavior on color { ColorAnimation { duration: 320 } }
                }
                GradientStop {
                    position: 1.00
                    color: root.activeTheme().accent
                    Behavior on color { ColorAnimation { duration: 320 } }
                }
            }
        }

        // Slick High-Visibility Cinema Game Backdrop (right/full stage with seamless edge fade)
        Item {
            id: heroBackdropWrap
            anchors.right: parent.right
            anchors.top: parent.top
            width: parent.width * 0.76
            height: parent.height * 0.88
            clip: true

            property var bgGame: root.activeView === "main" ? root.activeMainGame() : null
            property int bgStage: root.bgStageOf(bgGame)
            property string bgUrl: root.activeView === "main" ? root.gameBackdrop(bgGame, root.cacheRev, bgStage) : ""

            onBgGameChanged: {
                bgStage = root.bgStageOf(bgGame);
                bgZoomAnim.restart();
            }

            Image {
                id: heroBackdropImg
                anchors.fill: parent
                source: heroBackdropWrap.bgUrl
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 960
                sourceSize.height: 540
                asynchronous: true
                smooth: true
                scale: 1.0
                opacity: (status === Image.Ready && root.activeView === "main") ? 0.62 : 0.0
                Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                onStatusChanged: {
                    if (status === Image.Error && heroBackdropWrap.bgGame && heroBackdropWrap.bgStage < 6) {
                        heroBackdropWrap.bgStage = root.advanceBgStage(heroBackdropWrap.bgGame);
                    }
                }
            }

            NumberAnimation {
                id: bgZoomAnim
                target: heroBackdropImg
                property: "scale"
                from: 1.05
                to: 1.0
                duration: 650
                easing.type: Easing.OutCubic
            }

            // Seamless horizontal fade on the left edge (melts cleanly into pitch-black left side, zero hard border)
            Item {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * 0.56
                clip: true

                Rectangle {
                    width: parent.height
                    height: parent.width
                    anchors.centerIn: parent
                    rotation: -90
                    gradient: Gradient {
                        GradientStop { position: 0.00; color: "#ff000000" }
                        GradientStop { position: 0.34; color: "#c8000000" }
                        GradientStop { position: 0.70; color: "#44000000" }
                        GradientStop { position: 1.00; color: "#00000000" }
                    }
                }
            }

            // Subtle console-color cinematic tint across right edge (blends art with Gamedeck neon vibe)
            Rectangle {
                anchors.fill: parent
                opacity: heroBackdropImg.status === Image.Ready ? 0.22 : 0.0
                Behavior on opacity { NumberAnimation { duration: 320 } }
                gradient: Gradient {
                    GradientStop { position: 0.00; color: "#00000000" }
                    GradientStop { position: 0.65; color: root.activeTheme().c1 }
                    GradientStop { position: 1.00; color: root.activeTheme().c2 }
                }
            }

            // Seamless bottom fade so the shelf & floor reflections stay crisp
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * 0.42
                gradient: Gradient {
                    GradientStop { position: 0.00; color: "#00000000" }
                    GradientStop { position: 0.58; color: "#88020614" }
                    GradientStop { position: 1.00; color: "#ee020614" }
                }
            }

            // Light top-bar readability gradient so floating L1/R1 tabs stay crisp over bright screenshots
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height * 0.22
                gradient: Gradient {
                    GradientStop { position: 0.00; color: "#aa000000" }
                    GradientStop { position: 1.00; color: "#00000000" }
                }
            }
        }

        // Bottom floor fade for footer legibility
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * 0.22
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 1.0; color: "#b8020614" }
            }
        }

        // Giant ultra-subtle console watermark
        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.13
            anchors.rightMargin: parent.width * 0.04
            text: root.activeTheme().badge
            color: "#12ffffff"
            font.pixelSize: root.px(88)
            font.bold: true
            font.letterSpacing: 4
            visible: root.activeView === "main"
        }
    }

    // ------------------------------------------------------------------
    // 12. Floating Gamedeck Top Bar (No Heavy Box) + Subtle Clock Pill
    // ------------------------------------------------------------------

    Row {
        id: topBar
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.045
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.sz(24)
        visible: root.activeView === "main"

        // L1 Outlined Pill (with press flash pulse)
        Rectangle {
            width: root.sz(48); height: root.sz(30); radius: root.sz(10)
            color: root.l1Pulse > 0.05 ? "#66ffffff" : "#18ffffff"
            border.color: root.l1Pulse > 0.05 ? "#ffffff" : "#b8ffffff"
            border.width: 1.5
            scale: 1.0 + 0.08 * root.l1Pulse
            anchors.verticalCenter: parent.verticalCenter
            Text { anchors.centerIn: parent; text: "L1"; color: "#ffffff"; font.pixelSize: root.sz(13); font.bold: true }
        }

        Row {
            spacing: root.sz(30)
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: {
                    var out = [];
                    var total = root.tabList.length;
                    if (total === 0) return out;
                    var start = Math.max(0, root.tabIndex - 1);
                    var end = Math.min(total - 1, start + 2);
                    if (end - start < 2) start = Math.max(0, end - 2);
                    for (var i = start; i <= end; i++) out.push(i);
                    return out;
                }
                delegate: Column {
                    spacing: root.sz(6)
                    property bool isActive: modelData === root.tabIndex

                    Rectangle {
                        width: parent.isActive ? root.sz(38) : 0
                        height: root.sz(4)
                        radius: root.sz(2)
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#ffffff"
                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }
                    Text {
                        text: root.tabLabel(root.tabList[modelData])
                        color: parent.isActive ? "#ffffff" : "#80ffffff"
                        font.pixelSize: root.sz(18)
                        font.bold: parent.isActive
                        font.letterSpacing: 1.5
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                }
            }
        }

        // R1 Outlined Pill (with press flash pulse)
        Rectangle {
            width: root.sz(48); height: root.sz(30); radius: root.sz(10)
            color: root.r1Pulse > 0.05 ? "#66ffffff" : "#18ffffff"
            border.color: root.r1Pulse > 0.05 ? "#ffffff" : "#b8ffffff"
            border.width: 1.5
            scale: 1.0 + 0.08 * root.r1Pulse
            anchors.verticalCenter: parent.verticalCenter
            Text { anchors.centerIn: parent; text: "R1"; color: "#ffffff"; font.pixelSize: root.sz(13); font.bold: true }
        }
    }

    // Subtle Glass Clock Pill (top-right)
    Rectangle {
        id: clockPill
        z: 31
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.045
        anchors.verticalCenter: topBar.verticalCenter
        width: clockLabel.implicitWidth + root.sz(30)
        height: root.sz(36)
        radius: height / 2
        color: "#44050b18"
        border.color: "#38ffffff"
        border.width: 1
        visible: root.activeView !== "search"

        Text {
            id: clockLabel
            anchors.centerIn: parent
            text: root.clockText
            color: "#f2ffffff"
            font.pixelSize: root.sz(18)
            font.bold: true
            font.letterSpacing: 1
        }
    }

    // ------------------------------------------------------------------
    // 13. Main View: Bold TV-Sized Gamedeck Shelf & 5-Column Poster Grid
    // ------------------------------------------------------------------

    Item {
        id: mainViewLayer
        anchors.fill: parent
        visible: root.activeView === "main"

        // Active Game Header (sits cleanly above lifted hero card + glow)
        Column {
            id: headerCol
            anchors.left: parent.left
            anchors.leftMargin: parent.width * 0.055
            y: Math.max(root.height * 0.105, mainShelfContainer.y + (mainShelfContainer.height - carousel.height) / 2 - carousel.height * 0.095 - root.px(26) - height)
            width: parent.width * 0.78
            spacing: root.sz(6)
            visible: root.currentGames.length > 0
            transform: Translate { id: headerShift; x: 0 }

            property var curGame: root.activeMainGame()
            property var gTheme: root.themeFor(root.gameShortName(curGame))

            Row {
                spacing: root.sz(12)

                Rectangle {
                    height: root.sz(24)
                    width: badgeTxt.implicitWidth + root.sz(18)
                    radius: root.sz(6)
                    color: headerCol.gTheme.c2
                    border.color: "#88ffffff"
                    border.width: 1
                    Text {
                        id: badgeTxt
                        anchors.centerIn: parent
                        text: headerCol.gTheme.badge
                        color: "#ffffff"
                        font.pixelSize: root.sz(11)
                        font.bold: true
                        font.letterSpacing: 1.2
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: headerCol.gTheme.tag
                    color: "#ccffffff"
                    font.pixelSize: root.sz(12)
                    font.bold: true
                    font.letterSpacing: 1.5
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "★ FAVORITE"
                    color: "#ffd644"
                    font.pixelSize: root.sz(12)
                    font.bold: true
                    visible: !!(headerCol.curGame && headerCol.curGame.favorite)
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "♡ WISHLIST"
                    color: "#ff7ac3"
                    font.pixelSize: root.sz(12)
                    font.bold: true
                    visible: root.isWishlisted(headerCol.curGame, root.cacheRev)
                }
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: headerCol.curGame ? root.cleanTitle(headerCol.curGame.title) : ""
                color: "#ffffff"
                font.pixelSize: root.sz(35)
                font.bold: true
            }

            Item {
                width: parent.width * 0.96
                height: mainDescFg.implicitHeight
                visible: mainDescFg.text.length > 0

                // Crisp subtle shadow for couch-distance TV readability
                Text {
                    x: 2; y: 2
                    width: parent.width
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    lineHeight: 1.18
                    text: mainDescFg.text
                    color: "#cc000000"
                    font.pixelSize: root.sz(19)
                    font.weight: Font.Medium
                }
                Text {
                    id: mainDescFg
                    width: parent.width
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    lineHeight: 1.18
                    text: root.gameDescription(headerCol.curGame, root.cacheRev)
                    color: "#f5ffffff"
                    font.pixelSize: root.sz(19)
                    font.weight: Font.Medium
                }
            }
        }

        // Game Counter (Right Side)
        Text {
            anchors.right: parent.right
            anchors.rightMargin: parent.width * 0.055
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.19
            text: ((root.gridMode ? gridView.currentIndex : carousel.currentIndex) + 1) + " / " + root.currentGames.length
            color: "#d8ffffff"
            font.pixelSize: root.sz(18)
            font.bold: true
            visible: root.currentGames.length > 0
        }

        // Empty State
        Column {
            anchors.centerIn: parent
            spacing: root.sz(10)
            visible: root.currentGames.length === 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    var ci = root.currentTabObj().colIndex;
                    if (ci === -2) return "★ NO FAVORITES YET";
                    if (ci === -3) return "NOTHING PLAYED YET";
                    return "NO GAMES FOUND";
                }
                color: "#eeffffff"
                font.pixelSize: root.sz(26)
                font.bold: true
                font.letterSpacing: 2
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Press [A] on any game to Favorite, Wishlist, or Play"
                color: "#aaffffff"
                font.pixelSize: root.sz(15)
            }
        }

        // Shelf / Grid Container
        Item {
            id: mainShelfContainer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.31
            anchors.bottom: parent.bottom
            anchors.bottomMargin: parent.height * 0.115
            transform: Translate { id: shelfShift; x: 0 }
            visible: root.currentGames.length > 0

            // --- BOLD TV-SIZED GAMEDECK CAROUSEL (Never shrunk to tiny phone cards!) ---
            ListView {
                id: carousel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height * 0.80
                orientation: ListView.Horizontal
                spacing: root.px(32)
                leftMargin: parent.width * 0.055
                rightMargin: parent.width * 0.45
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: parent.width * 0.055
                preferredHighlightEnd: parent.width * 0.055 + height * root.cardRatio
                highlightMoveDuration: 360
                model: root.gridMode ? [] : root.currentGames
                visible: !root.gridMode

                delegate: Item {
                    id: cardWrap
                    property bool isFocused: ListView.isCurrentItem && root.activeView === "main" && !root.actionOpen && !root.gridMode
                    property int artStage: root.artStageOf(modelData)
                    property string artUrl: root.gameBoxArt(modelData, root.cacheRev, artStage)
                    property var cardTheme: root.themeFor(root.gameShortName(modelData))
                    property bool hasArt: artUrl !== "" && art.status !== Image.Error
                    property real lift: height * 0.048

                    z: isFocused ? 5 : 1
                    width: carousel.height * root.cardRatio
                    height: carousel.height

                    onIsFocusedChanged: {
                        if (isFocused) cardSheenAnim.restart();
                    }

                    // Zero-RAM Per-Card Glossy Floor Reflection Pool (brightens on active hero)
                    Rectangle {
                        anchors.top: launchScaler.bottom
                        anchors.topMargin: root.px(8)
                        anchors.horizontalCenter: launchScaler.horizontalCenter
                        width: parent.width * (cardWrap.isFocused ? 0.98 : 0.84)
                        height: root.px(44)
                        radius: root.px(12)
                        opacity: cardWrap.isFocused ? 0.34 : 0.14
                        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                        Behavior on width   { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                        gradient: Gradient {
                            GradientStop { position: 0.00; color: cardWrap.isFocused ? "#99ffffff" : "#55ffffff" }
                            GradientStop { position: 0.40; color: cardWrap.isFocused ? "#30ffffff" : "#18ffffff" }
                            GradientStop { position: 1.00; color: "#00000000" }
                        }
                    }

                    // Elastic Launch Warp Scaler
                    Item {
                        id: launchScaler
                        anchors.fill: parent
                        scale: cardWrap.isFocused ? root.launchScale : 1.0

                        // 5-Layer Truly Concentric Gamedeck Pure-White Breathing Bloom
                        Item {
                            id: glowContainer
                            anchors.fill: card
                            scale: card.scale
                            opacity: cardWrap.isFocused ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                            Item {
                                anchors.fill: parent
                                opacity: 0.90
                                SequentialAnimation on opacity {
                                    running: cardWrap.isFocused
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0.66; to: 1.00; duration: 1150; easing.type: Easing.InOutSine }
                                    NumberAnimation { from: 1.00; to: 0.66; duration: 1150; easing.type: Easing.InOutSine }
                                }

                                Rectangle { anchors.fill: parent; anchors.margins: -3;  radius: 17; color: "transparent"; border.color: "#72ffffff"; border.width: 3 }
                                Rectangle { anchors.fill: parent; anchors.margins: -7;  radius: 21; color: "transparent"; border.color: "#44ffffff"; border.width: 4 }
                                Rectangle { anchors.fill: parent; anchors.margins: -12; radius: 26; color: "transparent"; border.color: "#24ffffff"; border.width: 5 }
                                Rectangle { anchors.fill: parent; anchors.margins: -18; radius: 32; color: "transparent"; border.color: "#12ffffff"; border.width: 6 }
                                Rectangle { anchors.fill: parent; anchors.margins: -25; radius: 39; color: "transparent"; border.color: "#07ffffff"; border.width: 7 }
                            }
                        }

                        // Hero Card Body (TV-sized, bold lift & scale contrast)
                        Rectangle {
                            id: card
                            width: parent.width
                            height: parent.height
                            y: cardWrap.isFocused ? -cardWrap.lift : 0
                            radius: 14
                            color: "#090f1e"
                            scale: cardWrap.isFocused ? 1.10 : 0.86
                            opacity: cardWrap.isFocused ? 1.0 : 0.82

                            Behavior on scale   { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            Behavior on y       { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                            // Subtle interior backdrop gradient
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: 10
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: cardWrap.cardTheme.c1 }
                                    GradientStop { position: 1.0; color: "#090f1e" }
                                }
                            }

                            Image {
                                id: art
                                anchors.fill: parent
                                anchors.margins: 4
                                source: cardWrap.artUrl
                                sourceSize.width: 512
                                sourceSize.height: 512
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                visible: status === Image.Ready
                                onStatusChanged: {
                                    if (status === Image.Error && cardWrap.artStage < 6 && root.gameLocalArt(modelData) === "") {
                                        cardWrap.artStage = root.advanceArtStage(modelData);
                                    }
                                }
                            }

                            // Slick Minimal Fallback Tile (replaces blank flat blue boxes)
                            Item {
                                anchors.fill: parent
                                anchors.margins: 4
                                clip: true
                                visible: !cardWrap.hasArt || art.status !== Image.Ready

                                Rectangle {
                                    width: parent.width * 1.45
                                    height: parent.height * 0.24
                                    anchors.centerIn: parent
                                    rotation: -28
                                    color: "#14ffffff"
                                }
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.margins: 12
                                    height: root.px(24)
                                    width: fbTagTxt.implicitWidth + 16
                                    radius: 6
                                    color: "#55000000"
                                    border.color: "#44ffffff"
                                    border.width: 1
                                    Text {
                                        id: fbTagTxt
                                        anchors.centerIn: parent
                                        text: cardWrap.cardTheme.badge
                                        color: "#f2ffffff"
                                        font.pixelSize: root.px(10)
                                        font.bold: true
                                        font.letterSpacing: 1.1
                                    }
                                }
                                Column {
                                    anchors.centerIn: parent
                                    width: parent.width - 28
                                    spacing: 6
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData ? root.cleanTitle(modelData.title).charAt(0).toUpperCase() : "N"
                                        color: "#2cffffff"
                                        font.pixelSize: root.px(56)
                                        font.bold: true
                                    }
                                    Text {
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                        text: modelData ? root.cleanTitle(modelData.title) : ""
                                        color: "#ffffff"
                                        font.pixelSize: root.px(17)
                                        font.bold: true
                                    }
                                }
                            }

                            // Diagonal Specular Glass Sheen Sweep on Hero Focus Enter
                            Item {
                                anchors.fill: parent
                                anchors.margins: 4
                                clip: true
                                z: 1

                                Rectangle {
                                    id: cardSheen
                                    width: parent.width * 0.42
                                    height: parent.height * 1.9
                                    y: -parent.height * 0.45
                                    x: -parent.width * 0.8
                                    rotation: 24
                                    opacity: 0.0
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#00ffffff" }
                                        GradientStop { position: 0.5; color: "#36ffffff" }
                                        GradientStop { position: 1.0; color: "#00ffffff" }
                                    }
                                }

                                ParallelAnimation {
                                    id: cardSheenAnim
                                    NumberAnimation { target: cardSheen; property: "x"; from: -card.width * 0.7; to: card.width * 1.35; duration: 500; easing.type: Easing.OutCubic }
                                    SequentialAnimation {
                                        NumberAnimation { target: cardSheen; property: "opacity"; from: 0.0; to: 1.0; duration: 150 }
                                        NumberAnimation { target: cardSheen; property: "opacity"; from: 1.0; to: 0.0; duration: 350 }
                                    }
                                }
                            }

                            // Favorite ★ & Wishlist ♡ Corner Badges
                            Row {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 10
                                spacing: 6
                                z: 3
                                scale: cardWrap.isFocused ? root.badgePopScale : 1.0

                                Rectangle {
                                    width: root.px(30); height: root.px(30); radius: root.px(15)
                                    color: "#cc000000"
                                    border.color: "#ff7ac3"; border.width: 1.5
                                    visible: root.isWishlisted(modelData, root.cacheRev)
                                    Text { anchors.centerIn: parent; text: "♡"; color: "#ff7ac3"; font.pixelSize: root.px(17); font.bold: true }
                                }
                                Rectangle {
                                    width: root.px(30); height: root.px(30); radius: root.px(15)
                                    color: "#cc000000"
                                    border.color: "#ffd644"; border.width: 1.5
                                    visible: !!(modelData && modelData.favorite)
                                    Text { anchors.centerIn: parent; text: "★"; color: "#ffd644"; font.pixelSize: root.px(18) }
                                }
                            }

                            // Launch White Bloom Flash
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: 10
                                z: 1
                                color: "#ffffff"
                                opacity: cardWrap.isFocused ? 0.62 * root.launchPhase : 0.0
                                visible: opacity > 0.01
                            }

                            // Crisp Pure-White Top Frame
                            Rectangle {
                                anchors.fill: parent
                                z: 2
                                radius: 14
                                color: "transparent"
                                border.width: cardWrap.isFocused ? 4 : 2
                                border.color: cardWrap.isFocused ? "#ffffff" : "#26ffffff"
                            }
                        }
                    }
                }
            }

            // --- 5-COLUMN POSTER GRID VIEW ---
            GridView {
                id: gridView
                anchors.fill: parent
                anchors.leftMargin: parent.width * 0.055
                anchors.rightMargin: parent.width * 0.055
                cellWidth: width / 5
                cellHeight: cellWidth * 1.15
                clip: true
                highlightMoveDuration: 220
                model: root.gridMode ? root.currentGames : []
                visible: root.gridMode

                delegate: Item {
                    id: gridCell
                    width: gridView.cellWidth
                    height: gridView.cellHeight
                    property bool isFocused: GridView.isCurrentItem && root.activeView === "main" && !root.actionOpen && root.gridMode
                    property int artStage: root.artStageOf(modelData)
                    property string artUrl: root.gameBoxArt(modelData, root.cacheRev, artStage)
                    property var cardTheme: root.themeFor(root.gameShortName(modelData))
                    z: isFocused ? 5 : 1

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: root.px(10)
                        radius: 12
                        color: "#090f1e"
                        scale: gridCell.isFocused ? 1.06 : 0.94
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        Rectangle { anchors.fill: parent; anchors.margins: -4;  radius: 16; color: "transparent"; border.color: "#60ffffff"; border.width: 4; visible: gridCell.isFocused }
                        Rectangle { anchors.fill: parent; anchors.margins: -9;  radius: 21; color: "transparent"; border.color: "#28ffffff"; border.width: 5; visible: gridCell.isFocused }
                        Rectangle { anchors.fill: parent; anchors.margins: -14; radius: 26; color: "transparent"; border.color: "#12ffffff"; border.width: 5; visible: gridCell.isFocused }

                        Rectangle {
                            anchors.fill: parent; anchors.margins: 4; radius: 8
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: gridCell.cardTheme.c1 }
                                GradientStop { position: 1.0; color: "#090f1e" }
                            }
                        }

                        Image {
                            id: gArt
                            anchors.fill: parent
                            anchors.margins: 4
                            source: gridCell.artUrl
                            sourceSize.width: 512
                            sourceSize.height: 512
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            visible: status === Image.Ready
                            onStatusChanged: {
                                if (status === Image.Error && gridCell.artStage < 6 && root.gameLocalArt(modelData) === "") {
                                    gridCell.artStage = root.advanceArtStage(modelData);
                                }
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 20
                            spacing: 4
                            visible: gArt.status !== Image.Ready
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData ? root.cleanTitle(modelData.title).charAt(0).toUpperCase() : "N"
                                color: "#2cffffff"; font.pixelSize: root.px(36); font.bold: true
                            }
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                text: modelData ? root.cleanTitle(modelData.title) : ""
                                color: "#ffffff"
                                font.pixelSize: root.px(14)
                                font.bold: true
                            }
                        }

                        Row {
                            anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 8; spacing: 4; z: 3
                            Text { text: "♡"; color: "#ff7ac3"; font.pixelSize: root.px(15); visible: root.isWishlisted(modelData, root.cacheRev) }
                            Text { text: "★"; color: "#ffd644"; font.pixelSize: root.px(16); visible: !!(modelData && modelData.favorite) }
                        }

                        Rectangle {
                            anchors.fill: parent
                            z: 2
                            radius: 12
                            color: "transparent"
                            border.width: gridCell.isFocused ? 4 : 2
                            border.color: gridCell.isFocused ? "#ffffff" : "#22ffffff"
                        }
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // 14. DISCOVERY HUB OVERLAY (Separate from L1/R1 Console Tabs)
    // ------------------------------------------------------------------

    Rectangle {
        id: hubOverlay
        anchors.fill: parent
        color: "#ed050a18"
        z: 30
        opacity: root.activeView === "hub" ? 1.0 : 0.0
        scale: root.activeView === "hub" ? 1.0 : 0.96
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Column {
            anchors.fill: parent
            anchors.leftMargin: parent.width * 0.05
            anchors.rightMargin: parent.width * 0.05
            anchors.topMargin: parent.height * 0.05
            anchors.bottomMargin: parent.height * 0.10
            spacing: root.px(16)
            visible: !root.hubSubOpen

            Row {
                spacing: root.sz(16)
                Text { text: "DISCOVERY HUB"; color: "#ffffff"; font.pixelSize: root.sz(26); font.bold: true; font.letterSpacing: 2 }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "POPULAR • FRANCHISES • MULTIPLAYER • WISHLIST • CONSOLES"; color: "#88ffffff"; font.pixelSize: root.sz(12); font.bold: true; font.letterSpacing: 1.4 }
            }

            // Section 0: Continue + Search + Multiplayer + Wishlist + Unplayed
            ListView {
                id: hubQuickList
                width: parent.width
                height: root.sz(72)
                orientation: ListView.Horizontal
                spacing: root.px(16)
                clip: true
                model: root.hubQuickItems
                delegate: Rectangle {
                    property bool sel: root.hubSection === 0 && index === root.hubQuickIdx
                    width: Math.max(root.sz(215), qCol.implicitWidth + root.sz(42))
                    height: hubQuickList.height - 6
                    anchors.verticalCenter: parent.verticalCenter
                    radius: root.sz(12)
                    color: sel ? "#38ffffff" : "#18ffffff"
                    border.color: sel ? "#ffffff" : "#28ffffff"
                    border.width: sel ? 3 : 1
                    scale: sel ? 1.04 : 0.98
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Row {
                        id: qCol
                        anchors.centerIn: parent
                        spacing: root.sz(12)
                        Text { text: modelData.icon; color: modelData.accent; font.pixelSize: root.sz(modelData.icon.length > 1 ? 15 : 22); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            Text { text: modelData.title; color: "#ffffff"; font.pixelSize: root.sz(14); font.bold: true; font.letterSpacing: 1 }
                            Text { text: modelData.subtitle; color: "#bbffffff"; font.pixelSize: root.sz(12); elide: Text.ElideRight; width: root.sz(175) }
                        }
                    }
                }
            }

            // Section 1: POPULAR CLASSICS (Curated Order)
            Column {
                width: parent.width
                spacing: root.px(8)
                visible: root.popularGames.length > 0

                Text {
                    text: "★ POPULAR CLASSICS (" + root.popularGames.length + ")"
                    color: root.hubSection === 1 ? "#ffd644" : "#ccffffff"
                    font.pixelSize: root.sz(15)
                    font.bold: true
                    font.letterSpacing: 1.6
                }

                ListView {
                    id: hubPopularList
                    width: parent.width
                    height: root.height * 0.22
                    orientation: ListView.Horizontal
                    spacing: root.px(18)
                    clip: true
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: width * 0.7
                    highlightMoveDuration: 260
                    model: root.hubReady ? root.popularGames : []

                    delegate: Rectangle {
                        property bool sel: root.hubSection === 1 && index === root.hubPopularIdx
                        width: hubPopularList.height * 0.78
                        height: hubPopularList.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 12
                        color: "#0e1526"
                        scale: sel ? 1.06 : 0.94
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        Image {
                            id: popImg
                            property int st: root.artStageOf(modelData)
                            anchors.fill: parent; anchors.margins: 4
                            source: root.gameBoxArt(modelData, root.cacheRev, st)
                            sourceSize.width: 512; sourceSize.height: 512
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            visible: status === Image.Ready
                            onStatusChanged: if (status === Image.Error && st < 6 && root.gameLocalArt(modelData) === "") st = root.advanceArtStage(modelData)
                        }
                        Text {
                            anchors.centerIn: parent; width: parent.width - 16
                            horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; maximumLineCount: 3
                            text: root.cleanTitle(modelData.title); color: "#ffffff"; font.pixelSize: root.px(14); font.bold: true
                            visible: popImg.status !== Image.Ready
                        }
                        Rectangle {
                            anchors.fill: parent; z: 2; radius: 12; color: "transparent"
                            border.width: sel ? 4 : 1.5; border.color: sel ? "#ffffff" : "#28ffffff"
                        }
                    }
                }
            }

            // Section 2: FRANCHISE COLLECTIONS
            Column {
                width: parent.width
                spacing: root.px(8)
                visible: root.franchiseList.length > 0

                Text {
                    text: "FRANCHISE COLLECTIONS (" + root.franchiseList.length + " SERIES)"
                    color: root.hubSection === 2 ? "#66aaff" : "#ccffffff"
                    font.pixelSize: root.sz(15)
                    font.bold: true
                    font.letterSpacing: 1.6
                }

                ListView {
                    id: hubFranchiseList
                    width: parent.width
                    height: root.height * 0.18
                    orientation: ListView.Horizontal
                    spacing: root.px(18)
                    clip: true
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: width * 0.7
                    highlightMoveDuration: 260
                    model: root.hubReady ? root.franchiseList : []

                    delegate: Rectangle {
                        property bool sel: root.hubSection === 2 && index === root.hubFranchiseIdx
                        width: root.sz(245)
                        height: hubFranchiseList.height - 10
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 12
                        color: sel ? "#254080" : "#121d38"
                        scale: sel ? 1.05 : 0.96
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        Image {
                            property int st: root.artStageOf(modelData.coverGame)
                            anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                            anchors.margins: 6
                            width: parent.width * 0.45
                            source: root.gameBoxArt(modelData.coverGame, root.cacheRev, st)
                            sourceSize.width: 512; sourceSize.height: 512
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            opacity: 0.92
                            onStatusChanged: if (status === Image.Error && st < 6 && root.gameLocalArt(modelData.coverGame) === "") st = root.advanceArtStage(modelData.coverGame)
                        }

                        Column {
                            anchors.left: parent.left; anchors.leftMargin: root.px(16)
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * 0.50
                            spacing: 6
                            Text {
                                width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
                                text: modelData.name
                                color: "#ffffff"; font.pixelSize: root.sz(16); font.bold: true
                            }
                            Text {
                                text: modelData.count + " GAMES"
                                color: "#ffd644"; font.pixelSize: root.sz(13); font.bold: true
                            }
                        }

                        Rectangle {
                            anchors.fill: parent; z: 2; radius: 12; color: "transparent"
                            border.width: sel ? 4 : 1.5; border.color: sel ? "#ffffff" : "#26ffffff"
                        }
                    }
                }
            }

            // Section 3: CONSOLES (D-Pad-Only Console Switcher)
            Column {
                width: parent.width
                spacing: root.px(8)
                visible: root.hubConsoleItems.length > 0

                Text {
                    text: "CONSOLES  •  SWITCH LIBRARY"
                    color: root.hubSection === 3 ? "#5cd6ff" : "#ccffffff"
                    font.pixelSize: root.sz(15)
                    font.bold: true
                    font.letterSpacing: 1.6
                }

                ListView {
                    id: hubConsoleList
                    width: parent.width
                    height: root.sz(50)
                    orientation: ListView.Horizontal
                    spacing: root.px(12)
                    clip: true
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: width * 0.8
                    highlightMoveDuration: 220
                    model: root.hubReady ? root.hubConsoleItems : []

                    delegate: Rectangle {
                        property bool sel: root.hubSection === 3 && index === root.hubConsoleIdx
                        property bool cur: index === root.tabIndex
                        width: Math.max(root.sz(110), cLbl.implicitWidth + root.sz(36))
                        height: hubConsoleList.height - 6
                        anchors.verticalCenter: parent.verticalCenter
                        radius: height / 2
                        color: sel ? "#38ffffff" : (cur ? "#22ffffff" : "#12ffffff")
                        border.color: sel ? "#ffffff" : (cur ? "#99ffffff" : "#26ffffff")
                        border.width: sel ? 3 : 1
                        scale: sel ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        Text {
                            id: cLbl
                            anchors.centerIn: parent
                            text: modelData.label
                            color: "#ffffff"
                            font.pixelSize: root.sz(14)
                            font.bold: parent.cur
                            font.letterSpacing: 1
                        }
                    }
                }
            }
        }

        // Hub Sub-Collection View (Franchise / Multiplayer / Unplayed / Wishlist)
        Column {
            anchors.fill: parent
            anchors.leftMargin: parent.width * 0.055
            anchors.rightMargin: parent.width * 0.055
            anchors.topMargin: parent.height * 0.08
            spacing: root.px(18)
            visible: root.hubSubOpen

            Column {
                spacing: 4
                Text { text: root.hubSubTag; color: "#66aaff"; font.pixelSize: root.sz(13); font.bold: true; font.letterSpacing: 2 }
                Text { text: root.hubSubTitle + " (" + root.hubSubGames.length + ")"; color: "#ffffff"; font.pixelSize: root.sz(30); font.bold: true }
                Text {
                    text: root.hubSubGames.length > 0 && root.hubSubIdx < root.hubSubGames.length
                          ? root.cleanTitle(root.hubSubGames[root.hubSubIdx].title) + "  •  " + root.themeFor(root.gameShortName(root.hubSubGames[root.hubSubIdx])).badge
                          : "No games in this folder yet"
                    color: "#ccffffff"; font.pixelSize: root.sz(18); font.bold: true
                }
            }

            ListView {
                id: hubSubList
                width: parent.width
                height: root.height * 0.50
                orientation: ListView.Horizontal
                spacing: root.px(26)
                clip: false
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: 0
                preferredHighlightEnd: preferredHighlightBegin + height * 0.74
                highlightMoveDuration: 340
                model: root.hubSubOpen ? root.hubSubGames : []

                delegate: Rectangle {
                    property bool sel: index === root.hubSubIdx && !root.actionOpen
                    width: hubSubList.height * 0.74
                    height: hubSubList.height - 12
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 14
                    color: "#090f1e"
                    z: sel ? 4 : 1
                    scale: sel ? 1.07 : 0.89
                    opacity: sel ? 1.0 : 0.80
                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                    Rectangle { anchors.fill: parent; anchors.margins: -4;  radius: 18; color: "transparent"; border.color: "#66ffffff"; border.width: 4; visible: sel }
                    Rectangle { anchors.fill: parent; anchors.margins: -10; radius: 24; color: "transparent"; border.color: "#28ffffff"; border.width: 6; visible: sel }

                    Image {
                        id: subImg
                        property int st: root.artStageOf(modelData)
                        anchors.fill: parent; anchors.margins: 4
                        source: root.gameBoxArt(modelData, root.cacheRev, st)
                        sourceSize.width: 512; sourceSize.height: 512
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        visible: status === Image.Ready
                        onStatusChanged: if (status === Image.Error && st < 6 && root.gameLocalArt(modelData) === "") st = root.advanceArtStage(modelData)
                    }
                    Text {
                        anchors.centerIn: parent; width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; maximumLineCount: 4
                        text: root.cleanTitle(modelData.title); color: "#ffffff"; font.pixelSize: root.px(16); font.bold: true
                        visible: subImg.status !== Image.Ready
                    }
                    Rectangle {
                        anchors.fill: parent; z: 2; radius: 14; color: "transparent"
                        border.width: sel ? 4 : 2; border.color: sel ? "#ffffff" : "#26ffffff"
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // 15. KEYWORD SEARCH ENGINE OVERLAY (TV Virtual Keyboard + Live Filter)
    // ------------------------------------------------------------------

    Rectangle {
        id: searchOverlay
        anchors.fill: parent
        color: "#f2050a18"
        z: 35
        opacity: root.activeView === "search" ? 1.0 : 0.0
        scale: root.activeView === "search" ? 1.0 : 0.96
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Column {
            anchors.fill: parent
            anchors.margins: parent.width * 0.05
            anchors.bottomMargin: parent.height * 0.10
            spacing: root.px(18)

            Row {
                width: parent.width
                spacing: root.px(18)

                Rectangle {
                    width: parent.width * 0.68
                    height: root.sz(54)
                    radius: root.sz(12)
                    color: "#162445"
                    border.color: "#5cd6ff"
                    border.width: 2

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: root.sz(18)
                        text: root.searchQuery.length > 0 ? ("SEARCH:  " + root.searchQuery + "_") : "TYPE ANY KEYWORD (E.G. MARIO, SONIC, DRAGON)..."
                        color: root.searchQuery.length > 0 ? "#ffffff" : "#77ffffff"
                        font.pixelSize: root.sz(18)
                        font.bold: true
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.searchQuery.length === 0 ? (root.libGames.length + " GAMES  •  TYPE TO FILTER") : (root.searchResults.length + " MATCHING GAMES")
                    color: "#5cd6ff"
                    font.pixelSize: root.sz(17)
                    font.bold: true
                    font.letterSpacing: 1
                }
            }

            Row {
                width: parent.width
                height: parent.height - root.sz(76)
                spacing: root.px(28)

                Grid {
                    columns: 6
                    spacing: root.px(8)
                    width: parent.width * 0.44

                    Repeater {
                        model: root.kbKeys
                        delegate: Rectangle {
                            property bool sel: root.searchZone === 0 && index === root.kbIndex
                            property bool flashed: index === root.kbFlashIdx
                            width: (parent.width - root.px(40)) / 6
                            height: root.sz(46)
                            radius: root.sz(8)
                            color: flashed ? "#ddffffff" : (sel ? "#2454ff" : "#18ffffff")
                            border.color: sel ? "#ffffff" : "#24ffffff"
                            border.width: sel ? 3 : 1
                            scale: sel ? 1.07 : 1.0
                            Behavior on scale { NumberAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: flashed ? "#000000" : "#ffffff"
                                font.pixelSize: modelData.length > 2 ? root.sz(11) : root.sz(16)
                                font.bold: true
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width * 0.52
                    height: parent.height
                    radius: 12
                    color: "#11ffffff"
                    border.color: root.searchZone === 1 ? "#ffffff" : "#22ffffff"
                    border.width: root.searchZone === 1 ? 2 : 1
                    clip: true

                    ListView {
                        id: searchResultsList
                        anchors.fill: parent
                        anchors.margins: root.px(12)
                        spacing: root.px(8)
                        model: root.searchResults

                        delegate: Rectangle {
                            property bool sel: root.searchZone === 1 && index === root.searchResultIdx
                            width: searchResultsList.width
                            height: root.sz(56)
                            radius: root.sz(10)
                            color: sel ? "#36ffffff" : "#0effffff"
                            border.color: sel ? "#ffffff" : "transparent"
                            border.width: 2

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: root.px(12); anchors.rightMargin: root.px(12)
                                spacing: root.px(14)

                                Image {
                                    property int st: root.artStageOf(modelData)
                                    width: root.sz(40); height: root.sz(40)
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: root.gameBoxArt(modelData, root.cacheRev, st)
                                    sourceSize.width: 256; sourceSize.height: 256
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    onStatusChanged: if (status === Image.Error && st < 6 && root.gameLocalArt(modelData) === "") st = root.advanceArtStage(modelData)
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - root.sz(70)
                                    Text {
                                        width: parent.width; elide: Text.ElideRight
                                        text: root.cleanTitle(modelData.title)
                                        color: "#ffffff"; font.pixelSize: root.sz(16); font.bold: true
                                    }
                                    Text {
                                        text: root.themeFor(root.gameShortName(modelData)).badge
                                        color: "#99ffffff"; font.pixelSize: root.sz(12); font.bold: true
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "NO GAMES MATCH \"" + root.searchQuery + "\""
                        color: "#88ffffff"
                        font.pixelSize: root.sz(18)
                        font.bold: true
                        visible: root.searchResults.length === 0
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // 16. FROSTED DEEP-BLUE GAMEDECK GLASS ACTION DRAWER
    //     Fixed top header + clipped scrolling ListView + Gliding Focus Pill
    // ------------------------------------------------------------------

    Rectangle {
        id: actionScrim
        anchors.fill: parent
        color: "#a8020612"
        z: 50
        opacity: root.actionOpen ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
    }

    Rectangle {
        id: actionDrawer
        property real baseW: Math.max(root.sz(440), root.width * 0.39)
        property real bleed: 64
        width: baseW + bleed
        height: parent.height
        x: root.actionOpen ? root.width - baseW : root.width
        visible: x < root.width
        z: 55
        gradient: Gradient {
            GradientStop { position: 0.00; color: "#f20c1c45" }
            GradientStop { position: 0.45; color: "#f508122b" }
            GradientStop { position: 1.00; color: "#f8040814" }
        }
        Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 0.80 } }

        // Crisp luminous glass left edge
        Rectangle { width: 3; height: parent.height; color: "#ccffffff" }
        Rectangle { x: 3; width: 12; height: parent.height; gradient: Gradient {
            GradientStop { position: 0.0; color: "#22ffffff" }
            GradientStop { position: 1.0; color: "#00ffffff" }
        } }

        // Fixed Header (Never clips off top on 720p or 1080p)
        Column {
            id: actionHead
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: root.px(28)
            anchors.rightMargin: root.px(28) + actionDrawer.bleed
            anchors.topMargin: parent.height * 0.036
            spacing: root.px(10)

            property var ag: root.actionGame
            property var aTheme: root.themeFor(root.gameShortName(ag))

            Text {
                text: parent.aTheme.badge + "  •  " + parent.aTheme.tag
                color: parent.aTheme.accent
                font.pixelSize: root.sz(12)
                font.bold: true
                font.letterSpacing: 1.8
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: parent.ag ? root.cleanTitle(parent.ag.title) : ""
                color: "#ffffff"
                font.pixelSize: root.sz(22)
                font.bold: true
            }

            // TOP ROW: 3 BIG SELECTABLE ICON BUTTONS (▶ PLAY, ★ FAVORITE, ♡ WISHLIST)
            Row {
                width: parent.width
                spacing: root.px(10)

                Repeater {
                    model: {
                        var _rev = root.cacheRev;
                        var fav = !!(root.actionGame && root.actionGame.favorite);
                        var wl = root.isWishlisted(root.actionGame, _rev);
                        return [
                            { icon: "▶", label: "PLAY", accent: "#2454ff" },
                            { icon: fav ? "★" : "☆", label: fav ? "FAVED" : "FAVORITE", accent: "#d99b00" },
                            { icon: wl ? "♥" : "♡", label: wl ? "SAVED" : "WISHLIST", accent: "#d63384" }
                        ];
                    }
                    delegate: Rectangle {
                        property bool sel: root.actionZone === 0 && index === root.actionIconIdx
                        width: (parent.width - root.px(20)) / 3
                        height: root.sz(72)
                        radius: root.sz(12)
                        color: sel ? modelData.accent : "#1cffffff"
                        border.color: sel ? "#ffffff" : "#30ffffff"
                        border.width: sel ? 3 : 1
                        scale: sel ? 1.06 : 0.97
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 140 } }

                        // Expanding press-ripple ring
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                            radius: parent.radius
                            color: "transparent"
                            border.color: "#ffffff"
                            border.width: 3
                            scale: root.actionRippleScale
                            opacity: sel ? root.actionRippleOpacity : 0.0
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; color: "#ffffff"; font.pixelSize: root.sz(22); font.bold: true }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: "#ffffff"; font.pixelSize: root.sz(11); font.bold: true; font.letterSpacing: 1 }
                        }
                    }
                }
            }

            // Big & Crisp Couch-Readable Description & Play Stats Card
            Rectangle {
                width: parent.width
                height: infoCol.implicitHeight + root.px(20)
                radius: root.sz(12)
                color: "#22ffffff"
                border.color: "#38ffffff"
                border.width: 1.5
                visible: descTxt.text.length > 0 || statsRow.visible

                Column {
                    id: infoCol
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: root.px(14)
                    spacing: 8

                    Text {
                        id: descTxt
                        width: parent.width
                        wrapMode: Text.WordWrap
                        maximumLineCount: root.height < 900 ? 3 : 4
                        lineHeight: 1.22
                        elide: Text.ElideRight
                        text: root.gameDescription(root.actionGame, root.cacheRev)
                        color: "#ffffff"
                        font.pixelSize: root.sz(17)
                        font.weight: Font.Medium
                        visible: text.length > 0
                    }

                    Row {
                        id: statsRow
                        spacing: root.sz(14)
                        property string pt: root.actionGame ? root.formatPlayTime(root.actionGame.playTime) : ""
                        property int pc: (root.actionGame && root.actionGame.playCount) ? root.actionGame.playCount : 0
                        property string lp: root.formatLastPlayed(root.actionGame)
                        visible: pt.length > 0 || pc > 0 || lp.length > 0

                        Text { text: "PLAYED: " + parent.pc + "x"; color: "#bbffffff"; font.pixelSize: root.sz(12); font.bold: true; visible: parent.pc > 0 }
                        Text { text: "TIME: " + parent.pt; color: "#bbffffff"; font.pixelSize: root.sz(12); font.bold: true; visible: parent.pt.length > 0 }
                        Text { text: "LAST: " + parent.lp; color: "#bbffffff"; font.pixelSize: root.sz(12); font.bold: true; visible: parent.lp.length > 0 }
                    }
                }
            }
        }

        // Scrollable Clipped Options List with Gliding Focus Highlight Pill
        ListView {
            id: actionList
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: actionHead.bottom
            anchors.bottom: actionHint.top
            anchors.leftMargin: root.px(28)
            anchors.rightMargin: root.px(28) + actionDrawer.bleed
            anchors.topMargin: root.px(10)
            anchors.bottomMargin: root.px(6)
            clip: true
            interactive: false
            spacing: root.px(6)
            model: root.actionMenuItems
            currentIndex: root.actionListIdx
            highlightFollowsCurrentItem: true
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: height
            highlightMoveDuration: 165

            highlight: Rectangle {
                radius: root.sz(9)
                color: "#33ffffff"
                border.color: "#ffffff"
                border.width: 2
                opacity: root.actionZone === 1 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 140 } }

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: parent.height * 0.54
                    radius: 2
                    color: "#ffffff"
                }
            }

            delegate: Item {
                property bool sel: root.actionZone === 1 && index === root.actionListIdx
                width: actionList.width
                height: root.sz(42)

                Rectangle {
                    anchors.fill: parent
                    radius: root.sz(9)
                    color: "#0affffff"
                    border.color: "#18ffffff"
                    border.width: 1
                    visible: !parent.sel
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: root.sz(18)
                    anchors.right: parent.right; anchors.rightMargin: root.sz(10)
                    elide: Text.ElideRight
                    text: root.actionLabel(modelData.id)
                    color: parent.sel ? "#ffffff" : "#bbffffff"
                    font.pixelSize: root.sz(14)
                    font.bold: true
                    font.letterSpacing: 1
                }
            }
        }

        Text {
            id: actionHint
            anchors.left: parent.left
            anchors.leftMargin: root.px(28)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.px(16)
            text: "[←/→ ↑/↓]  MOVE        [A]  SELECT        [B]  BACK"
            color: "#99ffffff"
            font.pixelSize: root.sz(12)
            font.bold: true
            font.letterSpacing: 1
        }
    }

    // ------------------------------------------------------------------
    // 17. Bottom Footer Bar (Geometric Console Emblem + Frosted Badges)
    // ------------------------------------------------------------------

    Item {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: parent.width * 0.045
        anchors.rightMargin: parent.width * 0.045
        anchors.bottomMargin: parent.height * 0.032
        height: root.sz(42)
        z: 40

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.sz(10)

            Rectangle {
                width: root.sz(30); height: root.sz(20); radius: root.sz(6)
                color: "transparent"; border.color: "#ccffffff"; border.width: 2
                anchors.verticalCenter: parent.verticalCenter
                Rectangle { x: root.sz(6); y: root.sz(8); width: root.sz(8); height: root.sz(2.5); color: "#ffffff" }
                Rectangle { x: root.sz(8.8); y: root.sz(5.2); width: root.sz(2.5); height: root.sz(8); color: "#ffffff" }
                Rectangle { x: root.sz(19); y: root.sz(6); width: root.sz(3); height: root.sz(3); radius: 2; color: "#ffd644" }
                Rectangle { x: root.sz(22); y: root.sz(10); width: root.sz(3); height: root.sz(3); radius: 2; color: "#5cd6ff" }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.appName
                color: "#d8ffffff"
                font.pixelSize: root.sz(15)
                font.bold: true
                font.letterSpacing: 2.5
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.sz(14)
            visible: !root.actionOpen

            Repeater {
                model: root.activeView === "main"
                    ? (root.gridMode
                        ? [
                            { btn: "A", lbl: "ACTIONS" },
                            { btn: "X", lbl: "HUB" },
                            { btn: "Y", lbl: "SEARCH" }
                          ]
                        : [
                            { btn: "A", lbl: "ACTIONS" },
                            { btn: "X", lbl: "HUB" },
                            { btn: "Y", lbl: "SEARCH" },
                            { btn: "↓", lbl: "CONSOLE" }
                          ])
                    : [
                        { btn: "B", lbl: "BACK" },
                        { btn: "A", lbl: "SELECT" }
                      ]
                delegate: Rectangle {
                    height: root.sz(34)
                    width: promptRow.implicitWidth + root.sz(22)
                    radius: height / 2
                    color: "#28ffffff"
                    border.color: "#38ffffff"
                    border.width: 1

                    Row {
                        id: promptRow
                        anchors.centerIn: parent
                        spacing: root.sz(8)
                        Rectangle {
                            width: root.sz(22); height: root.sz(22); radius: width / 2
                            color: "#44ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: modelData.btn; color: "#ffffff"; font.pixelSize: root.sz(12); font.bold: true }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.lbl
                            color: "#f2ffffff"
                            font.pixelSize: root.sz(13)
                            font.bold: true
                            font.letterSpacing: 1
                        }
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // 17B. Built-In Android TV Controller Fix Guide (Accessibility Blocker)
    // ------------------------------------------------------------------

    Rectangle {
        id: ctrlFixOverlay
        anchors.fill: parent
        color: "#cc020612"
        z: 70
        opacity: root.controllerFixOpen ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.78, root.sz(760))
            height: ctrlFixCol.implicitHeight + root.px(56)
            radius: root.sz(18)
            color: "#f50a183b"
            border.color: "#ffffff"
            border.width: 2.5
            scale: root.controllerFixOpen ? 1.0 : 0.94
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }

            Column {
                id: ctrlFixCol
                anchors.left: parent.left; anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: root.px(32)
                spacing: root.px(14)

                Text {
                    text: "CONTROLLER A / B / X / Y NOT WORKING ON ANDROID TV?"
                    color: "#ffd644"
                    font.pixelSize: root.sz(20)
                    font.bold: true
                    font.letterSpacing: 1.2
                    width: parent.width
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    lineHeight: 1.22
                    text: "If your joystick scrolls but A, B, X, Y do nothing, an active Android TV Accessibility Service (such as a custom launcher or button remapper) is blocking gamepad buttons."
                    color: "#f2ffffff"
                    font.pixelSize: root.sz(16)
                }

                Rectangle {
                    width: parent.width
                    height: fixStep1.implicitHeight + root.px(20)
                    radius: root.sz(10)
                    color: "#1effffff"
                    border.color: "#33ffffff"
                    border.width: 1
                    Text {
                        id: fixStep1
                        anchors.fill: parent
                        anchors.margins: root.px(10)
                        wrapMode: Text.WordWrap
                        lineHeight: 1.25
                        text: "FIX 1 (TV SETTINGS):  Open Android Settings -> Device Preferences -> Accessibility -> Turn OFF active services -> Restart Pegasus."
                        color: "#ffffff"
                        font.pixelSize: root.sz(15)
                        font.bold: true
                    }
                }

                Rectangle {
                    width: parent.width
                    height: fixStep2.implicitHeight + root.px(22)
                    radius: root.sz(10)
                    color: "#22000000"
                    border.color: "#5cd6ff"
                    border.width: 1.5
                    Text {
                        id: fixStep2
                        anchors.fill: parent
                        anchors.margins: root.px(11)
                        wrapMode: Text.WordWrap
                        lineHeight: 1.28
                        text: "FIX 2 (atvTools / ADB SHELL):\nsettings put secure enabled_accessibility_services \"\"\nsettings put secure accessibility_enabled 0\nam force-stop org.pegasus_frontend.android"
                        color: "#7ae6ff"
                        font.pixelSize: root.sz(14)
                        font.bold: true
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "PRESS [A] OR [B] TO CLOSE"
                    color: "#ccffffff"
                    font.pixelSize: root.sz(14)
                    font.bold: true
                    font.letterSpacing: 1.5
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // 18. Toast Pill (Bottom-Center Spring Bounce)
    // ------------------------------------------------------------------

    Rectangle {
        id: toast
        property real restY: root.height * 0.855 - height
        anchors.horizontalCenter: parent.horizontalCenter
        height: root.sz(44)
        width: toastLabel.implicitWidth + root.sz(44)
        radius: height / 2
        z: 75
        color: "#ee0c152e"
        border.color: "#ffffff"
        border.width: 2
        y: root.toastVisible ? restY : restY + root.sz(22)
        opacity: root.toastVisible ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on y       { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

        Text {
            id: toastLabel
            anchors.centerIn: parent
            text: root.toastText
            color: "#ffffff"
            font.pixelSize: root.sz(15)
            font.bold: true
            font.letterSpacing: 1.2
        }
    }

    // ------------------------------------------------------------------
    // 19. TV Idle Screensaver (35% Dim + Gently Breathing Clock)
    // ------------------------------------------------------------------

    Rectangle {
        id: screensaverOverlay
        anchors.fill: parent
        color: "#a6000000"
        z: 85
        opacity: root.screensaverActive ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 600 } }

        Column {
            anchors.centerIn: parent
            spacing: root.sz(14)
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.clockText
                color: "#d8ffffff"
                font.pixelSize: root.sz(76)
                font.bold: true
                font.letterSpacing: 4
                opacity: 0.85
                SequentialAnimation on opacity {
                    running: root.screensaverActive
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.65; to: 1.0; duration: 2400; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.0; to: 0.65; duration: 2400; easing.type: Easing.InOutSine }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.appName + "  •  PRESS ANY BUTTON TO RESUME"
                color: "#77ffffff"
                font.pixelSize: root.sz(15)
                font.bold: true
                font.letterSpacing: 2.5
            }
        }
    }

    // ------------------------------------------------------------------
    // 20. Launch Fade-to-Black Curtain & Hub/Search Launch Flash
    // ------------------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        z: 95
        opacity: root.launchFade
        visible: opacity > 0.01
    }

    Rectangle {
        anchors.fill: parent
        color: "#ffffff"
        z: 94
        opacity: root.activeView === "main" ? 0.0 : 0.30 * root.launchPhase
        visible: opacity > 0.01
    }

    // ------------------------------------------------------------------
    // 21. Console Boot Splash Overlay (z: 100, synced to sounds/boot.wav)
    // ------------------------------------------------------------------

    Rectangle {
        id: splashOverlay
        anchors.fill: parent
        color: "#000000"
        z: 100
        visible: root.splashActive
        opacity: 1.0

        Rectangle {
            width: parent.width * 2.0
            height: parent.height * 2.0
            anchors.centerIn: parent
            rotation: -33
            gradient: Gradient {
                GradientStop { position: 0.00; color: "#000000" }
                GradientStop { position: 0.455; color: "#000000" }
                GradientStop { position: 0.50; color: "#0c28b8" }
                GradientStop { position: 0.78; color: "#2454ff" }
                GradientStop { position: 1.00; color: "#6694ff" }
            }
        }

        Column {
            id: splashLogo
            anchors.centerIn: parent
            spacing: root.sz(16)
            opacity: 0.0
            scale: 0.86

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.appName
                color: "#ffffff"
                font.pixelSize: root.sz(64)
                font.bold: true
                font.letterSpacing: 8
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.sz(290)
                height: root.sz(5)

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * root.splashBarProgress + root.sz(42)
                    height: root.sz(30)
                    radius: height / 2
                    color: "#1c2454ff"
                    opacity: root.splashBarProgress
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * root.splashBarProgress + root.sz(18)
                    height: root.sz(14)
                    radius: height / 2
                    color: "#3c6694ff"
                    opacity: root.splashBarProgress
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * root.splashBarProgress
                    height: parent.height
                    radius: 3
                    color: "#ffffff"
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "LIVING-ROOM CONSOLE DASHBOARD"
                color: "#ccffffff"
                font.pixelSize: root.sz(16)
                font.bold: true
                font.letterSpacing: 4
            }
        }
    }
}