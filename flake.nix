{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });

      scriptDrvs = forEachSupportedSystem ({ pkgs }:
        let
          getSystem = "SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')";
          forEachDir = exec: ''
            for dir in */; do
              (
                cd "''${dir}"

                ${exec}
              )
            done
          '';
        in
        {
          check = pkgs.writeShellApplication {
            name = "check";
            text = forEachDir ''
              echo "checking ''${dir}"
              nix flake check --all-systems --no-build
            '';
          };

          update = pkgs.writeShellApplication {
            name = "update";
            text = forEachDir ''
              echo "updating ''${dir}"
              nix flake update
            '';
          };
        });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: let
        inherit (pkgs) system mkShell;
        inherit (pkgs.lib) getExe;
        onefetch = getExe pkgs.onefetch;
      in {
        default = mkShell {
          packages = with scriptDrvs.${system}; [
            check
            update
          ];

          shellHook = ''
            ${onefetch} --no-bots 2>/dev/null
          '';
        };
      });

      templates = rec {
        default = empty;

        c-cpp = {
          path = ./c-cpp;
          description = "C/C++ development enviroment";
        };

        c = c-cpp;
        cpp = c-cpp;

        empty = {
          path = ./empty;
          description = "Empty dev template that you can customize at will";
        };

        go = {
          path = ./go;
          description = "Go development enviroment";
        };

        java = {
          path = ./java;
          description = "Java development enviroment";
        };

        python = {
          path = ./python;
          description = "Python development enviroment";
        };

        rust = {
          path = ./rust;
          description = "Rust development enviroment";
          welcomeText = ''
      # Simple Rust/Cargo Template
      ## Intended usage
            The intended usage of this flake is...

      ## More info
            - [Rust language](https://www.rust-lang.org/)
            - [Rust on the NixOS Wiki](https://nixos.wiki/wiki/Rust)
            - ...
          '';
        };

        shell = {
          path = ./shell;
          description = "Shell development enviroment";
        };

        zig = {
          path = ./zig;
          description = "Zig development enviroment";
        };
      };
    };
}
