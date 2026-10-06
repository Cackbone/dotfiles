// Linked into the Firefox profile by install.sh. Prefs here are re-applied at every start.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true); // load chrome/userChrome.css
user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org"); // dark base under the overrides
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
// video decoded by the Intel GPU (VA-API, needs intel-media-driver; check about:support →
// Media → Codec Support Information). The GPU (Comet Lake) can't decode AV1, which YouTube
// prefers whenever the browser offers it: without AV1, YouTube sends VP9, decoded by the GPU
user_pref("media.hardware-video-decoding.enabled", true);
user_pref("media.av1.enabled", false);
