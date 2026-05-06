{
  description = "Helium Browser packaged for NixOS, x86_64-linux only";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    pname = "helium";
    version = "0.11.7.1";

    src = pkgs.fetchurl {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
      hash = "sha256-qzc135IP5F2btxtOMUGMz+0azJhYL9KI0lcPG2KjcxU=";
    };

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
        platforms = ["x86_64-linux"];
        mainProgram = "helium";
      };
    };
  in {
    packages.${system} = {
      default = helium;
      helium = helium;
    };

    apps.${system} = {
      default = {
        type = "app";
        program = "${helium}/bin/helium";
      };

      helium = {
        type = "app";
        program = "${helium}/bin/helium";
      };
    };

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
