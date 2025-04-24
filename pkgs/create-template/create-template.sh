#!/bin/sh
set -e

usage() {
  echo "Usage: $0 <template-name>"
  echo
  echo "Options:"
  echo "  -h, --help            Show this help page"
  exit 1
}

for arg
do
  case "$arg" in
    -h | --help) usage ;;
  esac
done

[ "$#" -ne 1 ] && usage

TEMPLATE="$1"

mkdir --parents "$TEMPLATE"

cat <<EOF | (set -x; tee "$TEMPLATE/.envrc") | bat --style=numbers --pager=never --language=sh
use flake
EOF

FLAKE="$TEMPLATE/flake.nix"
cat <<EOF | (set -x; tee "$FLAKE") | bat --style=numbers --pager=never --language=nix
{
  description = "A Nix-flake-based $TEMPLATE development environment";

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
            packages = [];

            shellHook = ''
              \${onefetch} --no-bots 2>/dev/null
            '';
          };
        }
      );
    };
}
EOF

GITIGNORE="$TEMPLATE/.gitignore"
cat <<EOF | (set -x; tee "$GITIGNORE") | bat --style=numbers --pager=never --language=gitignore
.direnv
EOF

echo "Template $TEMPLATE created"
echo "You may want to do the following:"
echo "  - Add packages to default devShell to $FLAKE"
echo "  - Add language specific rules to $GITIGNORE"
echo "  - Generate flake.lock file to $TEMPLATE to pin inputs versions"
echo "  - Update README.md with new template"
