{
  description = "A Nix-flake-based C/C++ development environment";

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
              clang-format.enable = true;
              nixfmt-rfc-style.enable = true;
            };
          };
        }
      );

      devShells = forEachSupportedSystem (
        { pkgs, system, ... }:
        let
          inherit (pkgs) mkShell;
          inherit (pkgs.lib) getExe;
          inherit (self.checks."${system}") pre-commit-check;

          onefetch = getExe pkgs.onefetch;
        in
        {
          default =
            mkShell.override
              {
                # Override stdenv in order to change compiler:
                # stdenv = pkgs.clangStdenv;
              }
              {
                packages =
                  [
                    pkgs.clang-tools
                    pkgs.cmake
                    pkgs.codespell
                    pkgs.conan
                    pkgs.cppcheck
                    pkgs.doxygen
                    pkgs.gtest
                    pkgs.lcov
                    pkgs.vcpkg
                    pkgs.vcpkg-tool
                  ]
                  ++ (if system == "aarch64-darwin" then [ ] else [ pkgs.gdb ])
                  ++ pre-commit-check.enabledPackages;

                shellHook = ''
                  ${pre-commit-check.shellHook}
                  ${onefetch} --no-bots 2>/dev/null
                '';
              };
        }
      );

      packages = forEachSupportedSystem (
        { pkgs, system, ... }:
        let
          inherit (pkgs.stdenv) mkDerivation;
        in
        {
          default = mkDerivation {
            name = "c-cpp";
            src = ./.;

            installPhase = ''
              mkdir --parents $out/bin
              cp target/release/* $out/bin
            '';
          };
        }
      );
    };
}
