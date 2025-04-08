{
  description = "A Nix-flake-based Go 1.22 development environment";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      goVersion = 24; # Change this to update the whole stack

      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      });
    in
    {
      overlays.default = final: prev: {
        go = final."go_1_${toString goVersion}";
      };

      devShells = forEachSupportedSystem ({ pkgs }: let
        inherit (pkgs) mkShell;
        inherit (pkgs) go gotools golangci-lint; # go (version is specified by overlay)
        inherit (pkgs.lib) getExe;
        onefetch = getExe pkgs.onefetch;
      in {
        default = mkShell {
          packages = [
            go

            # goimports, godoc, etc.
            gotools

            # https://github.com/golangci/golangci-lint
            golangci-lint
          ];

          shellHook = ''
            ${onefetch} --no-bots 2>/dev/null
          '';
        };
      });
    };
}
