with import <nixpkgs> {};

mkShell {
  buildInputs = with pkgs; [ hugo ];
}
