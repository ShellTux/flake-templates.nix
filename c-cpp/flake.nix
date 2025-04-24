{
  description = "A Nix-flake-based C/C++ development environment";

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
          inherit (pkgs) system mkShell;
          inherit (pkgs.lib) getExe;

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
                packages = [
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
                ] ++ (if system == "aarch64-darwin" then [ ] else [ pkgs.gdb ]);

                shellHook = ''
                  ${onefetch} --no-bots 2>/dev/null
                '';
              };
        }
      );
    };
}
