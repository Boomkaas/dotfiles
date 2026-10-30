// Firefox prefs applied on every start (overrides about:config).

// Load chrome/userChrome.css and chrome/userContent.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Dark everywhere: browser UI, about: pages, and sites' prefers-color-scheme
user_pref("browser.theme.toolbar-theme", 0);
user_pref("browser.theme.content-theme", 0);
user_pref("layout.css.prefers-color-scheme.content-override", 0);

// Black instead of grey/white while a page is loading or blank
user_pref("browser.display.background_color", "#000000");
user_pref("browser.display.background_color.dark", "#000000");
