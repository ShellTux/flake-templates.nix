{
  description = "A Nix-flake-based Node.js development environment";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs =
    { self, nixpkgs }@inputs:
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
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ inputs.self.overlays.default ];
            };
          }
        );
    in
    {
      overlays.default = final: prev: rec {
        nodejs = prev.nodejs;
        yarn = (prev.yarn.override { inherit nodejs; });
      };

      devShells = forEachSupportedSystem (
        { pkgs }:
        let
          inherit (pkgs) mkShellNoCC;
          inherit (pkgs.lib) getExe;

          onefetch = getExe pkgs.onefetch;
        in
        {
          default = mkShellNoCC {
            packages = [
              pkgs.node2nix
              pkgs.nodejs
              pkgs.nodePackages.pnpm
              pkgs.yarn
            ];

            shellHook = ''
              ${onefetch} --no-bots 2>/dev/null
            '';
          };
        }
      );
    };
}
