{
  description = "Flutter development environment (Linux Desktop + Optional Android)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        includeAndroid = false; # Set to true when you want the 8GB Android SDK

        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };

        # Only define the heavy SDK if includeAndroid is true
        androidSdk = if includeAndroid then 
          (pkgs.androidenv.composeAndroidPackages {
            buildToolsVersions = [ "34.0.0" ];
            platformVersions = [ "34" "33" ];
            abiVersions = [ "x86_64" "arm64-v8a" ];
            includeEmulator = true;
            includeSystemImages = true;
          }).androidsdk
          else null;

        libraries = with pkgs; [
          util-linux
          libGL
          fontconfig
          harfbuzz
          at-spi2-core
          pango
          pcre2
          gdk-pixbuf
          gtk3
          glib
          libepoxy
          cairo
          libsysprof-capture
          libselinux
          libsepol
          libthai
          libdatrie
          libdeflate
          pcre
          xorg.libXdmcp
          xorg.libXtst
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          name = "flutter-env";

          nativeBuildInputs = with pkgs; [
            fvm
            cmake
            ninja
            pkg-config
            clang
          ] ++ (if includeAndroid then [ androidSdk jdk17 ] else []);

          buildInputs = libraries;

          shellHook = ''
            # Linux Desktop Paths
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH"
            export PKG_CONFIG_PATH="${pkgs.lib.makeSearchPath "lib/pkgconfig" (map (x: x.dev or x) libraries)}:$PKG_CONFIG_PATH"

            ${if includeAndroid then ''
              # Android Specific Paths
              export ANDROID_HOME="${androidSdk}/libexec/android-sdk"
              export ANDROID_SDK_ROOT="${androidSdk}/libexec/android-sdk"
              export JAVA_HOME="${pkgs.jdk17.home}"
              export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/34.0.0/aapt2"
              echo "🤖 Android SDK included."
            '' else ''
              echo "🖥️ Linux Desktop mode (Android SDK omitted)."
            ''}
            
            echo "✅ Run 'flutter doctor' to check status."
            # For Fish users
            if [ "$SHELL" = "$(which fish)" ]; then
              exec fish
            fi
          '';
        };
      }
    );
}
