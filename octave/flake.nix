{
  description = "A Nix-flake-based Octave development environment";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      # Some octave packages are not supported for some systems
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        # "x86_64-darwin"
        # "aarch64-darwin"
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
          inherit (pkgs) mkShell;
          inherit (pkgs.lib) getExe;

          octave = pkgs.octaveFull.withPackages (octavePackages: [
            octavePackages.audio
            octavePackages.image
            octavePackages.linear-algebra
            octavePackages.ltfat
            octavePackages.matgeom
            octavePackages.signal
            octavePackages.statistics
            octavePackages.symbolic
          ]);

          onefetch = getExe pkgs.onefetch;
        in
        {
          default = mkShell {
            packages = [ octave ];

            shellHook = ''
              ${onefetch} --no-bots 2>/dev/null
            '';

            env = {
              INFOPATH = "${octave}/share/info";
            };
          };
        }
      );
    };
}
