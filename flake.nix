{
  description = "Shared Nix development tools - formatters, linters, LSP, pre-commit hooks";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
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

      # Treefmt configuration for a system
      treefmtFor = system: treefmt-nix.lib.evalModule (pkgsFor system) ./treefmt.nix;

      # Pre-commit hooks for a system (requires src path from consumer)
      mkPreCommitHooks =
        system: src:
        pre-commit-hooks.lib.${system}.run {
          inherit src;
          hooks = {
            treefmt = {
              enable = true;
              package = (treefmtFor system).config.build.wrapper;
              settings.fail-on-change = true;
            };
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
            treefmtEval = treefmtFor system;
            pre-commit-check = mkPreCommitHooks system src;
          in
          pkgs.mkShell {
            packages = [
              treefmtEval.config.build.wrapper
              pkgs.statix
              pkgs.nixd
              pkgs.deadnix
            ]
            ++ extraPackages;

            shellHook = ''
              ${pre-commit-check.shellHook}
              ${shellHook}
            '';
          };

        # Get just the treefmt wrapper (useful for formatter output)
        mkFormatter = system: (treefmtFor system).config.build.wrapper;

        # Get the formatting check (useful for CI)
        mkFormattingCheck = system: src: (treefmtFor system).config.build.check src;

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
      formatter = forAllSystems (system: self.lib.mkFormatter system);

      # Checks for this repo
      checks = forAllSystems (system: {
        formatting = self.lib.mkFormattingCheck system self;
        pre-commit = self.lib.mkPreCommitHooks system ./.;
      });
    };
}
