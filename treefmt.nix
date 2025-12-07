{
  projectRootFile = "flake.nix";
  settings.global.fail-on-change = true;
  programs = {
    deadnix.enable = true;
    nixfmt.enable = true;
    statix.enable = true;
  };
}
