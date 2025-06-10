{
  description = "flake-templates.nix flake";

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

      scriptDrvs = forEachSupportedSystem (
        { pkgs, ... }:
        let
          inherit (pkgs.lib) getExe;

          getSystem = "SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')";

          parallel = getExe (
            pkgs.parallel-full.override {
              willCite = true;
            }
          );

          forEachDir =
            {
              exec,
              jobs ? 4,
            }:
            let
              inherit (builtins) concatStringsSep toString;

              exec_statements = concatStringsSep " && " exec;
            in
            ''
              # shellcheck disable=SC2012,SC2016,SC2035
              find . -mindepth 2 -maxdepth 2 -type f -name flake.nix -printf '%h\n' \
                | sort --unique \
                | ${parallel} --keep-order --group --color --color-failed --jobs ${toString jobs} \
                  'dir={}; cd "$dir" && ${exec_statements}'
            '';
        in
        {
          check = pkgs.writeShellApplication {
            name = "check";
            text = forEachDir {
              exec = [
                ''echo "checking $dir"''
                "(set -x; nix flake check --quiet --all-systems --no-build)"
              ];
            };
          };

          update = pkgs.writeShellApplication {
            name = "update";
            text = forEachDir {
              exec = [
                ''echo "updating $dir"''
                "(set -x; nix flake update)"
              ];
              jobs = 1;
            };
          };
        }
      );
    in
    {
      packages = forEachSupportedSystem (
        { pkgs, ... }:
        let
          inherit (pkgs) callPackage;
        in
        {
          create-template = callPackage ./pkgs/create-template { };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt-tree);

      checks = forEachSupportedSystem (
        { pkgs, system, ... }:
        {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt-rfc-style.enable = true;
            };
          };
        }
      );

      devShells = forEachSupportedSystem (
        { pkgs, system, ... }:
        let
          inherit (pkgs) system mkShellNoCC;
          inherit (pkgs.lib) getExe attrValues;
          inherit (self.checks."${system}") pre-commit-check;
          inherit (scriptDrvs."${system}") check update;

          packages = self.packages."${system}";

          onefetch = getExe pkgs.onefetch;
        in
        {
          default = mkShellNoCC {
            packages =
              [
                check
                update
              ]
              ++ attrValues packages
              ++ pre-commit-check.enabledPackages;

            shellHook = ''
              ${pre-commit-check.shellHook}
              ${onefetch} --no-bots 2>/dev/null
            '';
          };

          ci = mkShellNoCC {
            packages = [
              check
              update
            ];
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

        latex = {
          path = ./latex;
          description = "LaTeX development environment";
          welcomeText = ''
            # LaTeX Development environment

            ## More info
              - [LaTeX](https://www.latex-project.org/)
              - [TexLive](https://wiki.nixos.org/wiki/TexLive)
          '';
        };

        matlab = {
          path = ./matlab;
          description = "MATLAB development environment";
          welcomeText = ''
            # MATLAB Development environment

            ## More info
              - [MATLAB](https://www.mathworks.com/products/matlab.html)
              - [MATLAB on the NixOS Wiki](https://nixos.wiki/wiki/Matlab)
              - [nix-matlab](https://gitlab.com/doronbehar/nix-matlab)
              - Note: Use a valid license for MATLAB.
          '';
        };

        matlab-octave = {
          path = ./matlab-octave;
          description = "MATLAB/Octave development environment";
          welcomeText = ''
            # MATLAB/Octave Development environment

            ## More info
              - This environment supports both MATLAB and Octave.
              - [MATLAB](https://www.mathworks.com/products/matlab.html)
              - [MATLAB on the NixOS Wiki](https://nixos.wiki/wiki/Matlab)
              - [nix-matlab](https://gitlab.com/doronbehar/nix-matlab)
              - [Octave](https://octave.org)
              - Note: Use a valid license for MATLAB.
          '';
        };

        octave = {
          path = ./octave;
          description = "Octave development environment";
          welcomeText = ''
            # Octave Development environment

            ## More info
              - [Octave language](https://octave.org)
          '';
        };

        octave-matlab = matlab-octave;

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

        rust-crane = {
          path = ./rust-crane;
          description = "Rust development enviroment with crane for caching dependencies";
          welcomeText = ''
            # Rust Development environment

            ## More info
                  - [Rust language](https://www.rust-lang.org/)
                  - [Rust on the NixOS Wiki](https://nixos.wiki/wiki/Rust)

            You can:
              1. `rm -r src/ Cargo.toml Cargo.lock`
              2. `cargo init`
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

        typst = {
          path = ./typst;
          description = "Typst development enviroment";
          welcomeText = ''
            # Typst Development environment

            ## More info
              - [Typst Github](https://github.com/typst/typst)
              - [Typst](https://typst.app/)
              - [Typst Examples Book](https://sitandr.github.io/typst-examples-book/book/)
          '';
        };

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
