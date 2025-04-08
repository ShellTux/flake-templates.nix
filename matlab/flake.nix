{
  description = "A Nix-flake-based MATLAB development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    nix-matlab = {
      url = "gitlab:doronbehar/nix-matlab";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-matlab,
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
            pkgs = import nixpkgs {
              inherit system;
            };

            nix-matlab = {
              shellHooksCommon = nix-matlab.shellHooksCommon;
              packages = nix-matlab.packages.${system};
            };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, nix-matlab }:
        let
          inherit (pkgs) mkShell;
          inherit (pkgs.lib) getExe;

          onefetch = getExe pkgs.onefetch;

          wmname = getExe pkgs.wmname;
        in
        {
          default = mkShell {
            packages = [
              nix-matlab.packages.matlab
              nix-matlab.packages.matlab-mex
              nix-matlab.packages.matlab-mlint
            ];

            shellHook = ''
              ${nix-matlab.shellHooksCommon}
              ${wmname} LG3D
              ${onefetch} --no-bots 2>/dev/null
            '';
          };
        }
      );
    };
}
