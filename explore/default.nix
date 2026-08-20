# explore/default.nix — composition of all experimental modules
#
# Import this in a snowflake to enable all explore modules at once.
# Comment out individual lines to exclude specific experiments.
{ ... }:

{
  imports = [
    ./fileviewer-test.nix
    ./claude.nix
  ];
}
