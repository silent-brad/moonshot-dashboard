{
  description = "ESP32 Touchscreen Dev Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python311;
        esp-idf = pkgs.fetchgit {
          url = "https://github.com/espressif/esp-idf.git";
          rev = "v5.2";
          sha256 = "sha256-+tAb32TXeMZzU7QiVlRYMKKUCkqGiOIMdL4vzUgGbzA=";
          fetchSubmodules = true;
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python
            python311Packages.pip
            python311Packages.virtualenv
            cmake
            ninja
            git
            wget
            gnumake
            flex
            bison
            gperf
            ccache
            libffi
            libusb1
            openssl
            dfu-util
            luajit
            freetype
          ];

          shellHook = ''
            export IDF_PATH="${esp-idf}"
            export IDF_TOOLS_PATH="$HOME/.espressif"
            export LD_LIBRARY_PATH="${
              pkgs.lib.makeLibraryPath [
                pkgs.libusb1
                pkgs.zlib
                pkgs.stdenv.cc.cc.lib
                pkgs.freetype
              ]
            }:$LD_LIBRARY_PATH"

            # Track which ESP-IDF version tools were installed for
            IDF_HASH=$(echo "${esp-idf}" | sha256sum | cut -c1-16)
            TOOLS_MARKER="$IDF_TOOLS_PATH/tools_installed_$IDF_HASH"

            if [ ! -f "$TOOLS_MARKER" ]; then
              echo "Installing ESP-IDF tools for ${esp-idf}..."
              rm -f "$IDF_TOOLS_PATH"/tools_installed_*
              python "${esp-idf}/tools/idf_tools.py" install --targets esp32s3
              touch "$TOOLS_MARKER"
            fi

            VENV_DIR="$IDF_TOOLS_PATH/python_env/idf5.2_py3.11_env"
            VENV_MARKER="$VENV_DIR/.installed_$IDF_HASH"

            if [ ! -f "$VENV_MARKER" ]; then
              echo "Creating Python virtual environment..."
              rm -rf "$VENV_DIR"
              python "${esp-idf}/tools/idf_tools.py" install-python-env
              touch "$VENV_MARKER"
            fi

            # Activate the ESP-IDF Python venv first
            if [ -f "$VENV_DIR/bin/activate" ]; then
              source "$VENV_DIR/bin/activate"
            fi

            source "${esp-idf}/export.sh"
          '';
        };
      });
}
