{ pkgs, lib, user, ... }:
let
  isDeveloper = user.developer or false;
  isDarwin = pkgs.stdenv.isDarwin;

  androidComposition = pkgs.androidenv.composeAndroidPackages {
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

  chromeExecutable = if isDarwin
    then "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    else "${pkgs.google-chrome}/bin/google-chrome-stable";
in
lib.mkIf isDeveloper {
  home.packages = [
    pkgs.flutter
    pkgs.jdk17
    androidSdk
  ] ++ lib.optionals (!isDarwin) [
    pkgs.google-chrome
  ];

  home.sessionVariables = {
    ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
    ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
    JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
    CHROME_EXECUTABLE = chromeExecutable;
  };
}
