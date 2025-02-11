{ pkgs, lib, config, inputs, ... }:

{
  packages = [ pkgs.git ];

  languages = {
    solidity = {
      enable = true;
      foundry.enable = true;
    };
  };
}
