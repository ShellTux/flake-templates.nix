{
  description = "flake-templates.nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

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

      scriptDrvs = forEachSupportedSystem (
        { pkgs }:
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
        }
      );
    in
    {
      formatter = forEachSupportedSystem ({ pkgs }: pkgs.nixfmt-tree);

      devShells = forEachSupportedSystem (
        { pkgs }:
        let
          inherit (pkgs) system mkShell;
          inherit (pkgs.lib) getExe;
          onefetch = getExe pkgs.onefetch;
        in
        {
          default = mkShell {
            packages = with scriptDrvs.${system}; [
              check
              update
            ];

            shellHook = ''
              ${onefetch} --no-bots 2>/dev/null
            '';
          };
        }
      );

      templates = rec {
        default = empty;

        c-cpp = {
          path = ./c-cpp;
          description = "C/C++ development enviroment";
          welcomeText = ''
            # C/C++ Development environment

            ## More info
              - [C language](https://en.wikipedia.org/wiki/C_(programming_language))
              - [C++ language](https://en.wikipedia.org/wiki/C%2B%2B)
              - [C/C++ on the NixOS Wiki](https://nixos.wiki/wiki/C)
              - [C/C++ reference](https://en.cppreference.com/w/c)
          '';
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
          welcomeText = ''
            # Go Development environment

            ## More info
              - [Go language](https://golang.org/)
              - [Go on the NixOS Wiki](https://nixos.wiki/wiki/Go)
          '';

        };

        java = {
          path = ./java;
          description = "Java development enviroment";
          welcomeText = ''
            # Java Development environment

            ## More info
              - [Java language](https://www.java.com/)
              - [Java on the NixOS Wiki](https://nixos.wiki/wiki/Java)
          '';
        };

        python = {
          path = ./python;
          description = "Python development enviroment";
          welcomeText = ''
            # Python Development environment

            ## More info
              - [Python language](https://www.python.org/)
              - [Python on the NixOS Wiki](https://nixos.wiki/wiki/Python)
          '';
        };

        rust = {
          path = ./rust;
          description = "Rust development enviroment";
          welcomeText = ''
            # Rust Development environment

            ## More info
                  - [Rust language](https://www.rust-lang.org/)
                  - [Rust on the NixOS Wiki](https://nixos.wiki/wiki/Rust)
          '';
        };

        shell = {
          path = ./shell;
          description = "Shell development enviroment";
          welcomeText = ''
            # Shell Development environment

            ## More info
              - [Shell Scripts](https://nixos.wiki/wiki/Shell_Scripts)
          '';
        };

        sh = shell;

        zig = {
          path = ./zig;
          description = "Zig development enviroment";
          welcomeText = ''
            # Zig Development environment

            ## More info
              - [Zig language](https://ziglang.org/)
          '';
        };
      };
    };
}
