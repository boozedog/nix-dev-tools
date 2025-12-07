{
  description = "Shared Nix development tools - formatters, linters, LSP, pre-commit hooks";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      pre-commit-hooks,
      ...
    }:
    let
      # Supported systems
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      # Helper to generate outputs for each system
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Get pkgs for a system
      pkgsFor = system: nixpkgs.legacyPackages.${system};

      # Pre-commit hooks for a system (requires src path from consumer)
      mkPreCommitHooks =
        system: src:
        pre-commit-hooks.lib.${system}.run {
          inherit src;
          hooks = {
            statix.enable = true;
            deadnix.enable = true;
            nixfmt-rfc-style.enable = true;
            nil.enable = true;
          };
        };
    in
    {
      # Export the lib functions for consumers to use
      lib = {
        # Create a devShell with all the dev tools
        mkDevShell =
          {
            system,
            src ? ./.,
            extraPackages ? [ ],
            shellHook ? "",
          }:
          let
            pkgs = pkgsFor system;
            pre-commit-check = mkPreCommitHooks system src;
          in
          pkgs.mkShell {
            packages = [
              pkgs.nixfmt-rfc-style
              pkgs.statix
              pkgs.nixd
              pkgs.deadnix
              pkgs.nil
            ]
            ++ extraPackages;

            shellHook = ''
              ${pre-commit-check.shellHook}
              ${shellHook}
            '';
          };

        # Get pre-commit check (useful for CI)
        inherit mkPreCommitHooks;
      };

      # Default devShell for this repo itself
      devShells = forAllSystems (system: {
        default = self.lib.mkDevShell {
          inherit system;
          src = ./.;
        };
      });

      # Formatter for this repo
      formatter = forAllSystems (system: (pkgsFor system).nixfmt-rfc-style);

      # Checks for this repo
      checks = forAllSystems (system: {
        pre-commit = self.lib.mkPreCommitHooks system ./.;
      });
    };
}
