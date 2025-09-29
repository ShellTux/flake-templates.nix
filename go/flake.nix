{
  description = "A Nix-flake-based Go 1.22 development environment";

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
      goVersion = 24; # Change this to update the whole stack

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

            pkgs = import nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
            };
          }
        );
    in
    {
      overlays.default = final: prev: {
        go = final."go_1_${toString goVersion}";
      };

      checks = forEachSupportedSystem (
        { pkgs, system, ... }:
        {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              gofmt.enable = true;
              gotest.enable = true;
              nixfmt-rfc-style.enable = true;
            };
          };
        }
      );

      devShells = forEachSupportedSystem (
        { pkgs, system, ... }:
        let
          inherit (pkgs) mkShell;
          inherit (pkgs) go gotools golangci-lint; # go (version is specified by overlay)
          inherit (pkgs.lib) getExe;
          inherit (self.checks."${system}") pre-commit-check;

          onefetch = getExe pkgs.onefetch;
        in
        {
          default = mkShell {
            packages =
              [
                go

                # goimports, godoc, etc.
                gotools

                # https://github.com/golangci/golangci-lint
                golangci-lint
              ]
              ++ [
                pkgs.entr
                pkgs.fd
                pkgs.jq
                pkgs.ripgrep
                pkgs.ripgrep-all
                pkgs.tokei
              ]
              ++ pre-commit-check.enabledPackages;

            shellHook = ''
              ${pre-commit-check.shellHook}
              ${onefetch} --no-bots 2>/dev/null
            '';
          };
        }
      );
    };
}
