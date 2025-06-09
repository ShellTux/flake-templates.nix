{
  description = "A Nix-flake-based Rust development environment";

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
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
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

            pkgs = import nixpkgs {
              inherit system;
              overlays = [
                rust-overlay.overlays.default
                self.overlays.default
              ];
            };
          }
        );
    in
    {
      overlays.default = final: prev: {
        rustToolchain =
          let
            rust = prev.rust-bin;
          in
          if builtins.pathExists ./rust-toolchain.toml then
            rust.fromRustupToolchainFile ./rust-toolchain.toml
          else if builtins.pathExists ./rust-toolchain then
            rust.fromRustupToolchainFile ./rust-toolchain
          else
            rust.stable.latest.default.override {
              extensions = [
                "rust-src"
                "rustfmt"
              ];
            };
      };

      checks = forEachSupportedSystem (
        { pkgs, system, ... }:
        {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              cargo-check.enable = true;
              clippy.enable = true;
              nixfmt-rfc-style.enable = true;
              rustfmt.enable = true;
            };
          };
        }
      );

      devShells = forEachSupportedSystem (
        { pkgs, system, ... }:
        let
          inherit (pkgs) mkShell;
          inherit (pkgs.lib) getExe;
          inherit (pkgs) rustToolchain;
          inherit (pkgs.rust.packages.stable.rustPlatform) rustLibSrc;
          inherit (self.checks."${system}") pre-commit-check;

          onefetch = getExe pkgs.onefetch;
        in
        {
          default = mkShell {
            packages = [
              rustToolchain

              pkgs.openssl
              pkgs.pkg-config
              pkgs.cargo-deny
              pkgs.cargo-edit
              pkgs.cargo-watch
              pkgs.rust-analyzer
            ] ++ pre-commit-check.enabledPackages;

            env = {
              # Required by rust-analyzer
              RUST_SRC_PATH = "${rustLibSrc}";
            };

            shellHook = ''
              ${pre-commit-check.shellHook}
              ${onefetch} --no-bots 2>/dev/null
            '';
          };
        }
      );
    };
}
