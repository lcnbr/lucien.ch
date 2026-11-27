{
  description = "lucien.ch: Typst site, build tools and browser editor";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in {
      # `nix develop`, then `python3 scripts/build.py --editor --search` and
      # `python3 scripts/serve.py`. The repo pins Typst in ./typst-version.
      devShells = forAll (pkgs: {
        default = pkgs.mkShell { packages = [ pkgs.typst pkgs.python3 pkgs.nodejs ]; };
      });
    };
}
