{
  description = "A Nix-flake-based C/C++/Rust development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      rust-overlay,
      pre-commit-hooks,
      crane,
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        pre-commit-hooks.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        let
          inherit (builtins)
            attrValues
            elem
            pathExists
            ;
          inherit (pkgs.lib) getExe filterAttrs fileset;

          additionalPackages = attrValues (filterAttrs (key: value: (elem key [ ])) config.packages);

          rustToolchain =
            if pathExists ./rust-toolchain.toml then
              pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml
            else if pathExists ./rust-toolchain then
              pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain
            else
              pkgs.rust-bin.stable.latest.default.override {
                extensions = [
                  "rust-src"
                  "rustfmt"
                ];
              };
          craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

          inherit (craneLib)
            buildPackage
            cargoDoc
            cargoFmt
            cargoNextest
            ;

          src = fileset.toSource {
            root = ./.;
            fileset = fileset.unions [
              (craneLib.fileset.commonCargoSources ./.)
              # (fileset.fileFilter (file: any (ext: file.hasExt ext) ["md"]) ./.)
              # (fileset.maybeMissing ./images)
            ];
          };

          commonArgs = {
            inherit src;
            strictDeps = true;

            nativeBuildInputs = [
              pkgs.openssl
              pkgs.openssl.dev
              pkgs.pkg-config
            ];

            PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
            OPENSSL_NO_VENDOR = 1;
          };

          cargoArtifacts = craneLib.buildDepsOnly commonArgs;

          individualCrateArgs = commonArgs // {
            inherit cargoArtifacts;
            inherit (craneLib.crateNameFromCargoToml { inherit src; }) version;
            # NB: we disable tests since we'll run them all via cargo-nextest
            doCheck = false;
          };

          workspace = buildPackage (commonArgs // { inherit cargoArtifacts; });

          rust-bin = buildPackage (
            individualCrateArgs
            // {
              pname = "rust-bin";
              cargoExtraArgs = "--bin=bin";
            }
          );

          onefetch = getExe pkgs.onefetch;
        in
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;

            overlays = [ rust-overlay.overlays.default ];
          };

          pre-commit.settings.hooks = {
            cargo-check.enable = true;
            check-toml.enable = true;
            clang-format.enable = true;
            clippy.enable = true;
            nixfmt.enable = true;
            rustfmt.enable = true;
          };

          checks = {
            inherit workspace;

            my-workspace-doc = cargoDoc (
              commonArgs
              // {
                inherit cargoArtifacts;
              }
            );

            my-workspace-fmt = cargoFmt {
              inherit src;
            };

            my-workspace-nextest = cargoNextest (
              commonArgs
              // {
                inherit cargoArtifacts;
                partitions = 1;
                partitionType = "count";
                cargoNextestPartitionsExtraArgs = "--no-tests=pass";
              }
            );
          };

          devShells =
            let
              inherit (pkgs.rust.packages.stable.rustPlatform) rustLibSrc;
              inherit (config) pre-commit;
            in
            {
              default =
                craneLib.devShell.override
                  {
                    # Override stdenv in order to change compiler:
                    # stdenv = pkgs.clangStdenv;
                  }
                  {
                    packages =
                      [
                        # C/C++
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
                      ++ [
                        # Rust
                        pkgs.openssl
                        pkgs.pkg-config
                        pkgs.cargo-deny
                        pkgs.cargo-edit
                        pkgs.cargo-nextest
                        pkgs.cargo-watch
                        pkgs.rust-analyzer
                      ]
                      ++ [
                        pkgs.entr
                        pkgs.fd
                        pkgs.jq
                        pkgs.ripgrep
                        pkgs.ripgrep-all
                        pkgs.tokei
                      ]
                      ++ additionalPackages;

                    env = {
                      # Required by rust-analyzer
                      RUST_SRC_PATH = "${rustLibSrc}";
                    };

                    shellHook = ''
                      ${pre-commit.installationScript}
                      ${onefetch} --no-bots
                    '';
                  };

              ci = craneLib.devShell {
                packages = [
                  pkgs.openssl
                  pkgs.pkg-config
                  pkgs.cargo-nextest
                ];

                env = {
                  # Required by rust-analyzer
                  RUST_SRC_PATH = "${rustLibSrc}";
                  CARGO_TERM_COLOR = "always";
                };
              };
            };

          packages = {
            inherit
              workspace
              rust-bin
              ;

            default = workspace;
          };
        };
    };
}
