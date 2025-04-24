{
  bat,
  coreutils,
  writeShellApplication,
}:
let
  inherit (builtins) readFile;
in
writeShellApplication {
  name = "create-template";

  runtimeInputs = [
    bat
    coreutils
  ];

  text = readFile ./create-template.sh;
}
