{
  description = "A Nix-flake-based typst development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      pre-commit-hooks,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;

            pkgs = import nixpkgs { inherit system; };
          }
        );
    in
    {
      checks = forEachSupportedSystem (
        { pkgs, system, ... }:
        {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt-rfc-style.enable = true;
              typstfmt.enable = true;
              typstyle.enable = true;
            };
          };
        }
      );

      devShells = forEachSupportedSystem (
        { pkgs, system, ... }:
        let
          inherit (pkgs) mkShellNoCC;
          inherit (pkgs.lib) getExe;
          inherit (self.checks."${system}") pre-commit-check;

          onefetch = getExe pkgs.onefetch;
        in
        {
          default = mkShellNoCC {
            packages = [
              pkgs.tinymist
              pkgs.typst
              pkgs.typstfmt
              pkgs.typst-live
              pkgs.typstwriter
              pkgs.typstyle
            ] ++ pre-commit-check.enabledPackages;

            shellHook = ''
              ${pre-commit-check.shellHook}
              ${onefetch} --no-bots 2>/dev/null
            '';
          };
        }
      );
    };
}
