{ pkgs, lib, config, inputs, ... }:

{
  packages = [ pkgs.gnumake inputs.c3c.outputs.packages.${pkgs.system}.c3c ];

  # See full reference at https://devenv.sh/reference/options/
}
