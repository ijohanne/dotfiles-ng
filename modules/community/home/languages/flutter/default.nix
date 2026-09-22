{ config, pkgs-unstable, pkgs, lib, user, ... }:
let
  isDeveloper = user.developer or false;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  androidComposition = pkgs-unstable.androidenv.composeAndroidPackages {
    buildToolsVersions = [ "34.0.0" "30.0.3" ];
    platformVersions = [ "34" "33" ];
    abiVersions = [ "arm64-v8a" "x86_64" ];
    includeEmulator = true;
    includeSystemImages = true;
    systemImageTypes = [ "google_apis" ];
    includeSources = false;
    includeNDK = false;
  };

  androidSdk = androidComposition.androidsdk;

  chromeExecutable =
    if isDarwin
    then "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    else "${pkgs-unstable.google-chrome}/bin/google-chrome-stable";
in
lib.mkIf isDeveloper {
  home.packages = [
    pkgs-unstable.flutter
    pkgs-unstable.jdk17
    androidSdk
  ] ++ lib.optionals isDarwin [
    pkgs-unstable.cocoapods
  ] ++ lib.optionals (!isDarwin) [
    pkgs-unstable.google-chrome
  ];

  home.sessionVariables = {
    ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
    ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
    JAVA_HOME = "${pkgs-unstable.jdk17}/lib/openjdk";
    CHROME_EXECUTABLE = chromeExecutable;
  };

  programs.nixvim = {
    extraPlugins = with pkgs-unstable.vimPlugins; [
      flutter-tools-nvim
      plenary-nvim
    ];

    plugins.treesitter.grammarPackages = [
      config.programs.nixvim.plugins.treesitter.package.builtGrammars.dart
    ];

    extraConfigLua = ''
      require("flutter-tools").setup({
        lsp = {
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            enableSnippets = true,
          },
        },
        widget_guides = { enabled = true },
        closing_tags = { enabled = true },
      })
    '';
  };
}
