{
  description = "A Nix-flake-based LaTeX development environment";

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
          inherit (pkgs) mkShell;
          inherit (pkgs.lib) getExe;

          tex = pkgs.texlive.combine {
            inherit (pkgs.texlive)
              scheme-basic
              booktabs
              fancyvrb
              footnotehyper
              xcolor
              ;
          };

          onefetch = getExe pkgs.onefetch;
        in
        {
          default = mkShell {
            packages =
              [
                pkgs.tectonic
                pkgs.texlab
                tex
              ]
              ++ [
                pkgs.entr
                pkgs.fd
                pkgs.jq
                pkgs.ripgrep
                pkgs.ripgrep-all
                pkgs.tokei
              ];

            shellHook = ''
              ${onefetch} --no-bots 2>/dev/null
            '';
          };
        }
      );
    };
}
