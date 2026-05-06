# helium-nix

A minimal Nix flake for packaging [Helium Browser for Linux](https://github.com/imputnet/helium-linux) on `x86_64-linux`.

This flake wraps the official Helium Linux AppImage with Nix `appimageTools.wrapType2`.

## Status

- Architecture: `x86_64-linux` only
- Package format: official AppImage
- DRM/Widevine: not included by default
- Auto update: GitHub Actions workflow included

## Usage

### Run directly

```bash
nix run github:cordelia76544/helium-nix
```
### Build
```bash
nix build github:cordelia76544/helium-nix
./result/bin/helium
```
### Use as a flake input
Add this to your flake.nix:
```nix
inputs = {
  helium = {
    url = "github:cordelia76544/helium-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```
Then install it with Home Manager:
```nix
{ pkgs, inputs, ... }:

{
  home.packages = [
    inputs.helium.packages.${pkgs.system}.default
  ];
}
```
Make sure your Home Manager configuration receives inputs, for example:
```nix
home-manager.extraSpecialArgs = {
  inherit inputs;
};
```
#### Use the Home Manager module
```nix
{
  imports = [
    inputs.helium.homeManagerModules.default
  ];
}
```
## updating
This repository includes update.sh, which fetches the latest Helium Linux release and updates the AppImage hash.

Run manually:
```bash
./update.sh
nix build .#helium
```
The GitHub Actions workflow can also run automatically and create an update pull request.

## Notes

This project does not build Helium from source. It only wraps the official Linux AppImage release.

Widevine DRM is not bundled. Streaming services that require Widevine, such as Netflix or some paid movie platforms, may not work in Helium by default.

## License

The Nix packaging code in this repository is licensed under the MIT License.

Helium Browser itself is developed by the Helium authors and is licensed separately. See the upstream repositories:

https://github.com/imputnet/helium

https://github.com/imputnet/helium-linux
