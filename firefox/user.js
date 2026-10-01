// Linked into the Firefox profile by install.sh. Prefs here are re-applied at every start.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true); // load chrome/userChrome.css
user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org"); // dark base under the overrides
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
