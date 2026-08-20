# Snowflake: full
# Everything — editor, rust toolchain, all CLI tools, explore modules.
{ config, lib, pkgs, fenix, ... }:

{
  imports = [
    ../home/default.nix
    ../explore
  ];
}
