module.exports = {
  config: {
    // Choose either "stable" for the stable release or "canary" for the beta release
    updateChannel: 'stable',

    // Default font size in pixels for all tabs
    fontSize: 14,

    // Font family with optional fallbacks
    fontFamily: 'HackGen Console NF, Menlo, "DejaVu Sans Mono", Consolas, "Lucida Console", monospace',

    // Default shell to run when Hyper starts
    shell: '/bin/zsh',

    // Shell arguments
    shellArgs: ['--login'],

    // Set to true if you're using a Linux setup that doesn't show native menus
    // default: `false` on Linux, `true` on Windows (ignored on macOS)
    showHamburgerMenu: '',

    // Set to false if you want to hide the minimize, maximize, and close buttons
    // additionally, set to `'left'` if you want them on the left, like in Ubuntu
    // default: `true` on Windows and Linux (ignored on macOS)
    showWindowControls: '',

    // Custom CSS to embed in the main window
    css: '',

    // Custom CSS to embed in the terminal window
    termCSS: '',

    // If true, selected text will automatically be copied to the clipboard
    copyOnSelect: false,

    // Plugins to install from npm
    plugins: [
      'hyper-snazzy', // Example theme plugin
      'hyper-statusline', // Example status line plugin
    ],

    // Local plugins (not from npm)
    localPlugins: [],

    // Keymaps
    keymaps: {
      // Example: 'window:devtools': 'cmd+alt+o',
    },
  },

  // A list of plugins to fetch and install from npm
  // Format: [@org/]project[#version]
  // Examples:
  //   `hyperpower`
  //   `@company/project`
  //   `project#1.0.1`
  plugins: [],

  // In development, you can create a directory under
  // `~/.hyper_plugins/local/` and include it here
  // to load it and avoid it being `npm install`ed
  localPlugins: [],
};
