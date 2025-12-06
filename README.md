# nix-dev-tools

Shared Nix development environment with formatters, linters, LSP servers, and pre-commit hooks.

## What's Included

- **treefmt** with nixfmt - automatic Nix formatting
- **statix** - Nix linter and static analysis
- **nixd** - Nix LSP server with flake-aware option completions
- **pre-commit hooks** - treefmt and statix run automatically on commit

## Integration

### 1. Add the input to your flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    dev-tools = {
      url = "github:boozedog/nix-dev-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dev-tools, ... }:
    # ...
}
```

### 2. Add the devShell

```nix
outputs = { self, nixpkgs, dev-tools, ... }:
{
  # Your other outputs...

  devShells.aarch64-darwin.default = dev-tools.lib.mkDevShell {
    system = "aarch64-darwin";
    src = ./.;
  };

  # Add other systems as needed
  devShells.x86_64-linux.default = dev-tools.lib.mkDevShell {
    system = "x86_64-linux";
    src = ./.;
  };
};
```

### 3. (Optional) Add the formatter

This enables `nix fmt` to format your project:

```nix
formatter.aarch64-darwin = dev-tools.lib.mkFormatter "aarch64-darwin";
formatter.x86_64-linux = dev-tools.lib.mkFormatter "x86_64-linux";
```

### 4. Update your flake lock

```bash
nix flake update dev-tools
```

### 5. Enter the dev shell

```bash
nix develop
```

On first run, pre-commit hooks will be installed automatically.

## Full Example

Here's a complete minimal flake using nix-dev-tools:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    dev-tools = {
      url = "github:boozedog/nix-dev-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dev-tools, ... }:
    let
      system = "aarch64-darwin";  # or your system
    in
    {
      # Your NixOS/darwin/home-manager configurations here...

      devShells.${system}.default = dev-tools.lib.mkDevShell {
        inherit system;
        src = ./.;
      };

      formatter.${system} = dev-tools.lib.mkFormatter system;
    };
}
```

## Adding Project-Specific Packages

You can extend the dev shell with additional packages:

```nix
devShells.${system}.default = dev-tools.lib.mkDevShell {
  inherit system;
  src = ./.;
  extraPackages = with nixpkgs.legacyPackages.${system}; [
    nodejs
    yarn
    jq
  ];
  shellHook = ''
    echo "Welcome to my project!"
  '';
};
```

## Available Functions

| Function | Description |
|----------|-------------|
| `lib.mkDevShell { system, src, extraPackages?, shellHook? }` | Creates a dev shell with all tools |
| `lib.mkFormatter system` | Returns the treefmt wrapper for `nix fmt` |
| `lib.mkFormattingCheck system src` | Returns a check for CI |
| `lib.mkPreCommitHooks system src` | Returns pre-commit hook configuration |

## Supported Systems

- `aarch64-darwin` (Apple Silicon Mac)
- `x86_64-darwin` (Intel Mac)
- `aarch64-linux` (ARM Linux)
- `x86_64-linux` (x86 Linux)
