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
        overlays = {
          # When applied, the unstable nixpkgs set (declared in the flake inputs) will
          # be accessible through 'pkgs.unstable'
          default = final: prev: rec {
            unstable = import inputs.nixpkgs-unstable {
              inherit (final) system;
              config.allowUnfree = true;
            };

            statix =
              final.unstable.statix.overrideAttrs
              (_o: rec {
                src = final.fetchFromGitHub {
                  owner = "oppiliappan";
                  repo = "statix";
                  rev = "43681f0da4bf1cc6ecd487ef0a5c6ad72e3397c7";
                  hash = "sha256-LXvbkO/H+xscQsyHIo/QbNPw2EKqheuNjphdLfIZUv4=";
                };

                cargoDeps = final.rustPlatform.importCargoLock {
                  lockFile = src + "/Cargo.lock";
                  allowBuiltinFetchGit = true;
                };
              });
          };
        };
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
        # packages.foo = pkgs.callPackage ./foo/package.nix { };
        # packages.bar = pkgs.callPackage ./bar/package.nix {
        #   foo = config.packages.foo;
        # };
        overlayAttrs = {
          inherit (config.checks) pre-commit-check;
        };

        formatter = pkgs.alejandra;

        checks = {
          pre-commit-check = pre-commit-hooks.lib.${pkgs.system}.run {
            src = ./.;
            hooks = {
              statix = {
                enable = true;
                package = pkgs.statix;
              };
              alejandra.enable = true;
              flake-checker.enable = true;
            };
          };
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
