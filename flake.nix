{
  description = "";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Flake management
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Mail server
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.05";
      inputs = {
        nixpkgs-25_05.follows = "nixpkgs";
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    # Pre commit hooks for git
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Efael messenger
    web-client.url = "github:efael/fluffy/efael/app/v2.2.0";
  };

  outputs = {
    self,
    flake-parts,
    pre-commit-hooks,
    ...
  } @ inputs:
  # https://flake.parts/module-arguments.html
    flake-parts.lib.mkFlake {inherit inputs;} (top @ {
      config,
      withSystem,
      moduleWithSystem,
      ...
    }: {
      imports = [
        # Optional: use external flake logic, e.g.
        # inputs.foo.flakeModules.default
        inputs.flake-parts.flakeModules.easyOverlay
      ];
      flake = {
        # Put your original flake attributes here.
        overlays.default = import ./overlay.nix;
      };
      systems = [
        # systems for which you want to build the `perSystem` attributes
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem = {
        config,
        pkgs,
        ...
      }: {
        # Recommended: move all package definitions here.
        # e.g. (assuming you have a nixpkgs input)
        overlayAttrs = {
          inherit (config.checks) pre-commit-check;
        };

        formatter = pkgs.alejandra;

        checks = {
          pre-commit-check = pre-commit-hooks.lib.${pkgs.system}.run {
            src = ./.;
            hooks = {
              statix.enable = true;
              alejandra.enable = true;
              flake-checker.enable = true;
            };
          };
        };

        packages = {
          inherit (inputs.web-client.packages.${pkgs.system}) web;
        };

        devShells = {
          default = import ./shell.nix {
            inherit (self.checks.${pkgs.system}) pre-commit-check;
            pkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
          };
        };
      };
    });
}
