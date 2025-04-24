{
  description = "A Nix-flake-based typst development environment";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs =
    { self, nixpkgs }:
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
            pkgs = import nixpkgs { inherit system; };
          }
        );
    in
    {
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
              pkgs.tinymist
              pkgs.typst
              pkgs.typstfmt
              pkgs.typst-live
              pkgs.typstwriter
              pkgs.typstyle
            ];

            shellHook = ''
              ${onefetch} --no-bots 2>/dev/null
            '';
          };
        }
      );
    };
}
