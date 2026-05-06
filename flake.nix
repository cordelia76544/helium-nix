{
  description = "Helium Browser packaged for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    forAllSystems = f:
      nixpkgs.lib.genAttrs systems
      (system: f nixpkgs.legacyPackages.${system});
  in {
    packages = forAllSystems (pkgs: let
      pname = "helium";
      version = "0.12.1.1";

      src =
        if pkgs.stdenv.hostPlatform.system == "x86_64-linux"
        then
          pkgs.fetchurl {
            url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
            hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          }
        else if pkgs.stdenv.hostPlatform.system == "aarch64-linux"
        then
          pkgs.fetchurl {
            url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-aarch64.AppImage";
            hash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
          }
        else throw "Unsupported system";

      appimageContents = pkgs.appimageTools.extractType2 {
        inherit pname version src;
      };

      helium = pkgs.appimageTools.wrapType2 {
        inherit pname version src;

        extraPkgs = pkgs:
          with pkgs; [
            libva
            libva-utils
            vulkan-loader
            mesa
          ];

        extraInstallCommands = ''
          desktopFile="$(find ${appimageContents} -name '*.desktop' | head -n1)"

          if [ -n "$desktopFile" ]; then
            install -Dm444 "$desktopFile" "$out/share/applications/helium.desktop"

            substituteInPlace "$out/share/applications/helium.desktop" \
              --replace-regexp '^Exec=.*' 'Exec=helium %U' \
              --replace-regexp '^Name=.*' 'Name=Helium'
          fi

          if [ -d ${appimageContents}/usr/share/icons ]; then
            mkdir -p "$out/share/icons"
            cp -r ${appimageContents}/usr/share/icons/* "$out/share/icons/" || true
          fi

          if [ -d ${appimageContents}/usr/share/pixmaps ]; then
            mkdir -p "$out/share/pixmaps"
            cp -r ${appimageContents}/usr/share/pixmaps/* "$out/share/pixmaps/" || true
          fi
        '';

        meta = {
          description = "Helium Browser for Linux";
          homepage = "https://github.com/imputnet/helium-linux";
          license = pkgs.lib.licenses.gpl3Only;
          platforms = systems;
          mainProgram = "helium";
        };
      };
    in {
      default = helium;
      helium = helium;
    });

    apps = forAllSystems (pkgs: {
      default = {
        type = "app";
        program = "${self.packages.${pkgs.system}.default}/bin/helium";
      };
    });

    overlays.default = final: prev: {
      helium = self.packages.${final.system}.default;
    };

    homeManagerModules.default = {pkgs, ...}: {
      home.packages = [
        self.packages.${pkgs.system}.default
      ];
    };
  };
}
